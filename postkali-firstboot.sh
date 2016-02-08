#!/bin/sh

# grab the postkali-icon to desktop and runit
/usr/bin/wget -qO- http://bit.ly/postKali-icon > /etc/xdg/autostart/postKali-icon.desktop

# grab the postkali config script
/usr/bin/wget -qO- http://bit.ly/postKali-netti2 > /root/postkali
chmod +x /root/postkali

exit 0