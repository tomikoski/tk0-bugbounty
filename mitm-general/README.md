# MITM in general
Setup man-in-the-middle network using external router. Attacks everything except proxy IP.

## [GL-iNET](https://www.gl-inet.com/products/gl-a1300/)
* Connect any existing LAN to WAN in GL-iNET
* Reset device / clean install
* Use in router mode (default)
* Login + set password
* Fix NTP (via System menu)
* Run following `ssh root@192.168.8.1 'ash -s' < uci-firewall`
* Fire up Burp with invisible proxying using `$DAPROXY` IP (defined in `uci-firewall`)
* Should look in [LUCI OpenWrt](http://192.168.8.1/cgi-bin/luci) something like:
![port forward rules](firewall.png)
