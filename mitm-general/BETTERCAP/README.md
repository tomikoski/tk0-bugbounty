# Bettercap
[BetterCap](https://www.bettercap.org/)


## macOS Sequoia

```
sudo bettercap -i en0
```

## Debian 12
Usage example parallel with NetworkManager

```
$ cat /etc/network/intefaces
...
...
#DHCP, WIFI (external)
allow-hotplug wlan0
iface wlan0 inet dhcp
wpa-ssid "TESTNETWORK"
wpa-psk "kensentme"
...
...

# check for mode
$ sudo iw dev wlan0 info
...
	ssid TESTNETWORK
	type managed
...

# if managed, set to monitor
$ sudo iw dev wlan0 set type monitor


# check for mode
$ sudo iw dev wlan0 info
...
	ssid TESTNETWORK
	type monitor
...

# start bettercap
$ sudo bettercap -iface wlan0
```
