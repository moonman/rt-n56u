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
  
=========
  
To build:  
1. Follow the steps outlined here:  
http://code.google.com/p/rt-n56u/wiki/HowToMakeFirmware  
2. If building on Debian sid, also install ```automake1.11```  

========  
  
I use ArchLinux installation with debian sid chroot.  

Install "debootstrap" from aur and create a chroot.    
Place this script in <chrootdir>/bin and make it executable  

```
#!/bin/bash

PATH=$PATH:/bin:/sbin:/usr/sbin
export PATH

/bin/bash
```

to chroot use
```
arch-chroot <chrootdir> /bin/start
