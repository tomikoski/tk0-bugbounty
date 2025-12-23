# FUZZING!

* https://gitlab.com/akihe/radamsa
* https://github.com/denandz/fuzzotron
* https://github.com/Darkkey/erlamsa
* https://github.com/Darkkey/erlamsa-docker-image
* https://www.digitalocean.com/community/tutorials/how-to-install-and-use-radamsa-to-fuzz-test-programs-and-network-services-on-ubuntu-18-04
* https://github.com/sec-tools/litefuzz
* https://googleprojectzero.blogspot.com/2021/05/fuzzing-ios-code-on-macos-at-native.html
* https://github.com/AFLplusplus/AFLplusplus
* https://github.com/AFLplusplus/LibAFL
* https://github.com/google/honggfuzz


## Preparation / Emulation of FW
If you have ARM-based firmware and ARM-computer (like Macbook), you can emulate it with:

```
docker run -it --privileged -v $(pwd):/firmware ubuntu
mkdir /mnt/firmware
mount -o offset=119161856 /firmware/firmware.bin /mnt/firmware # offset = rootfs
chroot /mnt/firmware
```

## Building sample IoT-targets (binaries)

MIPS (usually in routers):
```
# https://toolchains.bootlin.com/
# download: arch mips32, uclibc, mips32
#
# wget https://toolchains.bootlin.com/downloads/releases/toolchains/mips32/tarballs/mips32--uclibc--stable-2025.08-1.tar.xz
#
# Using above, this example creates:
# -> ELF 32-bit MSB pie executable, MIPS, \
# MIPS32 version 1 (SYSV), dynamically linked, interpreter /lib/ld-uClibc.so.0, not stripped

# Set path to your new compiler
# export CC=./mips-buildroot-linux-uclibc-gnu/usr/bin/mips-linux-gcc

# Compile dynamically
# -Wl,-dynamic-linker sets the specific interpreter path
# $CC harness.c -o harness -Wl,-dynamic-linker,/lib/ld-uClibc.so.0

mkdir /tmp/mips-build-chain
/tmp/mips-build-chain/mips32--uclibc--stable-2025.08-1/bin/mips-linux-gcc target1.c \
 -o target1 -Wl,-dynamic-linker,/lib/ld-uClibc.so.0
```

Test:
```
file target1
# outputs: target1: ELF 32-bit MSB pie executable, MIPS, \
# MIPS32 version 1 (SYSV), dynamically linked, interpreter /lib/ld-uClibc.so.0, not stripped
```


## LibAFL / AFL++
Debian installation (worked for me):

```
sudo apt install llvm-16 llvm-16-tools clang-16
```

Follow: https://github.com/AFLplusplus/LibAFL

### Building in Linux (tested with 4.32a)

```
cd AFLplusplus
make PERFORMANCE=1

# build target with:
$AFL/afl-cc target.c -o target

# fuzz
$AFL/afl-fuzz -i in -o out -- ./target @@

# fuzz with params
$AFL/afl-fuzz -i in -o out -- ./target -a someparam -b someparam @@
```

## Black box fuzzing with AFL++ for MIPS / ARM etc.
Tested on Debian12. Compile AFL++ as normally would.

### Compile QEMU (for MIPS):
```
cd qemu_mode
CPU_TARGET=mips ./build_qemu_support.py

# fuzz
QEMU_LD_PREFIX=/usr/mips-linux-gnu $AFL/afl-fuzz -Q -i in -o out -- ./test_mips @@ 
```

### Compile QEMU (for arm64):
```
cd qemu_mode
CPU_TARGET=aarch64 ./build_qemu_support.sh

# fuzz:
QEMU_LD_PREFIX=/usr/aarch64-linux-gnu $AFLDIR/afl-fuzz -Q -i in -o out -- ./test_arm64 @@
```

### Parallel fuzzing (e.g using QEMU)
```
#term1, main
QEMU_LD_PREFIX=/usr/mips-linux-gnu $AFL/afl-fuzz -Q -i in -o out -M fuzz1 -- ./test_mips @@

#term2, secondary 1
QEMU_LD_PREFIX=/usr/mips-linux-gnu $AFL/afl-fuzz -Q -i in -o out -S fuzz2 -- ./test_mips @@

#term3, secondary 2
QEMU_LD_PREFIX=/usr/mips-linux-gnu $AFL/afl-fuzz -Q -i in -o out -S fuzz3 -- ./test_mips @@
...
...
```

## Fuzzing with macOS (M1/ARM)

### Binary fuzzing using non-instrumented mode

Compile AFLplusplus:
```
# only AFL++
cd AFLplusplus
make distrib

# AFL++ with fpicker
USEMMAP=1 make distrib
```

Fuzz using:
```
AFL_INST_LIBS=1 ~/Documents/git/AFLplusplus/afl-fuzz -D -n -i in -o out -- ./somemacosbinary @@
```

