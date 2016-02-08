#!/bin/sh

# grab the postkali-icon to desktop and runit
mkdir /etc/skel/Desktop
/usr/bin/wget -qO- http://bit.ly/postKali-icon > /etc/skel/Desktop/postKali-icon.desktop
chmod +x /etc/skel/Desktop/postKali-icon.desktop

# grab the postkali config script
/usr/bin/wget -qO- http://bit.ly/postKali-netti2 > /root/postkali
chmod +x /root/postkali

exit 0