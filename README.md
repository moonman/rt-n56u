rt-n56u-qos
=======

ASUS RT-N56U/N65U/N14U custom firmware with QOS

Upstream: http://code.google.com/p/rt-n56u/  
Prebuilt Images: https://www.mediafire.com/folder/z09g335s500o4/Padavan%27s_RTN56U_firmware_QOS_mod

========

Modifications:  

1. Added BFQ I/O scheduler  
2. Added OpenWRT QOS script for QOS into the firmware   
3. Added patch for newer systems with texinfo >= 5 to bootstrap cross-gcc 4.4.7  
4. Added gcc 4.7.3. All images are compiled with this now.  
Starting with *3.8-081-moonman-6 all builds are compiled with gcc 4.8.2 (with better optimizations for 74kc)  
Starting with *3.8-084-moonman-7 all builds are compiled with gcc 4.9.1
** Beware: any version of gcc past 4.4.7 causes problems in builds, particularly native ipv6 does not work, and
** PPTPD does not accept connections. I've reverted back to 4.4.7 until these problems are resolved.
5. All images are compiled with appropriate compiler optimizations instead of generic mips32r2:  
RT-N14U: -march=24kec -mtune=24kec  
RT-N56U/RT-N65U: -march=74kc -mtune=74kc  

=========  

How-To:

0. If NOT coming from stock f/w, reset internal storage after flashing:  
Advanced Settings -> Administration -> Settings ->  
Router Internal Storage (/etc/storage) -> Reset  
1. Disable HW Nat:  
Advanced Settings -> WAN -> Hardware offload NAT/Routing IPv4 -> Disable  
2. SSH (or WinSCP) into the router and modify /etc/storage/qos.conf for your connection  
3. Change QOS_ENABLED variable in qos.conf to YES (all caps) 

=========  
  
To build:  
1. Follow the steps outlined here:  
http://code.google.com/p/rt-n56u/wiki/HowToMakeFirmware  
2. Additionaly install ```sudo``` if it isn't installed. (it isn't, by default, in Debian)

========  
  
I use ArchLinux installation with debian sid chroot.  

Install "debootstrap" from aur and create a chroot.    
Place this script in \<chrootdir\>/bin and make it executable  
(I called this script "start")  

```
#!/bin/bash

PATH=$PATH:/bin:/sbin:/usr/sbin
export PATH

/bin/bash
```

to chroot use
```
arch-chroot <chrootdir> /bin/start
```
