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
