#!/bin/bash

# grab the postkali config script
/usr/bin/wget -qO- http://bit.ly/postKali-netti2 > /root/postkali
chmod +x /root/postkali

# create a desktop shortcut to run the script
file=/root/Desktop/postkali.desktop; [ -e "${file}" ] && cp -n $file{,.bkup}
cat <<EOF > "${file}" || echo -e ' '${RED}'[!] Issue with writing file'${RESET} 1>&2
[Desktop Entry]
Version=1.0
Name=Postkali
Comment=Configure Kali using Nettitude build script
Exec=gnome-terminal -e /root/postkali
Icon=utilities-terminal
Terminal=false
Type=Application
X-GNOME-Autostart-enabled=true
EOF
chmod +x /root/Desktop/postkali.desktop