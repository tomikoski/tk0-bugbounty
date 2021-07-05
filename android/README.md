Nexus 5x (with ram disk)
========================

1. download stock firmware: https://developers.google.com/android/images#bullhead
1. stock firmware (flash-all) -> wipes all data!
1. install magisk
1. extract boot.img from factory image and upload to device `Downloads`:
```
cd firmware/bullhead-opm7.181205.001
unzip image-bullhead-opm7.181205.001.zip -d image-bullhead-opm7.181205.001
adb push image-bullhead-opm7.181205.001/boot.img /sdcard/Download
```
1. patch with magisk
1. download patched, e.g.  adb pull /sdcard/Download/magisk_patched-23000_ESlfM.img
1. adb reboot bootloader 
1. fastboot flash boot magisk_patched-23000_ESlfM.img 
1. fastboot reboot
1. done

