#!/bin/sh

# Run the postkali-wrapper from autostart
cat <<EOF > /etc/xdg/autostart/postkali.desktop
[Desktop Entry]
Version=1.0
Name=Postkali
Comment=Configure Kali using Nettitude build script
Exec=/root/postkali-wrapper.sh
Icon=utilities-terminal
Terminal=false
Type=Application
X-GNOME-Autostart-enabled=true
EOF
# Create the portkali-wrapper
cat <<EOF > /root/postkali-wrapper.sh
#!/bin/bash
gnome-terminal -e "/root/postkali.sh --teamviewer" 2>&1 | tee /root/postKali-build.log
rm -f /etc/xdg/autostart/postkali.desktop
rm -f /etc/xdg/autostart/postkali-wrapper.sh
EOF
# Make it executable
chmod +x /root/postkali-wrapper.sh

# Grab the main postkali script
/usr/bin/wget -qO- http://bit.ly/postKali-netti2 > /root/postkali.sh
chmod +x /root/postkali.sh

exit 0