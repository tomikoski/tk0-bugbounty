# AGENTS.md — tk0-bugbounty

Repository-level rules for non-Claude AI tools (Codex, Cursor, Copilot). Claude Code reads the
identical body from `CLAUDE.md`.

> Everything below the first `##` heading is byte-identical to `CLAUDE.md`; edit one, mirror the
> other in the same commit.

## Hard rule — worktree isolation

Several agents — Claude Code sessions plus other AI tools — can work this repository at the same
time and **share one main checkout**. Two things collide there:

1. **HEAD moves.** `git checkout` / `switch` / `rebase` / `reset --hard` / `stash` in the shared
   tree rewrite the working directory under a parallel agent, mid-task. This has already destroyed
   in-flight work once, in the repository this one was carved from.
2. **Concurrent writes.** Two agents editing the same version-controlled file with no branch
   between them — no merge, no conflict marker, last writer wins silently.

Branches are not the problem. **Moving HEAD in, or writing to, the shared tree is the problem.**

The rule holds even when you believe you are the only agent running: you cannot see another
session, another tool, or a terminal from inside this one. `ListAgents` names the peer sessions on
this machine — check it before touching a shared surface.

## What requires a worktree

| Action | Main checkout |
|---|---|
| Read anything — `cat`, `grep`, `git log`, `git status`, `git diff` | ✅ allowed |
| Write to a **version-controlled** file (edit, create, delete) | ⛔ worktree required |
| `git commit` | ⛔ worktree required |
| `git checkout` / `switch` / `rebase` / `reset --hard` / `stash` | ⛔ never, in any flow |
| Write to a **gitignored** path (build output, scratch) | ✅ allowed |
| Write outside the repo — `/tmp/kauppinen-<ts>/`, agent scratchpad, `~/.claude/` | ✅ allowed |
| `git checkout -- <path>` / `git restore <path>` (no HEAD move) | ✅ allowed |
| `git merge --no-ff <branch>` into `master` | ✅ **only** here — see below |

## Spin a worktree

```bash
REPO="$(git rev-parse --show-toplevel)"
SLUG="<short-task-slug>"
BRANCH="<type>/${SLUG}"                        # type ∈ feat|fix|docs|chore|fuzz|recon
WT="$(dirname "$REPO")/$(basename "$REPO")-${SLUG}"

git -C "$REPO" worktree add -b "$BRANCH" "$WT" master
git -C "$REPO" worktree lock --reason "<session> · <task> · $(date +%F)" "$WT"
cd "$WT"
```

**One worktree = one branch = one agent.** `.git/objects` is shared, so this is cheap. Resume
existing work by `cd`-ing to its worktree (`git worktree list`); never create a second worktree for
a branch that already has one.

**Lock it.** `git worktree lock` makes `git worktree remove` refuse, which is the only mechanism
that actually stops another session reclaiming a worktree with live work in it. The reason string
carries who holds it and since when.

## The main checkout stays on `master` — permanently

Git only advances the `master` ref from the worktree that holds it, so merges into it **do** run
in the main checkout — but with **no preceding `git checkout master`**. That redundant HEAD-move is
exactly what clobbers parallel agents.

```bash
[ "$(git symbolic-ref --short HEAD)" = "master" ] || { echo "main checkout is not on master — STOP"; exit 1; }
git pull --ff-only
git merge --no-ff <branch>
```

Two sessions finishing together race here. `index.lock` makes one fail rather than corrupt, so
re-verify `symbolic-ref` and re-`pull --ff-only` immediately before merging — and on an
`index.lock` failure **stop and report; never retry-loop**. Resolve conflicts in the main checkout,
never inside a task worktree.

## Retirement order (never skip a gate)

Wrong order = work goes into the void. Stop at any failure.

1. **Commit gate** — from the task worktree, `git status --porcelain` must be empty, and
   `git ls-files --others --exclude-standard` must show no findings/report/harness files.
2. **Push gate** — `git push -u origin <branch>`, so the branch survives worktree deletion.
3. **Merge gate** — from the main checkout, per the no-checkout recipe above.
4. **Ancestor gate** — `git merge-base --is-ancestor <branch-tip> master` must succeed.
5. **Unlock gate** — `git worktree unlock <path>`.
6. **Remove** — `git worktree remove <path>` then `git branch -d <branch>`. Never `-D`.

Never `git worktree remove` a worktree with a live process (running fuzzer, un-merged results)
without asking the user first. The lock from step 5 is what enforces this.

## Enforcement

`.claude/hooks/worktree-guard.sh`, wired as a `PreToolUse` hook in `.claude/settings.json`,
hard-blocks HEAD-movers, `git commit`, and writes to non-ignored files when the target is the main
checkout. Linked worktrees are exempt.

Two gaps the hook does **not** cover — the rule above still binds:

- **Writes through Bash** (`sed -i`, `tee`, `>` redirects, heredocs) are not intercepted; parsing
  shell redirection reliably is not worth the false positives.
- **Non-Claude AI tools** do not load Claude Code hooks, and git has no `pre-checkout` hook
  (`post-checkout` fires after the tree is already overwritten). For those tools this is
  convention, enforced by reading this file.

The hook is a backstop. Follow the rule regardless of which tool you are.

## Commit hygiene — no session identifiers

The Claude Code harness varies its commit-attribution footer by session. While Remote Control is
connected it appends a `Claude-Session: https://claude.ai/code/session_<id>` trailer, pinning the
commit to a specific chat transcript.

`.githooks/commit-msg` strips those lines and lets the commit proceed — it never rejects a commit,
because the author should not have to know the trailer existed. It is a **git** hook, not a Claude
Code hook, so it binds every tool.

Enable once per clone. The setting lives in `.git/config`, which every worktree of this repo shares:

```bash
git config core.hooksPath .githooks
```

## This repo is part of the `ai-cc-*` set

Created by `AI/dot-claude/new-campaign-repo.sh` in the control repo (`tomikoski-labs`), which is
also where the rules, skills and gates live. The `ai-cc-` prefix marks provenance and **is** the
registry — `repo-registry.sh` derives the repo set from the glob, so nothing needs adding to a list.

Carved out of the control repo. Nothing here may reference the pre-split layout — no paths under
the old `claude-projects` tree, and no `tomikoski-labs/…` paths. `check-stale-refs.sh` in the
control repo enforces that across every registered repo, and this repo's `.githooks/pre-commit`
reports it advisorily. A reference that must survive goes in `stale-refs-allow.txt` **with a
reason**.

(That sentence deliberately does not spell the old path out. The gate matches the literal string,
so writing it here would make every stamped repo flag its own rule file on every commit — which is
exactly what happened the first time these five were stamped.)
