# iOS

## Jailbreaking: Palera1n iOS 15.7.2
*Using iPhone7 with iOS 15.7.2*
1. iPhone7 was upgraded from 14.8 -> 15.7.2 :)
1. Follow this Linux-guide: https://appledb.dev/jailbreak/palera1n.html

**NOTE 1:** During installation there was some problems with `usbmuxd` but I got it sorted out when I ran this command while in error state. Shown below: 
 ```
...
Creating listening port 6413 for device port 22
bind(): Address not available
Error creating socket for listen port 6413: Address not available
...
 ```
 At this point after cold sweats, I just popped another terminal and ran: `iproxy -s 127.0.0.1 6413:22` which continued installation successfully
 

**NOTE 2:** Full logs of this slow'ish but still working proceudure can be seen [here](https://raw.githubusercontent.com/tomikoski/tk0-bugbounty/master/iOS/palera1n-installation-logs.txt)

## Jailbreaking: checkra1n iOS 14.8
*Using iPhone7 with iOS 14.8*
1. download checkra1n (0.12.4)
1. **preffered** Use Ubuntu (with X and NOT Wayland) - OR - use **INTEL** based macOS or older macOS - latest (2022) doesn't work with Apple M1 at least :[
1. use following settings: ![testing](cr.png)

Problem solving:
* If this doesn't work (exploit does not trigger) - reset iPhone using `erase all content -> everything`. Repeat.
* If Cydia / apt fails - remove from system and rearm using checkra1n

## Decrypting HTTPS traffic
* https://andydavies.me/blog/2019/12/12/capturing-and-decrypting-https-traffic-from-ios-apps/
