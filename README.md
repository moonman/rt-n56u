rt-n56u
=======

ASUS RT-N56U/N65U/N14U custom firmware

Upstream: http://code.google.com/p/rt-n56u/

========

Modifications:  

1. Added BFQ I/O scheduler  
2. Added OpenWRT QOS script for QOS into the firmware   
3. Added patch for newer systems with texinfo >= 5 to bootstrap cross-gcc 4.4.7  
4. Added gcc 4.7.3. All images are compiled with this now.  
TODO: get 4.8.2 to work  
5. All images are compiled with appropriate compiler optimizations instead of generic mips32r2:  
RT-N14U: -march=24kec -mtune=24kec  
RT-N56U/RT-N65U: -march=74kc -mtune=74kc  

=========  

How-To:

0. If coming not from stock f/w, reset internal storage after flashing:  
Advanced Settings -> Administration -> Settings ->  
Router Internal Storage (/etc/storage) -> Reset  
1. Disable HW Nat:  
Advanced Settings -> WAN -> Hardware offload NAT/Routing IPv4 -> Disable  
2. SSH into the router and modify /etc/storage/qos.conf for your connection  
3. Advanced Settings -> Administration -> Tweaks -> Run after WAN up/down Events  
Uncomment the last line  
OR  
if on build >= *3.8-080-moonman-3 change QOS_ENABLED variable in qos.conf to YES

=========  
  
To build:  
1. Follow the steps outlined here:  
http://code.google.com/p/rt-n56u/wiki/HowToMakeFirmware  
2. If building on Debian sid (ubuntu? ), also install ```automake1.11```  
   and uninstall ```automake```. Please note: this may interfere with  
   other projects you might want to build so do it in chroot or VM to be safe.  

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
