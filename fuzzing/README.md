# FUZZING!

* https://gitlab.com/akihe/radamsa
* https://github.com/denandz/fuzzotron
* https://github.com/Darkkey/erlamsa
* https://github.com/Darkkey/erlamsa-docker-image
* https://www.digitalocean.com/community/tutorials/how-to-install-and-use-radamsa-to-fuzz-test-programs-and-network-services-on-ubuntu-18-04


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

### Binary fuzzing using Frida
```
cd AFLplusplus/frida_mode/test/osx-lib
make frida_persistent
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
			$(HARNESS_BIN) ../test1.dat
```

Then prepare and recompile with:
```
cd AFLplusplus/frida_mode/test/osx-lib
dd if=/dev/zero bs=1048576 count=1 of=test1.dat
make clean
make frida_adhoctest

# fuzzing starts with 'AFLplusplus/frida_mode/test/osx-lib/test1.dat'
```
