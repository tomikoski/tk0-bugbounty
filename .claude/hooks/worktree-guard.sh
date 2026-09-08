#!/bin/bash
# PreToolUse guard — worktree isolation for the shared MAIN checkout.
#
# Why: several agents (Claude sessions, and other AI tools) work this repo at
# once and share ONE main working tree. Two things collide there:
#   1. HEAD moves  — `git checkout` / `switch` / `reset --hard` / `rebase` /
#      `stash` rewrite the shared tree under a parallel session mid-task.
#   2. Concurrent writes — two agents editing the same tracked file with no
#      branch between them.
# Fix for both: one worktree = one branch = one agent. The main worktree stays
# on `main` permanently and is read-only for day-to-day work.
#
# Dispatch (one script, two PreToolUse matchers):
#   Bash            -> block HEAD-movers + `git commit` in the main worktree
#   Edit|Write|...  -> block writes to non-ignored paths in the main worktree
#
# Always allowed, by design:
#   - anything inside a LINKED worktree (.git/worktrees/*)
#   - `git merge` in the main worktree (git only advances `main` from the
#     worktree holding it — this is the documented retirement path)
#   - `git checkout -- <path>` / `git restore <path>` (no HEAD move)
#   - reads of every kind; writes outside the repo (~/.claude, /tmp, scratchpad)
#   - writes to gitignored paths inside the repo (build output, scratch)
#
# Known limit: writes performed THROUGH Bash (`sed -i`, `tee`, `>` redirects,
# heredocs) are not intercepted here — parsing shell redirection reliably is not
# worth the false positives. Those are covered by the rule text in CLAUDE.md /
# AGENTS.md, not by this block.
#
# Exit 2 = deny, stderr goes back to the agent.

set -uo pipefail

input=$(cat)

field() { # $1 = dotted path under the hook payload
  printf '%s' "$input" | /usr/bin/python3 -c '
import sys, json
try:
    doc = json.load(sys.stdin)
except Exception:
    sys.exit(0)
node = doc
for key in sys.argv[1].split("."):
    if not isinstance(node, dict):
        sys.exit(0)
    node = node.get(key)
print(node if isinstance(node, str) else "")
' "$1" 2>/dev/null
}

tool=$(field tool_name)

