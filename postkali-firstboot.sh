#!/bin/bash

# grab the postkali config script
/usr/bin/wget -qO- http://bit.ly/postKali-netti2 > /root/postkali
chmod +x /root/postkali

# create a desktop shortcut to run the script
cat <<EOF > /root/Desktop/postkali.desktop
[Desktop Entry]
Version=1.0
Name=Postkali
Comment=Configure Kali using Nettitude build script
Exec=gnome-terminal -e /root/postkali
Icon=utilities-terminal
Terminal=false
Type=Application

EOF
chmod +x /root/postkali