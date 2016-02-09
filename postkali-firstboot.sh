#!/bin/sh

# grab the postkali-icon to desktop and runit
cat <<EOF > /etc/xdg/autostart/postkali.desktop
[Desktop Entry]
Version=1.0
Name=Postkali
Comment=Configure Kali using Nettitude build script
Exec=gnome-terminal -e /root/postkali 2>&1 | tee /root/postKali-build.log; rm -f /etc/xdg/autostart/postkali.desktop
Icon=utilities-terminal
Terminal=false
Type=Application
X-GNOME-Autostart-enabled=true
EOF
# grab the postkali config script
/usr/bin/wget -qO- http://bit.ly/postKali-netti2 > /root/postkali
chmod +x /root/postkali

exit 0