# FUZZING!

* https://gitlab.com/akihe/radamsa
* https://github.com/denandz/fuzzotron
* https://github.com/Darkkey/erlamsa
* https://github.com/Darkkey/erlamsa-docker-image
* https://www.digitalocean.com/community/tutorials/how-to-install-and-use-radamsa-to-fuzz-test-programs-and-network-services-on-ubuntu-18-04
* https://github.com/sec-tools/litefuzz
* https://googleprojectzero.blogspot.com/2021/05/fuzzing-ios-code-on-macos-at-native.html

## LibAFL / AFL++
Debian installation (worked for me):

```
sudo apt install llvm-16 llvm-16-tools clang-16
```

Follow: https://github.com/AFLplusplus/LibAFL


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
cd AFLplusplus
gmake
```

Fuzz using:
```
AFL_INST_LIBS=1 ~/Documents/git/AFLplusplus/afl-fuzz -D -n -i in -o out -- ./somemacosbinary @@
```

### Binary fuzzing using Frida
Compile AFLplusplus:
```
cd AFLplusplus
gmake
cd frida_mode
gmake
```

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
fpicker can be found here: https://github.com/ttdennis/fpicker

Compile AFLplusplus
```
export PATH="/opt/homebrew/Cellar/llvm/17.0.6/bin:/opt/homebrew/Cellar/coreutils/9.4/bin":$PATH

# basically uses: CFLAGS="-DUSEMMAP=1"
cd AFLplusplus
TEST_MMAP=1 gmake

cd frida_mode
TEST_MMAP=1 gmake
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
