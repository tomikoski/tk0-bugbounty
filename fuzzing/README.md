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

## LibAFL / AFL++
Debian installation (worked for me):

```
sudo apt install llvm-16 llvm-16-tools clang-16
```

Follow: https://github.com/AFLplusplus/LibAFL

### Building in Linux (tested with 4.31)

```
cd AFLplusplus
make distrib

# build target with:
$AFL/afl-cc target.c -o target

# fuzz
$AFL/afl-fuzz -i in -o out -- ./target @@

# fuzz with params
$AFL/afl-fuzz -i in -o out -- ./target -a someparam -b someparam @@
```

## Black box fuzzing with AFL++ for MIPS / ARM etc.

Tested on Debian12. Compile AFL++ as normally would.

### Compile unicorn (for MIPS):
```
cd unicorn-mode
CPU_TARGET=mips ./build_qemu_support.sh

# fuzz
QEMU_LD_PREFIX=/usr/mips-linux-gnu $AFL/afl-fuzz -Q -i in -o out -- ./test_mips @@ 
```

### Compile unicorn (for arm64):
```
cd unicorn-mode
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

### Usage Linux
Clone honggfuzz, build it and run example:

```
cd $HOME
git clone https://github.com/google/honggfuzz
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