### Binary fuzzing using Frida
Compile examples:
```
cd AFLplusplus/frida_mode/test/osx-lib
make frida_persistent

# make will fail due to the ASLR blocking, since using:
# 	AFL_FRIDA_PERSISTENT_ADDR=0x0000000100003B88 \
#	AFL_FRIDA_PERSISTENT_CNT=1000000 \
#	AFL_ENTRYPOINT=0x0000000100003B88 \

# let's rerun using just AFL_INST_LIBS=1
AFL_INST_LIBS=1 ./afl-fuzz -D -O -i in -o frida-out -- ./harness @@
```

Adding following entry in GNUMakefile will also help to test:
```
.ONESHELL:
frida_adhoctest: $(HARNESS_BIN) $(LIB_BIN) $(TESTINSTR_DATA_FILE)
	cd $(BUILD_DIR) && \
	AFL_INST_LIBS=1 \
	$(ROOT)afl-fuzz \
		-D \
		-O \
		-i $(TESTINSTR_DATA_DIR) \
		-o $(FRIDA_OUT) \
		-- \
			$(HARNESS_BIN) $(TESTINSTR_DATA_FILE)

```

Then prepare and recompile with:
```
cd AFLplusplus/frida_mode/test/osx-lib
dd if=/dev/zero bs=1048576 count=1 of=test1.dat
make clean
make frida_adhoctest

# fuzzing starts with 'AFLplusplus/frida_mode/test/osx-lib/test1.dat'
```

### Binary fuzzing with fpicker
fpicker can be found here: https://github.com/ttdennis/fpicker.

#### NOTE: for some weird reason fpicker is segfaulting with M1
```
```


#### fpicker with Intel Mac (still works)
Compile AFLplusplus
```
cd AFLplusplus
USEMMAP=1 make distrib
```

Fuzz with fpicker
```
cd fpicker
frida-compile -v examples/test/test-fuzzer.js -o harness.js

# pwd: HOME/fpicker
# terminal 1
# start app

./examples/test/test 123

#terminal 2
$AFLDIR/afl-fuzz -D -i examples/test/in/ -o examples/test/out -- ./fpicker --fuzzer-mode afl -e attach -p test -f harness.js
```

## hongfuzz
* Linux: works as documented.
* macOS:
  1. Fix `fuzz.c` PRIu64 errors (change to %lu and %llu)
  1. build with `OS=POSIX make clean all` (see: https://github.com/google/honggfuzz/issues/477#issuecomment-1502180246)
  1. Fix `Makefile` to remove atomic and extra flags:

```
diff --git a/Makefile b/Makefile
index 81a6e84d..8deae005 100644
--- a/Makefile
+++ b/Makefile
@@ -27,7 +27,7 @@ BIN := honggfuzz
 HFUZZ_CC_BIN := hfuzz_cc/hfuzz-cc
 HFUZZ_CC_SRCS := hfuzz_cc/hfuzz-cc.c
 COMMON_CFLAGS := -std=c11 -I/usr/local/include -D_GNU_SOURCE -Wall -Wextra -Werror -Wno-format-truncation -Wno-override-init -I.
-COMMON_LDFLAGS := -pthread -L/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/lib -lm
+COMMON_LDFLAGS := -pthread -L/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/lib
 COMMON_SRCS := $(sort $(wildcard *.c))
 CFLAGS ?= -O3 -mtune=native -funroll-loops
 LDFLAGS ?=
@@ -164,9 +164,9 @@ else
         ARCH_CFLAGS += -m64 -D_POSIX_C_SOURCE=200809L -D__EXTENSIONS__=1
        ARCH_LDFLAGS += -m64 -lkstat -lsocket -lnsl -lkvm
     endif
-    ifneq ($(OS),Linux)
-        ARCH_LDFLAGS += -latomic
-    endif
+#    ifneq ($(OS),Linux)
+#        ARCH_LDFLAGS += -latomic
+#    endif
     ifneq ($(REALOS),OpenBSD)
     ifneq ($(REALOS),Darwin)
         ARCH_LDFLAGS += -lrt
```

### Usage Linux
Clone honggfuzz, build it. After this run example for 'file':

```
cd $HOME
mkdir fuzzing && cd fuzzing
apt source file
cd file-5.44
CC=~/git/honggfuzz/hfuzz_cc/hfuzz-clang ./configure --enable-static --disable-shared

#
# important!
# check output here for missing features like: lzma, bzip2, ... and fix these before make
#

make -j$(nproc)

# 
# important!
# if make still fails, run this 'autoreconf -v' and re-configure, re-make
# 

cd hongfuzz/examples/file

~/git/honggfuzz/hfuzz_cc/hfuzz-clang -I ~/fuzzing/linux-sources/file-5.44/src persistent-file.c -o persistent-file ~/fuzzing/linux-sources/file-5.44/src/.libs/libmagic.a -lz /usr/lib/x86_64-linux-gnu/libbz2.a -lz /usr/lib/x86_64-linux-gnu/liblzma.a -lz /usr/lib/x86_64-linux-gnu/libz.a /usr/lib/x86_64-linux-gnu/libzstd.a -lz /usr/lib/x86_64-linux-gnu/liblz.a -lz

~/git/honggfuzz/honggfuzz --input inputs/ --output outputs -R report -- ./persistent-file /home/tomi/fuzzing/linux-sources/file-5.44/magic/magic.local

```
