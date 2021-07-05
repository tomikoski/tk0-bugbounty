Nexus 5x (with ram disk)
========================

## Prepare boot.img
1. download stock firmware: https://dl.google.com/dl/android/aosp/bullhead-opm7.181205.001-factory-5f189d84.zip (latest for Nexus 5x)
1. stock firmware: `./flash-all.sh` (wipes all data!)
1. install magisk: https://topjohnwu.github.io/Magisk/install.html
1. extract boot.img from factory image and push to device:

```
$ cd firmware/bullhead-opm7.181205.001
$ unzip image-bullhead-opm7.181205.001.zip -d image-bullhead-opm7.181205.001
$ adb push image-bullhead-opm7.181205.001/boot.img /sdcard/Download
```

## Install Magisk boot.img
1. Open magisk and patch `boot.img` using `Select and Patch a File` option
1. download patched, e.g. `$ adb pull /sdcard/Download/magisk_patched-23000_ESlfM.img`
1. `$ adb reboot bootloader`
1. `$ fastboot flash boot magisk_patched-23000_ESlfM.img`
1. `$ fastboot reboot`
1. open magisk, should look like:

    ![screenshot](magisk.png)

1. done & simple test:
```
$ adb devices; adb shell "su -c id"
List of devices attached
00<DEVICEIDHERE>	device

uid=0(root) gid=0(root) groups=0(root) context=u:r:magisk:s0

```
