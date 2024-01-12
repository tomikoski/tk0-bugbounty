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

# update path: llvm/clang
export PATH="/usr/lib/llvm-16/bin/":$PATH
```

Follow: https://github.com/AFLplusplus/LibAFL
