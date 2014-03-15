rt-n56u
=======

ASUS RT-N56U/N65U/N14U custom firmware

Upstream: http://code.google.com/p/rt-n56u/

========

Modifications:  
1. Added BFQ I/O scheduler  
2. Added simple_shaper.sh script for QOS into the firmware  
Upstream URL: http://xserv.compress.to/xnor/linux/rt-nxxu/  
  
Kudos to ```xnor``` for an excellent script. I merely added it to the builds  
with tiny modifications for easier integration. You can ping xnor in the  
oficial support thread: http://www.smallnetbuilder.com/forums/showthread.php?t=14300  
3. simple_shaper doesn't need WAN interface to be set, as it is detected automagically now.  
4. Added patch for newer systems with texinfo >= 5 to bootstrap cross-gcc
  
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