# --- shared: is the relevant checkout the MAIN worktree? ---------------------
# Linked worktrees keep their gitdir at .git/worktrees/<name> — those are the
# isolated ones this guard exists to push work into, so they are never blocked.
in_main_worktree() { # $1 = directory to resolve from
  local gitdir
  gitdir=$(git -C "$1" rev-parse --absolute-git-dir 2>/dev/null) || return 1
  case "$gitdir" in
    */worktrees/*) return 1 ;;   # linked worktree
  esac
  return 0
}

# A command can target a repo other than $PWD: `git -C <dir> ...`, or a leading
# `cd <dir> && git ...`. Collect every directory the command could act in and
# treat the command as main-worktree work if ANY of them is the main checkout.
# Erring toward blocking is the safe direction here.
cmd_targets_main_worktree() { # $1 = command string
  local c="$1" d
  in_main_worktree "$PWD" && return 0
  while read -r d; do
    [ -z "$d" ] && continue
    d="${d%\'}"; d="${d#\'}"; d="${d%\"}"; d="${d#\"}"
    [ -d "$d" ] || continue
    in_main_worktree "$d" && return 0
  done < <(printf '%s\n' "$c" \
             | grep -oE '(-C[[:space:]]+|(^|[;&|(`]|&&|\|\|)[[:space:]]*cd[[:space:]]+)[^[:space:];&|]+' \
             | sed -E 's/^(-C|.*[[:space:]]cd|cd)[[:space:]]+//')
  return 1
}

worktree_help() { # $1 = suggested branch slug
  local root
  root=$(git rev-parse --show-toplevel 2>/dev/null || echo '<repo-root>')
  cat >&2 <<EOF
  Spin an isolated worktree and redo the action there:
    git -C "$root" worktree add -b <type>/<slug> "$(dirname "$root")/$(basename "$root")-<slug>" main
    cd "$(dirname "$root")/$(basename "$root")-<slug>"
  Resume existing work:  git worktree list
  The main worktree stays on 'main' permanently; only 'git merge --no-ff' runs there.
EOF
}

# ---------------------------------------------------------------------------
# Bash: block HEAD-movers and commits in the main worktree
# ---------------------------------------------------------------------------
if [ "$tool" = "Bash" ]; then
  cmd=$(field tool_input.command)
  [ -z "$cmd" ] && exit 0

  # Only fire when `git` sits at COMMAND position — line start, or after
  # ; & | ( ` && || — so a `git checkout` inside a grep pattern or an echo
  # argument is not mistaken for the real thing. Optional flags and -C <dir>
  # may sit between `git` and the verb.
  git_verb='(^|[;&|(`]|&&|\|\|)[[:space:]]*git([[:space:]]+-{1,2}[^[:space:]]+|[[:space:]]+-C[[:space:]]+[^[:space:]]+)*[[:space:]]+'

  # 1. HEAD / working-tree movers.
  if echo "$cmd" | grep -Eq "${git_verb}(checkout|switch|rebase|stash)([[:space:]]|$)" \
     || echo "$cmd" | grep -Eq "${git_verb}reset[[:space:]]+(-{1,2}[^[:space:]]+[[:space:]]+)*--hard"; then
    # `git checkout [opts] -- <path>` restores a file without moving HEAD.
    if ! echo "$cmd" | grep -Eq '\bgit\b[^&|;]*\bcheckout\b[^&|;]*( --([[:space:]]|$)| -- )'; then
      if cmd_targets_main_worktree "$cmd"; then
        echo "BLOCKED: HEAD-moving git in the MAIN shared worktree — this rewrites the tree under every parallel agent." >&2
        worktree_help
        echo "  File restore is exempt: 'git checkout -- <path>' or 'git restore <path>'." >&2
        exit 2
      fi
    fi
  fi

  # 2. Commits. Merges are deliberately NOT blocked — main advances only here.
  if echo "$cmd" | grep -Eq "${git_verb}commit([[:space:]]|$)"; then
    if cmd_targets_main_worktree "$cmd"; then
      echo "BLOCKED: 'git commit' in the MAIN shared worktree. Commits belong on a per-agent worktree branch." >&2
      worktree_help
      echo "  Merging a finished branch INTO main is allowed here: git pull --ff-only && git merge --no-ff <branch>" >&2
      exit 2
    fi
  fi

  exit 0
fi

# ---------------------------------------------------------------------------
# Edit / Write / NotebookEdit: block writes to non-ignored repo paths
# ---------------------------------------------------------------------------
path=$(field tool_input.file_path)
[ -z "$path" ] && path=$(field tool_input.notebook_path)
[ -z "$path" ] && exit 0

# Resolve against the nearest existing ancestor so brand-new files still land in
# the right repo (a path that does not exist yet has no realpath of its own).
probe="$path"
while [ ! -e "$probe" ] && [ "$probe" != "/" ] && [ -n "$probe" ]; do
  probe=$(dirname "$probe")
done
[ -e "$probe" ] || exit 0

dir="$probe"
[ -d "$dir" ] || dir=$(dirname "$dir")

root=$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null) || exit 0   # not a repo -> allow
in_main_worktree "$dir" || exit 0                                       # linked worktree -> allow

# Gitignored paths inside the repo are scratch/build output — no collision risk.
git -C "$root" check-ignore -q -- "$path" 2>/dev/null && exit 0

echo "BLOCKED: write to a version-controlled file in the MAIN shared worktree." >&2
echo "  target: $path" >&2
echo "  Several agents share this checkout; concurrent edits to tracked files collide with no branch between them." >&2
worktree_help
echo "  Reads are unrestricted, and gitignored / out-of-repo paths (scratchpad, /tmp) stay writable here." >&2
exit 2
