#!/bin/bash

# grab the postkali config script
/usr/bin/wget -qO- http://bit.ly/postKali-netti2 > /root/postkali
chmod +x /root/postkali
# grab the postkali-icon to desktop
/usr/bin/wget -qO- http://bit.ly/postKali-icon > /root/Desktop/postKali-icon.desktop
chmod +x /root/Desktop/postkali-icon.desktop