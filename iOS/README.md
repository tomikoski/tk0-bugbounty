# iOS
Process for jailbreaking iOS devices

1. Install required tools such as `libimobiledevice` and `libusbmuxd` (e.g. homebrew, apt, ...)  
1. Execute ![JAILBREAK](JAILBREAK.md)
2. See next possible steps below

## Jaibroken phone, now what...?

### iPhone8 -> follow this:
* Install: https://github.com/NyaMisty/ssl-kill-switch3 -> Enable/Disable cert validation
* Enable full logging (ref: https://github.com/EthanArbuckle/unredact-private-os_logs) from iPhone:
  * copy/edit file into: `/Library/Preferences/Logging/com.apple.system.logging.plist`
    ```xml
    <?xml version="1.0" encoding="UTF-8" ?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">

    <plist version="1.0">
    <dict>
      <!-- show all data in logs, e.g. via idevicesyslog -->
      <key>Enable-Private-Data</key>
      <true/>
    </dict>

    </plist>    
    ``````

  * kill logd to restart using new settings:

    ```
    killall -9 logd
    ```

* Install [theos](https://github.com/theos/theos) for SW development
  ```
  # Working settings with iPhone8 development, add as first lines the following:
  ROOTLESS = 1
  ARCHS := arm64 arm64e
  THEOS_PACKAGE_SCHEME=rootless
  THEOS_PACKAGE_ARCH := iphoneos-arm64e
  ...
  ...
  ```

### iPhone7 -> follow this:
* Install `PreferenceLoader` from Palera1n repos (DO NOT add extra's for Cydia)
* Install https://github.com/nabla-c0d3/ssl-kill-switch2 using SSH
* Enable/Disable cert validation


## Decrypting HTTPS traffic
* https://andydavies.me/blog/2019/12/12/capturing-and-decrypting-https-traffic-from-ios-apps/

## Decrypting IPA-files
* Use https://github.com/AloneMonkey/frida-ios-dump for all
