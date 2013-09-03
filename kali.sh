#!/bin/sh
#-Operating System--------------------------------------#
# Designed for: Kali Linux [1.0.4 x86]                  #
#   Working on: 2013-08-19                              #
#-Author------------------------------------------------#
# g0tmilk ~ http://g0tmi1k.com                          #
#-Note--------------------------------------------------#
# The script WASN'T designed to be executed!            #
# Instead copy & paste commands into a terminal window. #
#-------------------------------------------------------#

##### Remote configuration via SSH (optional)
services ssh start         # Start SSH to allow for remote config
ifconfig eth0              # Get IP of the interface
#--- Use a 'remote' computer from here on out!
ssh root@<ip>              # Replace <ip> with the value from ifconfig
export DISPLAY=:0.0        # Allows for remote configuration


##### Configure location (E.g. timezone & keyboard layout)
#--- Keyboard
#dpkg-reconfigure keyboard-configuration  #dpkg-reconfigure console-setup   # Keyboard [DONT USE "English (UK) - English (UK, Macintosh)" FOR UK MPB, USE "US" (Still not perfect)] #<--- Doesn't automate
sed -i 's/XKBLAYOUT=".*"/XKBLAYOUT="us"/' /etc/default/keyboard && dpkg-reconfigure keyboard-configuration -u   # Keyboard #<--- Doesn't automate (need to restart xserver)
#--- Correct the server time
#dpkg-reconfigure tzdata   # Timezone <--- Doesn't automate
rm -f /etc/localtime
ln -sf /usr/share/zoneinfo/Europe/London /etc/localtime   # London, Europe
#date
#--- Install ntp (sync time)
apt-get -y install ntp
#--- Start service
service ntp restart
#--- Add to start up
#update-rc.d ntp defaults


##### Fix NetworkManger (optional)
#--- Fix 'device not managed' issue
#sed -i 's/managed=.*/managed=true/' /etc/NetworkManager/NetworkManager.conf
file=/etc/network/interfaces; if [ -e $file ]; then cp -n $file{,.bkup}; fi
sed -i '/iface lo inet loopback/q' /etc/network/interfaces    #sed '/^#\|'auto\ lo'\|'iface\ lo'/!d' /etc/network/interfaces
service network-manager restart
#--- Fix 'network disabled' issue
service network-manager stop
rm -f /var/lib/NetworkManager/NetworkManager.state
service network-manager start


##### Fix repositories
grep -q 'kali main non-free contrib' /etc/apt/sources.list || echo "deb http://http.kali.org/kali kali main non-free contrib" >> /etc/apt/sources.list
grep -q 'kali/updates main contrib non-free' /etc/apt/sources.list || echo "deb http://security.kali.org/kali-security kali/updates main contrib non-free" >> /etc/apt/sources.list
apt-get update


##### Install 'Virtualmachines Tools' (optional)
#--- Install VMware tools ~ http://docs.kali.org/general-use/install-vmware-tools-kali-guest
grep -q 'cups enabled' /usr/sbin/update-rc.d || echo "cups enabled" >> /usr/sbin/update-rc.d
grep -q 'vmware-tools enabled' /usr/sbin/update-rc.d || echo "vmware-tools enabled" >> /usr/sbin/update-rc.d
apt-get -y install gcc make linux-headers-$(uname -r)
ln -sf /usr/src/linux-headers-$(uname -r)/include/generated/uapi/linux/version.h /usr/src/linux-headers-$(uname -r)/include/linux/
# VM -> Install VMware Tools.
mkdir -p /mnt/cdrom/
mount -o ro /dev/cdrom /mnt/cdrom
cp -f /mnt/cdrom/VMwareTools-*.tar.gz /tmp/
cd /tmp/
tar zxvf VMwareTools*
cd vmware-tools-distrib/
echo -e '\n' | perl vmware-install.pl
cd ~/
#--- Install Parallel tools
grep -q 'cups enabled' /usr/sbin/update-rc.d || echo "cups enabled" >> /usr/sbin/update-rc.d
grep -q 'vmware-tools enabled' /usr/sbin/update-rc.d || echo "vmware-tools enabled" >> /usr/sbin/update-rc.d
apt-get -y install gcc make linux-headers-$(uname -r)
ln -sf /usr/src/linux-headers-$(uname -r)/include/generated/uapi/linux/version.h /usr/src/linux-headers-$(uname -r)/include/linux/
#Virtual Machine -> Install Parallels Tools
cd /media/Parallel\ Tools/
./install   #<enter>,<enter>,<enter>... #<--- Doesn't automate
#--- Install VirtualBox Guest Additions
# Mount CD - Use autorun


##### Setup static IP address on eth1 - host only (optional)
ifconfig eth1 192.168.155.175/24
grep -q 'iface eth1 inet static' /etc/network/interfaces || echo -e '\nauto eth1\niface eth1 inet static\n    address 192.168.155.175\n    netmask 255.255.255.0\n    gateway 192.168.155.1' >> /etc/network/interfaces


##### Update OS
apt-get update && apt-get -y dist-upgrade --fix-missing
#--- Enable bleeding edge ~ http://www.kali.org/kali-monday/bleeding-edge-kali-repositories/
#grep -q 'kali-bleeding-edge' /etc/apt/sources.list || echo -e "\n\n## Bleeding edge\ndeb http://repo.kali.org/kali kali-bleeding-edge main" >> /etc/apt/sources.list
#apt-get update && apt-get -y upgrade


##### Configure GNOME 3
#--- Move bottom panel to top panel
gsettings set org.gnome.gnome-panel.layout toplevel-id-list "['top-panel']"
dconf write /org/gnome/gnome-panel/layout/objects/workspace-switcher/toplevel-id "'top-panel'"
dconf write /org/gnome/gnome-panel/layout/objects/window-list/toplevel-id "'top-panel'"
#--- Panel position
dconf write /org/gnome/gnome-panel/layout/toplevels/top-panel/orientation "'top'"    #"'right'"   # Issue with window-list
#--- Panel ordering
dconf write /org/gnome/gnome-panel/layout/objects/menu-bar/pack-type "'start'"
dconf write /org/gnome/gnome-panel/layout/objects/menu-bar/pack-index 0
dconf write /org/gnome/gnome-panel/layout/objects/window-list/pack-type "'start'"   # "'center'"
dconf write /org/gnome/gnome-panel/layout/objects/window-list/pack-index 5          #0
dconf write /org/gnome/gnome-panel/layout/objects/workspace-switcher/pack-type "'end'"
dconf write /org/gnome/gnome-panel/layout/objects/clock/pack-type "'end'"
dconf write /org/gnome/gnome-panel/layout/objects/user-menu/pack-type "'end'"
dconf write /org/gnome/gnome-panel/layout/objects/notification-area/pack-type "'end'"
dconf write /org/gnome/gnome-panel/layout/objects/workspace-switcher/pack-index 1
dconf write /org/gnome/gnome-panel/layout/objects/clock/pack-index 2
dconf write /org/gnome/gnome-panel/layout/objects/user-menu/pack-index 3
dconf write /org/gnome/gnome-panel/layout/objects/notification-area/pack-index 4
#--- Enable Auto hide
#dconf write /org/gnome/gnome-panel/layout/toplevels/top-panel/auto-hide true
#--- Add top 10 tools to toolbar
dconf load /org/gnome/gnome-panel/layout/objects/object-10-top/ << EOT
[instance-config]
menu-path='applications:/Kali/Top 10 Security Tools/'
tooltip='Top 10 Security Tools'

[/]
object-iid='PanelInternalFactory::MenuButton'
toplevel-id='top-panel'
pack-type='start'
pack-index=4
EOT
dconf write /org/gnome/gnome-panel/layout/object-id-list "$(dconf read /org/gnome/gnome-panel/layout/object-id-list | sed "s/]/, 'object-10-top']/")"
#--- Show desktop
dconf load /org/gnome/gnome-panel/layout/objects/object-show-desktop/ << EOT
[/]
object-iid='WnckletFactory::ShowDesktopApplet'
toplevel-id='top-panel'
pack-type='end'
pack-index=0
EOT
dconf write /org/gnome/gnome-panel/layout/object-id-list "$(dconf read /org/gnome/gnome-panel/layout/object-id-list | sed "s/]/, 'object-show-desktop']/")"
#--- Fix icon top 10 shortcut icon
#convert /usr/share/icons/hicolor/48x48/apps/k.png -negate /usr/share/icons/hicolor/48x48/apps/k-invert.png
#/usr/share/icons/gnome/48x48/status/security-medium.png
#--- Enable only two workspaces
gsettings set org.gnome.desktop.wm.preferences num-workspaces 2   #gconftool-2 --type int --set /apps/metacity/general/num_workspaces 2 #dconf write /org/gnome/gnome-panel/layout/objects/workspace-switcher/instance-config/num-rows 4
gsettings set org.gnome.shell.overrides dynamic-workspaces false
#--- Smaller title bar
#sed -i "/title_vertical_pad/s/value=\"[0-9]\{1,2\}\"/value=\"0\"/g" /usr/share/themes/Adwaita/metacity-1/metacity-theme-3.xml
#sed -i 's/title_scale=".*"/title_scale="small"/g' /usr/share/themes/Adwaita/metacity-1/metacity-theme-3.xml
gsettings set org.gnome.desktop.wm.preferences titlebar-font 'Droid Bold 10'   # 'Cantarell Bold 11'
gsettings set org.gnome.desktop.wm.preferences titlebar-uses-system-font false
#--- Hide desktop icon
dconf write /org/gnome/nautilus/desktop/computer-icon-visible false
#--- Add "open with terminal" on right click menu
apt-get -y install nautilus-open-terminal
#--- Restart GNOME panel to apply/take effect (need to restart xserver)
#killall -w gnome-panel && gnome-panel&   # Still need to logoff!


##### Install & configure XFCE4
apt-get -y install xfce4 xfce4-places-plugin
mv /usr/bin/startx{,-gnome}
ln -sf /usr/bin/startx{fce4,}  # Old school ;)
mkdir -p /root/.config/xfce4/{desktop,menu,panel,xfconf,xfwm4}/
mkdir -p /root/.config/xfce4/panel/launcher-1{5,6,7,9}
mkdir -p /root/.config/xfce4/xfconf/xfce-perchannel-xml/
mkdir -p /root/.themes/
echo -e "[Wastebasket]\nrow=2\ncol=0\n\n[File System]\nrow=1\ncol=0\n\n[Home]\nrow=0\ncol=0" > /root/.config/xfce4/desktop/icons.screen0.rc
echo -e "show_button_icon=true\nshow_button_label=false\nlabel=Places\nshow_icons=true\nshow_volumes=true\nmount_open_volumes=false\nshow_bookmarks=true\nshow_recent=true\nshow_recent_clear=true\nshow_recent_number=10\nsearch_cmd=" > /root/.config/xfce4/panel/places-23.rc
echo -e "card=PlaybackES1371AudioPCI97AnalogStereoPulseAudioMixer\ntrack=Master\ncommand=xfce4-mixer" > /root/.config/xfce4/panel/xfce4-mixer-plugin-24.rc
echo -e "[Desktop Entry]\nEncoding=UTF-8\nName=Iceweasel\nComment=Browse the World Wide Web\nGenericName=Web Browser\nX-GNOME-FullName=Iceweasel Web Browser\nExec=iceweasel %u\nTerminal=false\nX-MultipleArgs=false\nType=Application\nIcon=iceweasel\nCategories=Network;WebBrowser;\nMimeType=text/html;text/xml;application/xhtml+xml;application/xml;application/vnd.mozilla.xul+xml;application/rss+xml;application/rdf+xml;image/gif;image/jpeg;image/png;x-scheme-handler/http;x-scheme-handler/https;\nStartupWMClass=Iceweasel\nStartupNotify=true\nX-XFCE-Source=file:///usr/share/applications/iceweasel.desktop" > /root/.config/xfce4/panel/launcher-15/13684522587.desktop
echo -e "[Desktop Entry]\nVersion=1.0\nType=Application\nExec=exo-open --launch TerminalEmulator\nIcon=utilities-terminal\nStartupNotify=false\nTerminal=false\nCategories=Utility;X-XFCE;X-Xfce-Toplevel;\nOnlyShowIn=XFCE;\nName=Terminal Emulator\nName[en_GB]=Terminal Emulator\nComment=Use the command line\nComment[en_GB]=Use the command line\nX-XFCE-Source=file:///usr/share/applications/exo-terminal-emulator.desktop" > /root/.config/xfce4/panel/launcher-16/13684522758.desktop
echo -e "[Desktop Entry]\nType=Application\nVersion=1.0\nName=Geany\nName[en_GB]=Geany\nGenericName=Integrated Development Environment\nGenericName[en_GB]=Integrated Development Environment\nComment=A fast and lightweight IDE using GTK2\nComment[en_GB]=A fast and lightweight IDE using GTK2\nExec=geany %F\nIcon=geany\nTerminal=false\nCategories=GTK;Development;IDE;\nMimeType=text/plain;text/x-chdr;text/x-csrc;text/x-c++hdr;text/x-c++src;text/x-java;text/x-dsrc;text/x-pascal;text/x-perl;text/x-python;application/x-php;application/x-httpd-php3;application/x-httpd-php4;application/x-httpd-php5;application/xml;text/html;text/css;text/x-sql;text/x-diff;\nStartupNotify=true\nX-XFCE-Source=file:///usr/share/applications/geany.desktop" > /root/.config/xfce4/panel/launcher-17/13684522859.desktop
echo -e "[Desktop Entry]\nVersion=1.0\nName=Application Finder\nName[en_GB]=Application Finder\nComment=Find and launch applications installed on your system\nComment[en_GB]=Find and launch applications installed on your system\nExec=xfce4-appfinder\nIcon=xfce4-appfinder\nStartupNotify=true\nTerminal=false\nType=Application\nCategories=X-XFCE;Utility;\nX-XFCE-Source=file:///usr/share/applications/xfce4-appfinder.desktop" > /root/.config/xfce4/panel/launcher-19/136845425410.desktop
echo -e '<?xml version="1.0" encoding="UTF-8"?>\n\n<channel name="xfce4-appfinder" version="1.0">\n  <property name="category" type="string" value="All"/>\n  <property name="window-width" type="int" value="640"/>\n  <property name="window-height" type="int" value="480"/>\n  <property name="close-after-execute" type="bool" value="true"/>\n</channel>' > /root/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-appfinder.xml
echo -e '<?xml version="1.0" encoding="UTF-8"?>\n\n<channel name="xfce4-desktop" version="1.0">\n  <property name="backdrop" type="empty">\n    <property name="screen0" type="empty">\n      <property name="monitor0" type="empty">\n        <property name="brightness" type="empty"/>\n        <property name="color1" type="empty"/>\n        <property name="color2" type="empty"/>\n        <property name="color-style" type="empty"/>\n        <property name="image-path" type="empty"/>\n        <property name="image-show" type="empty"/>\n        <property name="last-image" type="empty"/>\n        <property name="last-single-image" type="empty"/>\n      </property>\n    </property>\n  </property>\n  <property name="desktop-icons" type="empty">\n    <property name="file-icons" type="empty">\n      <property name="show-removable" type="bool" value="true"/>\n      <property name="show-trash" type="bool" value="false"/>\n      <property name="show-filesystem" type="bool" value="false"/>\n      <property name="show-home" type="bool" value="false"/>\n    </property>\n  </property>\n</channel>' > /root/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml
echo -e '<?xml version="1.0" encoding="UTF-8"?>\n\n<channel name="xfce4-keyboard-shortcuts" version="1.0">\n  <property name="commands" type="empty">\n    <property name="default" type="empty">\n      <property name="&lt;Alt&gt;F2" type="empty"/>\n      <property name="&lt;Primary&gt;&lt;Alt&gt;Delete" type="empty"/>\n      <property name="XF86Display" type="empty"/>\n      <property name="&lt;Super&gt;p" type="empty"/>\n      <property name="&lt;Primary&gt;Escape" type="empty"/>\n    </property>\n    <property name="custom" type="empty">\n      <property name="XF86Display" type="string" value="xfce4-display-settings --minimal"/>\n      <property name="&lt;Super&gt;p" type="string" value="xfce4-display-settings --minimal"/>\n      <property name="&lt;Primary&gt;&lt;Alt&gt;Delete" type="string" value="xflock4"/>\n      <property name="&lt;Primary&gt;Escape" type="string" value="xfdesktop --menu"/>\n      <property name="&lt;Alt&gt;F2" type="string" value="xfrun4"/>\n      <property name="override" type="bool" value="true"/>\n    </property>\n  </property>\n  <property name="xfwm4" type="empty">\n    <property name="default" type="empty">\n      <property name="&lt;Alt&gt;Insert" type="empty"/>\n      <property name="Escape" type="empty"/>\n      <property name="Left" type="empty"/>\n      <property name="Right" type="empty"/>\n      <property name="Up" type="empty"/>\n      <property name="Down" type="empty"/>\n      <property name="&lt;Alt&gt;Tab" type="empty"/>\n      <property name="&lt;Alt&gt;&lt;Shift&gt;Tab" type="empty"/>\n      <property name="&lt;Alt&gt;Delete" type="empty"/>\n      <property name="&lt;Control&gt;&lt;Alt&gt;Down" type="empty"/>\n      <property name="&lt;Control&gt;&lt;Alt&gt;Left" type="empty"/>\n      <property name="&lt;Shift&gt;&lt;Alt&gt;Page_Down" type="empty"/>\n      <property name="&lt;Alt&gt;F4" type="empty"/>\n      <property name="&lt;Alt&gt;F6" type="empty"/>\n      <property name="&lt;Alt&gt;F7" type="empty"/>\n      <property name="&lt;Alt&gt;F8" type="empty"/>\n      <property name="&lt;Alt&gt;F9" type="empty"/>\n      <property name="&lt;Alt&gt;F10" type="empty"/>\n      <property name="&lt;Alt&gt;F11" type="empty"/>\n      <property name="&lt;Alt&gt;F12" type="empty"/>\n      <property name="&lt;Control&gt;&lt;Shift&gt;&lt;Alt&gt;Left" type="empty"/>\n      <property name="&lt;Alt&gt;&lt;Control&gt;End" type="empty"/>\n      <property name="&lt;Alt&gt;&lt;Control&gt;Home" type="empty"/>\n      <property name="&lt;Control&gt;&lt;Shift&gt;&lt;Alt&gt;Right" type="empty"/>\n      <property name="&lt;Control&gt;&lt;Shift&gt;&lt;Alt&gt;Up" type="empty"/>\n      <property name="&lt;Alt&gt;&lt;Control&gt;KP_1" type="empty"/>\n      <property name="&lt;Alt&gt;&lt;Control&gt;KP_2" type="empty"/>\n      <property name="&lt;Alt&gt;&lt;Control&gt;KP_3" type="empty"/>\n      <property name="&lt;Alt&gt;&lt;Control&gt;KP_4" type="empty"/>\n      <property name="&lt;Alt&gt;&lt;Control&gt;KP_5" type="empty"/>\n      <property name="&lt;Alt&gt;&lt;Control&gt;KP_6" type="empty"/>\n      <property name="&lt;Alt&gt;&lt;Control&gt;KP_7" type="empty"/>\n      <property name="&lt;Alt&gt;&lt;Control&gt;KP_8" type="empty"/>\n      <property name="&lt;Alt&gt;&lt;Control&gt;KP_9" type="empty"/>\n      <property name="&lt;Alt&gt;space" type="empty"/>\n      <property name="&lt;Shift&gt;&lt;Alt&gt;Page_Up" type="empty"/>\n      <property name="&lt;Control&gt;&lt;Alt&gt;Right" type="empty"/>\n      <property name="&lt;Control&gt;&lt;Alt&gt;d" type="empty"/>\n      <property name="&lt;Control&gt;&lt;Alt&gt;Up" type="empty"/>\n      <property name="&lt;Super&gt;Tab" type="empty"/>\n      <property name="&lt;Control&gt;F1" type="empty"/>\n      <property name="&lt;Control&gt;F2" type="empty"/>\n      <property name="&lt;Control&gt;F3" type="empty"/>\n      <property name="&lt;Control&gt;F4" type="empty"/>\n      <property name="&lt;Control&gt;F5" type="empty"/>\n      <property name="&lt;Control&gt;F6" type="empty"/>\n      <property name="&lt;Control&gt;F7" type="empty"/>\n      <property name="&lt;Control&gt;F8" type="empty"/>\n      <property name="&lt;Control&gt;F9" type="empty"/>\n      <property name="&lt;Control&gt;F10" type="empty"/>\n      <property name="&lt;Control&gt;F11" type="empty"/>\n      <property name="&lt;Control&gt;F12" type="empty"/>\n    </property>\n    <property name="custom" type="empty">\n      <property name="&lt;Control&gt;F3" type="string" value="workspace_3_key"/>\n      <property name="&lt;Control&gt;F4" type="string" value="workspace_4_key"/>\n      <property name="&lt;Control&gt;F5" type="string" value="workspace_5_key"/>\n      <property name="&lt;Control&gt;F6" type="string" value="workspace_6_key"/>\n      <property name="&lt;Control&gt;F7" type="string" value="workspace_7_key"/>\n      <property name="&lt;Control&gt;F8" type="string" value="workspace_8_key"/>\n      <property name="&lt;Control&gt;F9" type="string" value="workspace_9_key"/>\n      <property name="&lt;Alt&gt;Tab" type="string" value="cycle_windows_key"/>\n      <property name="&lt;Control&gt;&lt;Alt&gt;Right" type="string" value="right_workspace_key"/>\n      <property name="Left" type="string" value="left_key"/>\n      <property name="&lt;Control&gt;&lt;Alt&gt;d" type="string" value="show_desktop_key"/>\n      <property name="&lt;Control&gt;&lt;Shift&gt;&lt;Alt&gt;Left" type="string" value="move_window_left_key"/>\n      <property name="&lt;Control&gt;&lt;Shift&gt;&lt;Alt&gt;Right" type="string" value="move_window_right_key"/>\n      <property name="Up" type="string" value="up_key"/>\n      <property name="&lt;Alt&gt;F4" type="string" value="close_window_key"/>\n      <property name="&lt;Alt&gt;F6" type="string" value="stick_window_key"/>\n      <property name="&lt;Control&gt;&lt;Alt&gt;Down" type="string" value="down_workspace_key"/>\n      <property name="&lt;Alt&gt;F7" type="string" value="move_window_key"/>\n      <property name="&lt;Alt&gt;F9" type="string" value="hide_window_key"/>\n      <property name="&lt;Alt&gt;F11" type="string" value="fullscreen_key"/>\n      <property name="&lt;Alt&gt;F8" type="string" value="resize_window_key"/>\n      <property name="&lt;Super&gt;Tab" type="string" value="switch_window_key"/>\n      <property name="Escape" type="string" value="cancel_key"/>\n      <property name="&lt;Alt&gt;&lt;Control&gt;KP_1" type="string" value="move_window_workspace_1_key"/>\n      <property name="&lt;Alt&gt;&lt;Control&gt;KP_2" type="string" value="move_window_workspace_2_key"/>\n      <property name="&lt;Alt&gt;&lt;Control&gt;KP_3" type="string" value="move_window_workspace_3_key"/>\n      <property name="&lt;Alt&gt;&lt;Control&gt;KP_4" type="string" value="move_window_workspace_4_key"/>\n      <property name="&lt;Alt&gt;&lt;Control&gt;KP_5" type="string" value="move_window_workspace_5_key"/>\n      <property name="&lt;Alt&gt;&lt;Control&gt;KP_6" type="string" value="move_window_workspace_6_key"/>\n      <property name="Down" type="string" value="down_key"/>\n      <property name="&lt;Control&gt;&lt;Shift&gt;&lt;Alt&gt;Up" type="string" value="move_window_up_key"/>\n      <property name="&lt;Shift&gt;&lt;Alt&gt;Page_Down" type="string" value="lower_window_key"/>\n      <property name="&lt;Alt&gt;F12" type="string" value="above_key"/>\n      <property name="&lt;Alt&gt;&lt;Control&gt;KP_8" type="string" value="move_window_workspace_8_key"/>\n      <property name="&lt;Alt&gt;&lt;Control&gt;KP_9" type="string" value="move_window_workspace_9_key"/>\n      <property name="Right" type="string" value="right_key"/>\n      <property name="&lt;Alt&gt;F10" type="string" value="maximize_window_key"/>\n      <property name="&lt;Control&gt;&lt;Alt&gt;Up" type="string" value="up_workspace_key"/>\n      <property name="&lt;Control&gt;F10" type="string" value="workspace_10_key"/>\n      <property name="&lt;Alt&gt;&lt;Control&gt;KP_7" type="string" value="move_window_workspace_7_key"/>\n      <property name="&lt;Alt&gt;&lt;Control&gt;End" type="string" value="move_window_next_workspace_key"/>\n      <property name="&lt;Alt&gt;Delete" type="string" value="del_workspace_key"/>\n      <property name="&lt;Control&gt;&lt;Alt&gt;Left" type="string" value="left_workspace_key"/>\n      <property name="&lt;Control&gt;F12" type="string" value="workspace_12_key"/>\n      <property name="&lt;Alt&gt;space" type="string" value="popup_menu_key"/>\n      <property name="&lt;Alt&gt;&lt;Shift&gt;Tab" type="string" value="cycle_reverse_windows_key"/>\n      <property name="&lt;Shift&gt;&lt;Alt&gt;Page_Up" type="string" value="raise_window_key"/>\n      <property name="&lt;Alt&gt;Insert" type="string" value="add_workspace_key"/>\n      <property name="&lt;Alt&gt;&lt;Control&gt;Home" type="string" value="move_window_prev_workspace_key"/>\n      <property name="&lt;Control&gt;F2" type="string" value="workspace_2_key"/>\n      <property name="&lt;Control&gt;F1" type="string" value="workspace_1_key"/>\n      <property name="&lt;Control&gt;F11" type="string" value="workspace_11_key"/>\n      <property name="override" type="bool" value="true"/>\n    </property>\n  </property>\n  <property name="providers" type="array">\n    <value type="string" value="xfwm4"/>\n    <value type="string" value="commands"/>\n  </property>\n</channel>' > /root/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml
echo -e '<?xml version="1.0" encoding="UTF-8"?>\n\n<channel name="xfce4-mixer" version="1.0">\n  <property name="active-card" type="string" value="PlaybackES1371AudioPCI97AnalogStereoPulseAudioMixer"/>\n  <property name="volume-step-size" type="uint" value="5"/>\n  <property name="sound-card" type="string" value="PlaybackES1371AudioPCI97AnalogStereoPulseAudioMixer"/>\n  <property name="sound-cards" type="empty">\n    <property name="PlaybackES1371AudioPCI97AnalogStereoPulseAudioMixer" type="array">\n      <value type="string" value="Master"/>\n    </property>\n  </property>\n  <property name="window-height" type="int" value="400"/>\n  <property name="window-width" type="int" value="738"/>\n</channel>' > /root/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-mixer.xml
echo -e '<?xml version="1.0" encoding="UTF-8"?>\n\n<channel name="xfce4-panel" version="1.0">\n  <property name="panels" type="uint" value="1">\n    <property name="panel-0" type="empty">\n      <property name="position" type="string" value="p=6;x=0;y=0"/>\n      <property name="length" type="uint" value="100"/>\n      <property name="position-locked" type="bool" value="true"/>\n      <property name="plugin-ids" type="array">\n        <value type="int" value="1"/>\n        <value type="int" value="15"/>\n        <value type="int" value="16"/>\n        <value type="int" value="17"/>\n        <value type="int" value="21"/>\n        <value type="int" value="23"/>\n        <value type="int" value="19"/>\n        <value type="int" value="3"/>\n        <value type="int" value="24"/>\n        <value type="int" value="6"/>\n        <value type="int" value="2"/>\n        <value type="int" value="5"/>\n        <value type="int" value="4"/>\n        <value type="int" value="25"/>\n      </property>\n      <property name="background-alpha" type="uint" value="90"/>\n    </property>\n  </property>\n  <property name="plugins" type="empty">\n    <property name="plugin-1" type="string" value="applicationsmenu">\n      <property name="button-icon" type="string" value="kali-menu"/>\n      <property name="show-button-title" type="bool" value="false"/>\n      <property name="show-generic-names" type="bool" value="true"/>\n      <property name="show-tooltips" type="bool" value="true"/>\n    </property>\n    <property name="plugin-2" type="string" value="actions"/>\n    <property name="plugin-3" type="string" value="tasklist"/>\n    <property name="plugin-4" type="string" value="pager">\n      <property name="rows" type="uint" value="1"/>\n    </property>\n    <property name="plugin-5" type="string" value="clock">\n      <property name="digital-format" type="string" value="%R, %A %d %B %Y"/>\n    </property>\n    <property name="plugin-6" type="string" value="systray">\n      <property name="names-visible" type="array">\n        <value type="string" value="networkmanager applet"/>\n      </property>\n    </property>\n    <property name="plugin-15" type="string" value="launcher">\n      <property name="items" type="array">\n        <value type="string" value="13684522587.desktop"/>\n      </property>\n    </property>\n    <property name="plugin-16" type="string" value="launcher">\n      <property name="items" type="array">\n        <value type="string" value="13684522758.desktop"/>\n      </property>\n    </property>\n    <property name="plugin-17" type="string" value="launcher">\n      <property name="items" type="array">\n        <value type="string" value="13684522859.desktop"/>\n      </property>\n    </property>\n    <property name="plugin-21" type="string" value="applicationsmenu">\n      <property name="custom-menu" type="bool" value="true"/>\n      <property name="custom-menu-file" type="string" value="/root/.config/xfce4/menu/top10.menu"/>\n      <property name="button-icon" type="string" value="security-medium"/>\n      <property name="show-button-title" type="bool" value="false"/>\n      <property name="button-title" type="string" value="Top 10"/>\n    </property>\n    <property name="plugin-19" type="string" value="launcher">\n      <property name="items" type="array">\n        <value type="string" value="136845425410.desktop"/>\n      </property>\n    </property>\n    <property name="plugin-22" type="empty">\n      <property name="base-directory" type="string" value="/root"/>\n      <property name="hidden-files" type="bool" value="false"/>\n    </property>\n    <property name="plugin-23" type="string" value="places"/>\n    <property name="plugin-24" type="string" value="xfce4-mixer-plugin"/>\n    <property name="plugin-25" type="string" value="showdesktop"/>\n  </property>\n</channel>' > /root/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml
echo -e '<?xml version="1.0" encoding="UTF-8"?>\n\n<channel name="xfce4-settings-editor" version="1.0">\n  <property name="window-width" type="int" value="600"/>\n  <property name="window-height" type="int" value="380"/>\n  <property name="hpaned-position" type="int" value="200"/>\n</channel>' > /root/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-settings-editor.xml
echo -e '<?xml version="1.0" encoding="UTF-8"?>\n\n<channel name="xfwm4" version="1.0">\n  <property name="general" type="empty">\n    <property name="activate_action" type="string" value="bring"/>\n    <property name="borderless_maximize" type="bool" value="true"/>\n    <property name="box_move" type="bool" value="false"/>\n    <property name="box_resize" type="bool" value="false"/>\n    <property name="button_layout" type="string" value="O|SHMC"/>\n    <property name="button_offset" type="int" value="0"/>\n    <property name="button_spacing" type="int" value="0"/>\n    <property name="click_to_focus" type="bool" value="true"/>\n    <property name="focus_delay" type="int" value="250"/>\n    <property name="cycle_apps_only" type="bool" value="false"/>\n    <property name="cycle_draw_frame" type="bool" value="true"/>\n    <property name="cycle_hidden" type="bool" value="true"/>\n    <property name="cycle_minimum" type="bool" value="true"/>\n    <property name="cycle_workspaces" type="bool" value="false"/>\n    <property name="double_click_time" type="int" value="250"/>\n    <property name="double_click_distance" type="int" value="5"/>\n    <property name="double_click_action" type="string" value="maximize"/>\n    <property name="easy_click" type="string" value="Alt"/>\n    <property name="focus_hint" type="bool" value="true"/>\n    <property name="focus_new" type="bool" value="true"/>\n    <property name="frame_opacity" type="int" value="100"/>\n    <property name="full_width_title" type="bool" value="true"/>\n    <property name="inactive_opacity" type="int" value="100"/>\n    <property name="maximized_offset" type="int" value="0"/>\n    <property name="move_opacity" type="int" value="100"/>\n    <property name="placement_ratio" type="int" value="20"/>\n    <property name="placement_mode" type="string" value="center"/>\n    <property name="popup_opacity" type="int" value="100"/>\n    <property name="mousewheel_rollup" type="bool" value="true"/>\n    <property name="prevent_focus_stealing" type="bool" value="false"/>\n    <property name="raise_delay" type="int" value="250"/>\n    <property name="raise_on_click" type="bool" value="true"/>\n    <property name="raise_on_focus" type="bool" value="false"/>\n    <property name="raise_with_any_button" type="bool" value="true"/>\n    <property name="repeat_urgent_blink" type="bool" value="false"/>\n    <property name="resize_opacity" type="int" value="100"/>\n    <property name="restore_on_move" type="bool" value="true"/>\n    <property name="scroll_workspaces" type="bool" value="true"/>\n    <property name="shadow_delta_height" type="int" value="0"/>\n    <property name="shadow_delta_width" type="int" value="0"/>\n    <property name="shadow_delta_x" type="int" value="0"/>\n    <property name="shadow_delta_y" type="int" value="-3"/>\n    <property name="shadow_opacity" type="int" value="50"/>\n    <property name="show_app_icon" type="bool" value="false"/>\n    <property name="show_dock_shadow" type="bool" value="true"/>\n    <property name="show_frame_shadow" type="bool" value="false"/>\n    <property name="show_popup_shadow" type="bool" value="false"/>\n    <property name="snap_resist" type="bool" value="false"/>\n    <property name="snap_to_border" type="bool" value="true"/>\n    <property name="snap_to_windows" type="bool" value="false"/>\n    <property name="snap_width" type="int" value="10"/>\n    <property name="theme" type="string" value="Shiki-Colors-Light-Menus"/>\n    <property name="title_alignment" type="string" value="center"/>\n    <property name="title_font" type="string" value="Sans Bold 9"/>\n    <property name="title_horizontal_offset" type="int" value="0"/>\n    <property name="title_shadow_active" type="string" value="false"/>\n    <property name="title_shadow_inactive" type="string" value="false"/>\n    <property name="title_vertical_offset_active" type="int" value="0"/>\n    <property name="title_vertical_offset_inactive" type="int" value="0"/>\n    <property name="toggle_workspaces" type="bool" value="false"/>\n    <property name="unredirect_overlays" type="bool" value="true"/>\n    <property name="urgent_blink" type="bool" value="false"/>\n    <property name="use_compositing" type="bool" value="true"/>\n    <property name="workspace_count" type="int" value="2"/>\n    <property name="wrap_cycle" type="bool" value="true"/>\n    <property name="wrap_layout" type="bool" value="true"/>\n    <property name="wrap_resistance" type="int" value="10"/>\n    <property name="wrap_windows" type="bool" value="true"/>\n    <property name="wrap_workspaces" type="bool" value="false"/>\n    <property name="workspace_names" type="array">\n      <value type="string" value="Workspace 1"/>\n      <value type="string" value="Workspace 2"/>\n      <value type="string" value="Workspace 3"/>\n      <value type="string" value="Workspace 4"/>\n    </property>\n  </property>\n</channel>' > /root/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml
echo -e '<?xml version="1.0" encoding="UTF-8"?>\n\n<channel name="xsettings" version="1.0">\n  <property name="Net" type="empty">\n    <property name="ThemeName" type="empty"/>\n    <property name="IconThemeName" type="empty"/>\n    <property name="DoubleClickTime" type="int" value="250"/>\n    <property name="DoubleClickDistance" type="int" value="5"/>\n    <property name="DndDragThreshold" type="int" value="8"/>\n    <property name="CursorBlink" type="bool" value="true"/>\n    <property name="CursorBlinkTime" type="int" value="1200"/>\n    <property name="SoundThemeName" type="string" value="default"/>\n    <property name="EnableEventSounds" type="bool" value="false"/>\n    <property name="EnableInputFeedbackSounds" type="bool" value="false"/>\n  </property>\n  <property name="Xft" type="empty">\n    <property name="DPI" type="empty"/>\n    <property name="Antialias" type="int" value="-1"/>\n    <property name="Hinting" type="int" value="-1"/>\n    <property name="HintStyle" type="string" value="hintnone"/>\n    <property name="RGBA" type="string" value="none"/>\n  </property>\n  <property name="Gtk" type="empty">\n    <property name="CanChangeAccels" type="bool" value="false"/>\n    <property name="ColorPalette" type="string" value="black:white:gray50:red:purple:blue:light blue:green:yellow:orange:lavender:brown:goldenrod4:dodger blue:pink:light green:gray10:gray30:gray75:gray90"/>\n    <property name="FontName" type="string" value="Sans 10"/>\n    <property name="IconSizes" type="string" value=""/>\n    <property name="KeyThemeName" type="string" value=""/>\n    <property name="ToolbarStyle" type="string" value="icons"/>\n    <property name="ToolbarIconSize" type="int" value="3"/>\n    <property name="IMPreeditStyle" type="string" value=""/>\n    <property name="IMStatusStyle" type="string" value=""/>\n    <property name="MenuImages" type="bool" value="true"/>\n    <property name="ButtonImages" type="bool" value="true"/>\n    <property name="MenuBarAccel" type="string" value="F10"/>\n    <property name="CursorThemeName" type="string" value=""/>\n    <property name="CursorThemeSize" type="int" value="0"/>\n    <property name="IMModule" type="string" value=""/>\n  </property>\n</channel>' > /root/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml
echo -e '<Menu>\n\t<Name>Top 10</Name>\n\t<DefaultAppDirs/>\n\t<Directory>top10.directory</Directory>\n\t<Include>\n\t\t<Category>top10</Category>\n\t</Include>\n</Menu>' > /root/.config/xfce4/menu/top10.menu
sed -i 's/^enable=.*/enable=False/' /etc/xdg/user-dirs.conf   #sed -i 's/^XDG_/#XDG_/; s/^#XDG_DESKTOP/XDG_DESKTOP/;' /root/.config/user-dirs.dirs
rm -rf /root/{Documents,Downloads,Music,Pictures,Public,Templates,Videos}/
rm -f /root/.cache/sessions/*
wget http://xfce-look.org/CONTENT/content-files/142110-Shiki-Colors-Light-Menus.tar.gz -O /tmp/Shiki-Colors-Light-Menus.tar.gz
tar zxf /tmp/Shiki-Colors-Light-Menus.tar.gz -C /root/.themes/
xfconf-query -c xsettings -p /Net/ThemeName -s "Shiki-Colors-Light-Menus"
xfconf-query -c xsettings -p /Net/IconThemeName -s "gnome-brave"
#--- Enable compositing
xfconf-query -c xfwm4 -p /general/use_compositing -s true
#--- Configure file browser (need to re-login for effect)
mkdir -p /root/.config/Thunar/
if [ ! -e /root/.config/Thunar/thunarrc ]; then echo -e "[Configuration]\nLastShowHidden=TRUE" > /root/.config/Thunar/thunarrc; else sed -i 's/LastShowHidden=.*/LastShowHidden=TRUE/' /root/.config/Thunar/thunarrc; fi


##### Configure (TTY) resolution
file=/etc/default/grub; if [ -e $file ]; then cp -n $file{,.bkup}; fi
sed -i 's/GRUB_TIMEOUT=.*/GRUB_TIMEOUT=1/' /etc/default/grub
sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="vga=0x0318 quiet"/' /etc/default/grub
update-grub


##### Configure login (console login - non GUI)
file=/etc/X11/default-display-manager; if [ -e $file ]; then cp -n $file{,.bkup}; fi
echo > /etc/X11/default-display-manager
file=/etc/gdm3/daemon.conf; if [ -e $file ]; then cp -n $file{,.bkup}; fi
sed -i 's/^.*AutomaticLoginEnable = .*/AutomaticLoginEnable = True/' /etc/gdm3/daemon.conf
sed -i 's/^.*AutomaticLogin = .*/AutomaticLogin = root/' /etc/gdm3/daemon.conf
#ln -s /usr/sbin/gdm3 /usr/bin/startx   # Old school ;) <--- We want XFCE over GNOME anyway


##### Configure terminal (need to restart xserver)
gconftool-2 --type bool --set /apps/gnome-terminal/profiles/Default/scrollback_unlimited true    # Terminal -> Edit -> Profile Preferences -> Scrolling -> Scrollback: Unlimited -> Close
gconftool-2 --type string --set /apps/gnome-terminal/profiles/Default/background_darkness 0.85611499999999996   # Not working 100%!
gconftool-2 --type string --set /apps/gnome-terminal/profiles/Default/background_type transparent


##### Enable num lock at start up (might not be smart if you're using a smaller keyboard (laptop?))
apt-get -y install numlockx
file=/etc/gdm3/Init/Default; if [ -e $file ]; then cp -n $file{,.bkup}; fi
grep -q '/usr/bin/numlockx' /etc/gdm3/Init/Default || sed -i 's#exit 0#if [ -x /usr/bin/numlockx ]; then\n/usr/bin/numlockx on\nfi\nexit 0#' /etc/gdm3/Init/Default
#xfconf-query -c keyboards -p /Default/Numlock -s true


##### Configure startup (randomize the hostname, eth0 & wlan0's MAC address)
#if [[ `grep -q macchanger /etc/rc.local; echo $?` == 1 ]]; then sed -i 's#^exit 0#for int in eth0 wlan0; do\n\tifconfig $int down\n\t/usr/bin/macchanger -r $int \&\& sleep 3\n\tifconfig $int up\ndone\n\n\nexit 0#' /etc/rc.local; fi
##echo -e '#!/bin/bash\nfor int in eth0 wlan0; do\n\techo "Randomizing: $int"\n\tifconfig $int down\n\tmacchanger -r $int\n\tsleep 3\n\tifconfig $int up\n\techo "--------------------"\ndone\nexit 0' > /etc/init.d/macchanger
##echo -e '#!/bin/bash\n[ "$IFACE" == "lo" ] && exit 0\nifconfig $IFACE down\nmacchanger -r $IFACE\nifconfig $IFACE up\nexit 0' > /etc/network/if-pre-up.d/macchanger
#grep -q "hostname" /etc/rc.local hostname || sed -i 's#^exit 0#hostname $(cat /dev/urandom | tr -dc "A-Za-z" | head -c8)\nexit 0#' /etc/rc.local


##### Install terminator
apt-get -y install terminator
#--- Configure terminator
if [ -e /root/.config/terminator/config ]; then cp -n /root/.config/terminator/config{.bkup}; fi
mkdir -p /root/.config/terminator/
echo -e '[global_config]\n  enabled_plugins = TerminalShot, LaunchpadCodeURLHandler, APTURLHandler, LaunchpadBugURLHandler\n[keybindings]\n[profiles]\n  [[default]]\n    background_darkness = 0.9\n    copy_on_selection = True\n    background_type = transparent\n    scrollback_infinite = True\n[layouts]\n  [[default]]\n    [[[child1]]]\n      type = Terminal\n      parent = window0\n    [[[window0]]]\n      type = Window\n      parent = ""\n[plugins]' > /root/.config/terminator/config


##### Install zsh
apt-get -y install zsh git
#--- Setup oh-my-zsh
curl -s -L https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh | sh
#--- Configure zsh
file=/root/.zshrc; if [ -e $file ]; then cp -n $file{,.bkup}; fi   #/etc/zsh/zshrc
grep -q interactivecomments /root/.zshrc || echo "setopt interactivecomments" >> /root/.zshrc
grep -q ignoreeof /root/.zshrc || echo "setopt ignoreeof" >> /root/.zshrc
grep -q correctall /root/.zshrc || echo "setopt correctall" >> /root/.zshrcsudo
grep -q globdots /root/.zshrc || echo "setopt globdots" >> /root/.zshrc
grep -q bash_aliases /root/.zshrc || echo -e 'source $HOME/.bash_aliases' >> /root/.zshrc   #grep -q bashrc /root/.zshrc || echo -e 'source $HOME/.bashrc' >> /root/.zshrc
#--- Configure zsh (themes) ~ https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
sed -i 's/ZSH_THEME=.*/ZSH_THEME="alanpeabody"/' /root/.zshrc   # alanpeabody jreese   mh   candy   terminalparty kardan   nicoulaj sunaku    (Other themes I liked)
#--- Configure oh-my-zsh
sed -i 's/.*DISABLE_AUTO_UPDATE="true"/DISABLE_AUTO_UPDATE="true"/' /root/.zshrc
sed -i 's/plugins=(.*)/plugins=(git screen tmux last-working-dir)/' /root/.zshrc
#--- Set zsh as default
chsh -s `which zsh`
#--- Use zsh
#/usr/bin/env zsh
#source /root/.zshrc


##### Configure tmux
apt-get -y install tmux
#--- Configure tmux
file=/root/.tmux.conf; if [ -e $file ]; then cp -n $file{,.bkup}; fi
echo -e "#-References-------------------------------------------------------------------\n# http://blog.hawkhost.com/2010/07/02/tmux-%E2%80%93-the-terminal-multiple...\n# https://wiki.archlinux.org/index.php/Tmux\n\n\n#-Settings---------------------------------------------------------------------\n# Make it like screen (use C-a)\nunbind C-b\nset -g prefix C-a\n\n# Pane switching with Alt+arrow\nbind -n M-Left select-pane -L\nbind -n M-Right select-pane -R\nbind -n M-Up select-pane -U\nbind -n M-Down select-pane -D\n\n# Activity Monitoring\nsetw -g monitor-activity on\nset -g visual-activity on\n\n# Reaload settings\nunbind R\nbind R source-file ~/.tmux.conf\n\n# Load custom sources\nsource ~/.bashrc\n\n# Set defaults\nset -g default-terminal screen-256color\nset -g history-limit 5000\n\n# Defult windows titles\nset -g set-titles on\nset -g set-titles-string '#(whoami)@#H - #I:#W'\n\n# Last window switch\nbind-key C-a last-window\n\n# Use ZSH as default shell\nset-option -g default-shell /bin/zsh\n\n# Show tmux messages for longer\nset -g display-time 3000\n\n# Status bar is redrawn every minute\nset -g status-interval 60\n\n\n#-Theme------------------------------------------------------------------------\n# Default colours\nset -g status-bg black\nset -g status-fg white\n\n# Left hand side\nset -g status-left-length 30\nset -g status-left '#[fg=green,bold]#(whoami)#[gf=green]@#H #[fg=green,dim][#[fg=yellow]#(cut -d \" \" -f 1-3 /proc/loadavg)#[fg=green,dim]]'\n\n# Inactive windows in status bar\nset-window-option -g window-status-format '#[fg=red,dim]#I#[fg=grey,dim]:#[default,dim]#W#[fg=grey,dim]'\n\n# Current or active window in status bar\n#set-window-option -g window-status-current-format '#[bg=white,fg=red]#I#[bg=white,fg=grey]:#[bg=white,fg=black]#W#[fg=dim]#F'\nset-window-option -g window-status-current-format '#[fg=red,bold](#[fg=white,bold]#I#[fg=red,dim]:#[fg=white,bold]#W#[fg=red,bold])'\n\n# Right hand side\nset -g status-right '#[fg=green][#[fg=yellow]%Y-%m-%d #[fg=white]%H:%M#[default]#[fg=green]]'" > /root/.tmux.conf
#--- Setup alias
file=/root/.bash_aliases; if [ -e $file ]; then cp -n $file{,.bkup}; fi
grep -q 'alias tmux="tmux attach || tmux new"' /root/.bash_aliases 2>/dev/null || echo 'alias tmux="tmux attach || tmux new"' >> /root/.bash_aliases
source /root/.bash_aliases
#--- Use tmux
#tmux   # If ZSH isn't installed, it will not start up


##### Configure screen (if possible, use tmux instead)
apt-get -y install screen
#--- Configure screen
file=/root/.screenrc; if [ -e $file ]; then cp -n $file{,.bkup}; fi
echo -e "# Don't display the copyright page\nstartup_message off\n\n# tab-completion flash in heading bar\nvbell off\n\n# keep scrollback n lines\ndefscrollback 1000\n\n# hardstatus is a bar of text that is visible in all screens\nhardstatus on\nhardstatus alwayslastline\nhardstatus string '%{gk}%{G}%H %{g}[%{Y}%l%{g}] %= %{wk}%?%-w%?%{=b kR}(%{W}%n %t%?(%u)%?%{=b kR})%{= kw}%?%+w%?%?%= %{g} %{Y} %Y-%m-%d %C%a %{W}'\n\n# title bar\ntermcapinfo xterm ti@:te@\n\n# default windows (syntax: screen -t label order command)\nscreen -t bash1 0\nscreen -t bash2 1\n\n# select the default window\nselect 1" > /root/.screenrc


##### Install bash-completion
apt-get -y install bash-completion
#sed -i '/# enable bash completion in/,+3{/enable bash completion/!s/^#//}' /root/.bashrc


##### Configure aliases
#--- Enable defaults
for file in /root/.bash_aliases /root/.bashrc /etc/bashrc /etc/bash.bashrc; do
   if [ -e $file ]; then cp -n $file{,.bkup}; fi
   touch $file
   sed -i 's/#alias/alias/g' $file
done
#--- Add in ours
grep -q '### tmux' /root/.bash_aliases || echo -e '\n### tmux\nalias tmux="tmux attach || tmux new"\n' >> /root/.bash_aliases
grep -q '### axel' /root/.bash_aliases || echo -e '\n### axel\nalias axel="axel -a"\n' >> /root/.bash_aliases
grep -q '### screen' /root/.bash_aliases || echo -e '\n### screen\nalias screen="screen -xRR"\n' >> /root/.bash_aliases
grep -q '### Directory navigation aliases' /root/.bash_aliases || echo -e '\n### Directory navigation aliases\nalias ..="cd .."\nalias ...="cd ../.."\nalias ....="cd ../../.."\nalias .....="cd ../../../.."\n\n' >> /root/.bash_aliases
grep -q '### Add more aliases' /root/.bash_aliases || echo -e '\n### Add more aliases\nalias upd="sudo apt-get update"\nalias upg="sudo apt-get upgrade"\nalias ins="sudo apt-get install"\nalias rem="sudo apt-get purge"\nalias fix="sudo apt-get install -f"\n\n' >> /root/.bash_aliases
grep -q '### Extract file, example' /root/.bash_aliases || echo -e '\n### Extract file, example. "ex package.tar.bz2"\nex() {\n    if [[ -f $1 ]]; then\n        case $1 in\n            *.tar.bz2)   tar xjf $1  ;;\n            *.tar.gz)    tar xzf $1  ;;\n            *.bz2)       bunzip2 $1  ;;\n            *.rar)       rar x $1    ;;\n            *.gz)        gunzip $1   ;;\n            *.tar)       tar xf $1   ;;\n            *.tbz2)      tar xjf $1  ;;\n            *.tgz)       tar xzf $1  ;;\n            *.zip)       unzip $1    ;;\n            *.Z)         uncompress $1  ;;\n            *.7z)        7z x $1     ;;\n            *)           echo $1 cannot be extracted ;;\n        esac\n    else\n        echo $1 is not a valid file\n    fi\n}' >> /root/.bash_aliases
#--- Apply new aliases
source /root/.bash_aliases     #source /root/.bashrc    # If using ZSH, will fail
#--- Check
#alias


##### Configure vim
file=/etc/vim/vimrc; if [ -e $file ]; then cp -n $file{,.bkup}; fi   #cp -f /etc/vim/vimrc /root/.vimrc
sed -i 's/.*syntax on/syntax on/' $file
sed -i 's/.*set background=dark/set background=dark/' $file
sed -i 's/.*set showcmd/set showcmd/' $file
sed -i 's/.*set showmatch/set showmatch/' $file
sed -i 's/.*set ignorecase/set ignorecase/' $file
sed -i 's/.*set smartcase/set smartcase/' $file
sed -i 's/.*set incsearch/set incsearch/' $file
sed -i 's/.*set autowrite/set autowrite/' $file
sed -i 's/.*set hidden/set hidden/' $file
sed -i 's/.*set mouse=.*/"set mouse=a/' $file
grep -q '^set number' $file || echo 'set number' >> $file                                          # Add line numbers
grep -q '^set autoindent' $file || echo 'set autoindent' >> $file                                  # Set auto indent
grep -q '^set expandtab' $file || echo -e 'set expandtab\nset smarttab' >> $file                   # Set use spaces instead of tabs
grep -q '^set softtabstop' $file || echo -e 'set softtabstop=4\nset shiftwidth=4' >> $file         # Set 4 spaces as a 'tab'
grep -q '^set foldmethod=marker' $file || echo 'set foldmethod=marker' >> $file                    # Folding
grep -q '^nnoremap <space> za' $file || echo 'nnoremap <space> za' >> $file                        # Space toggle folds
grep -q '^set hlsearch' $file || echo 'set hlsearch' >> $file                                      # Highlight search results
grep -q '^set laststatus' $file || echo -e 'set laststatus=2\nset statusline=%F%m%r%h%w\ (%{&ff}){%Y}\ [%l,%v][%p%%]' >> $file   # Status bar
grep -q '^filetype on' $file || echo -e 'filetype on\nfiletype plugin on\nsyntax enable\nset grepprg=grep\ -nH\ $*' >> $file     # Syntax Highlighting
grep -q '^set wildmenu' $file || echo -e 'set wildmenu\nset wildmode=list:longest,full' >> $file   # Tab completion


##### Configure file browser (need to restart xserver)
mkdir -p /root/.config/gtk-2.0/
if [ -e /root/.config/gtk-2.0/gtkfilechooser.ini ]; then sed -i 's/^.*ShowHidden.*/ShowHidden=true/' /root/.config/gtk-2.0/gtkfilechooser.ini; else echo -e "\n[Filechooser Settings]\nLocationMode=path-bar\nShowHidden=true\nExpandFolders=false\nShowSizeColumn=true\nGeometryX=66\nGeometryY=39\nGeometryWidth=780\nGeometryHeight=618\nSortColumn=name\nSortOrder=ascending" > /root/.config/gtk-2.0/gtkfilechooser.ini; fi   #Open/save Window -> Right click -> Show Hidden Files: Enabled
dconf write /org/gnome/nautilus/preferences/show-hidden-files true
if [ -e /root/.gtk-bookmarks ]; then cp -n /root/.gtk-bookmarks{,.bkup}; fi
echo -e 'file:///var/www www\nfile:///usr/share apps\nfile:///tmp tmp\nfile:///usr/local/src/ src' >> /root/.gtk-bookmarks


##### Setup iceweasel
#--- Configure iceweasel
iceweasel & sleep 15; killall -w iceweasel   # Start and kill. Files needed for first time run
if [[ `grep -q "browser.startup.page" /root/.mozilla/firefox/*.default/prefs.js; echo $?` == 1 ]]; then echo 'user_pref("browser.startup.page", 0);' >> /root/.mozilla/firefox/*.default/prefs.js; else sed -i 's/^.*browser.startup.page.*/user_pref("browser.startup.page", 0);' /root/.mozilla/firefox/*.default/prefs.js; fi   # Iceweasel -> Edit -> Preferences -> General -> When firefox starts: Show a blank page
if [[ `grep -q "privacy.donottrackheader.enabled" /root/.mozilla/firefox/*.default/prefs.js; echo $?` == 1 ]]; then echo 'user_pref("privacy.donottrackheader.enabled", true);' >> /root/.mozilla/firefox/*.default/prefs.js; else sed -i 's/^.*privacy.donottrackheader.enabled.*/user_pref("privacy.donottrackheader.enabled", true);' /root/.mozilla/firefox/*.default/prefs.js; fi   # Privacy -> Enable: Tell websites I do not want to be tracked
if [[ `grep -q "browser.showQuitWarning" /root/.mozilla/firefox/*.default/prefs.js; echo $?` == 1 ]]; then echo 'user_pref("browser.showQuitWarning", true);' >> /root/.mozilla/firefox/*.default/prefs.js; else sed -i 's/^.*browser.showQuitWarning.*/user_pref("browser.showQuitWarning", true);' /root/.mozilla/firefox/*.default/prefs.js; fi   # Stop Ctrl + Q from quitting without warning
#--- Replace bookmarks
cd /root/.mozilla/firefox/*.default/
wget http://pentest-bookmarks.googlecode.com/files/bookmarksv1.5.html   # ***!!! hardcoded version! Need to manually check for updates
if [ -e bookmarks.html ]; then cp -n bookmarks.html{,.bkup}; fi
rm -f /root/.mozilla/firefox/*.default/places.sqlite
rm -f /root/.mozilla/firefox/*.default/bookmarkbackups/*
#--- Configure bookmarks
awk '!a[$0]++' bookmarksv*.html | egrep -v ">(Latest Headlines|Getting Started|Recently Bookmarked|Recent Tags|Mozilla Firefox|Help and Tutorials|Customize Firefox|Get Involved|About Us|Hacker Media|Bookmarks Toolbar|Most Visited)</" | egrep -v "^    </DL><p>" | egrep -v "^<DD>Add" > bookmarks.html
sed -i 's#^</DL><p>#        </DL><p>\n    </DL><p>\n    <DT><A HREF="https://127.0.0.1:8834">Nessus</A>\n    <DT><A HREF="https://127.0.0.1:9392">OpenVAS</A>\n    <DT><A HREF="https://127.0.0.1:3790">MSF Community</A>\n</DL><p>#' bookmarks.html
sed -i 's#<HR>#<DT><H3 ADD_DATE="1303667175" LAST_MODIFIED="1303667175" PERSONAL_TOOLBAR_FOLDER="true">Bookmarks Toolbar</H3>\n<DD>Add bookmarks to this folder to see them displayed on the Bookmarks Toolbar#' bookmarks.html
#--- Install addons
cd /root/.mozilla/firefox/*.default/
mkdir -p extensions/
cd /root/.mozilla/firefox/*.default/extensions/
wget https://addons.mozilla.org/firefox/downloads/latest/1865/addon-1865-latest.xpi?src=dp-btn-primary -O {d10d0bf8-f5b5-c8b4-a8b2-2b9879e08c5d}.xpi          # Adblock Plus
wget https://addons.mozilla.org/firefox/downloads/latest/92079/addon-92079-latest.xpi?src=dp-btn-primary  -O {bb6bc1bb-f824-4702-90cd-35e2fb24f25d}.xpi       # Cookies Manager+
wget https://addons.mozilla.org/firefox/downloads/latest/1843/addon-1843-latest.xpi?src=dp-btn-primary -O firebug@software.joehewitt.com.xpi                  # Firebug - not working 100%
wget https://addons.mozilla.org/firefox/downloads/file/150692/foxyproxy_basic-2.6.2-fx+tb+sm.xpi?src=search -O FoxyProxyBasic.zip && unzip -o FoxyProxyBasic.zip -d foxyproxy-basic@eric.h.jung/ && rm -f FoxyProxyBasic.zip   # FoxyProxy Basic
#wget https://addons.mozilla.org/firefox/downloads/latest/284030/addon-284030-latest.xpi?src=dp-btn-primary -O {6bdc61ae-7b80-44a3-9476-e1d121ec2238}.xpi     # HTTPS Finder
wget https://www.eff.org/files/https-everywhere-latest.xpi -O https-everywhere@eff.org.xpi                                                                    # HTTPS Everywhere
wget https://addons.mozilla.org/firefox/downloads/latest/3829/addon-3829-latest.xpi?src=dp-btn-primary -O {8f8fe09b-0bd3-4470-bc1b-8cad42b8203a}.xpi          # Live HTTP Headers
wget https://addons.mozilla.org/firefox/downloads/file/79565/tamper_data-11.0.1-fx.xpi?src=dp-btn-primary -O {9c51bd27-6ed8-4000-a2bf-36cb95c0c947}.xpi       # Tamper Data  - not working 100%
wget https://addons.mozilla.org/firefox/downloads/latest/300254/addon-300254-latest.xpi?src=dp-btn-primary -O check-compatibility@dactyl.googlecode.com.xpi   # Disable Add-on Compatibility Checks
#for z in *.xpi; do
# d=`basename $z .xpi`
# mkdir $d && unzip -o $z -d $d
#done
iceweasel   #<--- Doesn't automate
#--- Configure foxyproxy
sed -i 's/<proxies><proxy name="Default"/<proxies><proxy name="Localhost:8080" id="315347393" notes="Localhost:8080" enabled="true" mode="manual" selectedTabIndex="1" lastresort="false" animatedIcons="true" includeInCycle="true" color="#FF051A" proxyDNS="true" noInternalIPs="false" autoconfMode="pac" clearCacheBeforeUse="true" disableCache="false" clearCookiesBeforeUse="false" rejectCookies="false"><matches\/><autoconf url="" loadNotification="true" errorNotification="true" autoReload="false" reloadFreqMins="60" disableOnBadPAC="true"\/><autoconf url="http:\/\/wpad\/wpad.dat" loadNotification="true" errorNotification="true" autoReload="false" reloadFreqMins="60" disableOnBadPAC="true"\/><manualconf host="localhost" port="8080" socksversion="5" isSocks="false"\/><\/proxy><proxy name="Default"/' /root/.mozilla/firefox/*.default/foxyproxy.xml
cd ~/


##### Configure metasploit ~ http://docs.kali.org/general-use/starting-metasploit-framework-in-kali
#--- Start services
service postgresql start
service metasploit start
#--- Misc
export GOCOW=1   # Always a cow logo ;)
grep -q GOCOW /root/.bashrc || echo 'GOCOW=1' >> /root/.bashrc
#--- First time run
echo 'exit' > /tmp/msf.rc   #echo -e 'go_pro\nexit' > /tmp/msf.rc
msfconsole -r /tmp/msf.rc
#--- Sort out metasploiit
bash /opt/metasploit/scripts/launchui.sh    #<--- Doesn't automate. May take a little while to kick in
#--- Clean up
rm -f /tmp/msf.rc


##### Setup ssh
rm -f /etc/ssh/ssh_host_*
rm -f /root/.ssh/*
ssh-keygen -A
ssh-keygen -b 4096 -t rsa -f /root/.ssh/id_rsa -P ""
#update-rc.d -f ssh remove; update-rc.d ssh enable    # Enable SSH at startup


##### Install conky
apt-get -y install conky
#--- Configure conky
file=/root/.conkyrc; if [ -e $file ]; then cp -n $file{,.bkup}; fi
echo -e '#http://forums.opensuse.org/english/get-technical-help-here/how-faq-forums/unreviewed-how-faq/464737-easy-configuring-conky-conkyconf.html\nbackground yes\n\nfont Monospace:size=8:weight=bold\nuse_xft yes\n\nupdate_interval 2.0\n\nown_window yes\nown_window_type normal\nown_window_transparent yes\nown_window_class conky-semi\nown_window_argb_visual yes  # GNOME & XFCE yes, KDE no\nown_window_colour brown\nown_window_hints undecorated,below,sticky,skip_taskbar,skip_pager\n\ndouble_buffer yes\nmaximum_width 250\n\ndraw_shades yes\ndraw_outline no\ndraw_borders no\n\nstippled_borders 3\n#border_margin 9   # Old command\nborder_inner_margin 9\nborder_width 10\n\ndefault_color grey\n\nalignment bottom_right\n#gap_x 55 # KDE\n#gap_x 0  # GNOME\ngap_x 5\ngap_y 0\n\nuppercase no\nuse_spacer right\n\nTEXT\n${color dodgerblue3}SYSTEM ${hr 2}$color\n${color white}${time %A},${time %e} ${time %B} ${time %G}${alignr}${time %H:%M:%S}\n${color white}Machine$color: $nodename ${alignr}${color white}Uptime$color: $uptime\n\n${color dodgerblue3}CPU ${hr 2}$color\n#${font Arial:bold:size=8}${execi 99999 grep "model name" -m1 /proc/cpuinfo | cut -d":" -f2 | cut -d" " -f2- | sed "s#Processor ##"}$font$color\n${color white}MHz$color: ${freq}GHz $color${color white}Load$color: ${exec uptime | awk -F "load average: " '{print $2}'}\n${color white}Tasks$color: $running_processes/$processes ${alignr}${alignr}${color white}CPU0$color: ${cpu cpu0}% ${color white}CPU1$color: ${cpu cpu1}%\n#${color #c0ff3e}${acpitemp}C\n#${execi 20 sensors |grep "Core0 Temp" | cut -d" " -f4}$font$color$alignr${freq_g 2} ${execi 20 sensors |grep "Core1 Temp" | cut -d" " -f4}\n${cpugraph cpu0 25,120 000000 white} ${cpugraph cpu1 25,120 000000 white}\n${color white}${cpubar cpu1 3,120} ${color white}${cpubar cpu2 3,120}$color\n\n${color dodgerblue3}TOP 5 PROCESSES ${hr 2}$color\n${color white}NAME                PID      CPU      MEM\n${color white}1. ${top name 1}${top pid 1}   ${top cpu 1}   ${top mem 1}$color\n2. ${top name 2}${top pid 2}   ${top cpu 2}   ${top mem 2}\n3. ${top name 3}${top pid 3}   ${top cpu 3}   ${top mem 3}\n4. ${top name 4}${top pid 4}   ${top cpu 4}   ${top mem 4}\n5. ${top name 5}${top pid 5}   ${top cpu 5}   ${top mem 5}\n\n${color dodgerblue3}MEMORY & SWAP ${hr 2}$color\n${color white}RAM$color   $memperc%  ${membar 6}$color\n${color white}Swap$color  $swapperc%  ${swapbar 6}$color\n\n${color dodgerblue3}FILESYSTEM ${hr 2}$color\n${color white}root$color ${fs_free_perc /}% free$alignr${fs_free /}/ ${fs_size /}\n${fs_bar 3 /}$color\n#${color white}home$color ${fs_free_perc /home}% free$alignr${fs_free /home}/ ${fs_size /home}\n#${fs_bar 3 /home}$color\n\n${color dodgerblue3}LAN eth0 (${addr eth0}) ${hr 2}$color\n${color white}Down$color:  ${downspeed eth0} KB/s${alignr}${color white}Up$color: ${upspeed eth0} KB/s\n${color white}Downloaded$color: ${totaldown eth0} ${alignr}${color white}Uploaded$color: ${totalup eth0}\n${downspeedgraph eth0 25,120 000000 00ff00} ${alignr}${upspeedgraph eth0 25,120 000000 ff0000}$color\n${color dodgerblue3}LAN eth1 (${addr eth1}) ${hr 2}$color\n${color white}Down$color:  ${downspeed eth1} KB/s${alignr}${color white}Up$color: ${upspeed eth1} KB/s\n${color white}Downloaded$color: ${totaldown eth1} ${alignr}${color white}Uploaded$color: ${totalup eth1}\n${downspeedgraph eth1 25,120 000000 00ff00} ${alignr}${upspeedgraph eth1 25,120 000000 ff0000}$color\n${color dodgerblue3}WiFi (${addr wlan0}) ${hr 2}$color\n${color white}Down$color:  ${downspeed wlan0} KB/s${alignr}${color white}Up$color: ${upspeed wlan0} KB/s\n${color white}Downloaded$color: ${totaldown wlan0} ${alignr}${color white}Uploaded$color: ${totalup wlan0}\n${downspeedgraph wlan0 25,120 000000 00ff00} ${alignr}${upspeedgraph wlan0 25,120 000000 ff0000}$color\n\n${color dodgerblue3}CONNECTIONS ${hr 2}$color\n${color white}Inbound: $color${tcp_portmon 1 32767 count}${color white}  ${alignc}Outbound: $color${tcp_portmon 32768 61000 count}${alignr} ${color white}ALL: $color${tcp_portmon 1 65535 count}\n${color white}Inbound Connection ${alignr} Local Service/Port$color\n$color ${tcp_portmon 1 32767 rhost 0} ${alignr} ${tcp_portmon 1 32767 lservice 0}\n$color ${tcp_portmon 1 32767 rhost 1} ${alignr} ${tcp_portmon 1 32767 lservice 1}\n$color ${tcp_portmon 1 32767 rhost 2} ${alignr} ${tcp_portmon 1 32767 lservice 2}\n${color white}Outbound Connection ${alignr} Remote Service/Port$color\n$color ${tcp_portmon 32768 61000 rhost 0} ${alignr} ${tcp_portmon 32768 61000 rservice 0}\n$color ${tcp_portmon 32768 61000 rhost 1} ${alignr} ${tcp_portmon 32768 61000 rservice 1}\n$color ${tcp_portmon 32768 61000 rhost 2} ${alignr} ${tcp_portmon 32768 61000 rservice 2}' > /root/.conkyrc
#--- Add to startup
echo -e '#!/bin/bash\nsleep 30 && conky;' > /root/.conkyscript.sh
chmod +x /root/.conkyscript.sh
mkdir -p /root/.config/autostart/
echo -e '\n[Desktop Entry]\nType=Application\nExec=/root/.conkyscript.sh\nHidden=false\nNoDisplay=false\nX-GNOME-Autostart-enabled=true\nName[en_US]=conky\nName=conky\nComment[en_US]=\nComment=' > /root/.config/autostart/conkyscript.sh.desktop


##### Install geany
apt-get -y install geany
#--- Add to panel
dconf load /org/gnome/gnome-panel/layout/objects/geany/ << EOT
[instance-config]
location='/usr/share/applications/geany.desktop'

[/]
object-iid='PanelInternalFactory::Launcher'
pack-index=3
pack-type='start'
toplevel-id='top-panel'
EOT
dconf write /org/gnome/gnome-panel/layout/object-id-list "$(dconf read /org/gnome/gnome-panel/layout/object-id-list | sed "s/]/, 'geany']/")"
#--- Configure geany
geany & sleep 5; killall -w geany   # Start and kill. Files needed for first time run
# Geany -> Edit -> Preferences. Editor -> Newline strips trailing spaces: Enable. -> Indentation -> Type: Spaces. -> Files -> Strip trailing spaces and tabs: Enable. Replace tabs by space: Enable. -> Apply -> Ok
sed -i 's/^.*indent_type.*/indent_type=0/' /root/.config/geany/geany.conf   # Spaces over tabs
sed -i 's/^.*pref_editor_newline_strip.*/pref_editor_newline_strip=true/' /root/.config/geany/geany.conf
sed -i 's/^.*pref_editor_replace_tabs.*/pref_editor_replace_tabs=true/' /root/.config/geany/geany.conf
sed -i 's/^.*pref_editor_trail_space.*/pref_editor_trail_space=true/' /root/.config/geany/geany.conf
sed -i 's/^check_detect_indent=.*/check_detect_indent=true/' /root/.config/geany/geany.conf
sed -i 's/^pref_editor_ensure_convert_line_endings=.*/pref_editor_ensure_convert_line_endings=true/' /root/.config/geany/geany.conf
# Geany -> Tools -> Plugin Manger -> Save Actions -> HTML Characters: Enabled. Split WIndows: Enabled. Save Actions: Enabled. -> Preferences -> Backup Copy -> Enable -> Directory to save backup files in: /root/backups/geany/. Directory levels to include in the backup destination: 5 -> Apply -> Ok -> Ok
sed -i 's/^.*active_plugins.*/active_plugins=\/usr\/lib\/geany\/htmlchars.so;\/usr\/lib\/geany\/saveactions.so;\/usr\/lib\/geany\/splitwindow.so;/' /root/.config/geany/geany.conf
mkdir -p /root/backups/geany/
mkdir -p /root/.config/geany/plugins/saveactions/
echo -e '\n[saveactions]\nenable_autosave=false\nenable_instantsave=false\nenable_backupcopy=true\n\n[autosave]\nprint_messages=false\nsave_all=false\ninterval=300\n\n[instantsave]\ndefault_ft=None\n\n[backupcopy]\ndir_levels=5\ntime_fmt=%Y-%m-%d-%H-%M-%S\nbackup_dir=/root/backups/geany' > /root/.config/geany/plugins/saveactions/saveactions.conf


##### Install meld
apt-get -y install meld
#--- Configure meld
gconftool-2 --type bool --set /apps/meld/show_line_numbers true
gconftool-2 --type bool --set /apps/meld/show_whitespace true
gconftool-2 --type bool --set /apps/meld/use_syntax_highlighting true
gconftool-2 --type int --set /apps/meld/edit_wrap_lines 2


##### Install libreoffice
#apt-get -y install libreoffice


##### Install recordmydesktop
#apt-get -y install gtk-recordmydesktop


##### Install shutter
apt-get -y install shutter


##### Install axel
apt-get -y install axel
#--- Setup alias
grep -q 'alias axel="axel -a"' /root/.bash_aliases || echo 'alias axel="axel -a"' >> /root/.bash_aliases
#source /root/.bashrc


##### Install gparted
apt-get -y install gparted


##### Install daemonfs
apt-get -y install daemonfs


##### Install filezilla
apt-get -y install filezilla
#--- Configure filezilla
filezilla & sleep 5; killall -w filezilla   # Start and kill. Files needed for first time run
sed -i 's/^.*"Default editor".*/\t<Setting name="Default editor" type="string">2\/usr\/bin\/geany<\/Setting>/' /root/.filezilla/filezilla.xml


##### Install tftp
apt-get -y install tftp


##### Install lynx
apt-get -y install lynx


##### Install p7zip
apt-get -y install p7zip


##### Install zip
apt-get -y install zip


##### Install pptp vpn support
apt-get -y install network-manager-pptp-gnome network-manager-pptp


##### Install flash
#apt-get -y install flashplugin-nonfree


##### Install java
# <insert bash fu here>


##### Install unicornscan ~ http://bugs.kali.org/view.php?id=388
apt-get -y install unicornscan


##### Install nessus
#--- Get download link
xdg-open http://www.tenable.com/products/nessus/select-your-operating-system    #wget "http://downloads.nessus.org/<file>" -O /tmp/nessus.deb   # ***!!! Hardcoded version value
dpkg -i /usr/local/src/Nessus-*-debian6_i386.deb
#rm -f /tmp/nessus.deb
/opt/nessus/sbin/nessus-adduser   #<--- Doesn't automate
xdg-open http://www.tenable.com/products/nessus/nessus-plugins/register-a-homefeed
#--- Check email
 /opt/nessus/bin/nessus-fetch --register <key>   #<--- Doesn't automate
service nessusd start


##### Install openvas
apt-get -y install openvas
openvas-setup   #<--- Doesn't automate
#--- Remove 'default' user (admin), and create a new admin user (root).
test -e /var/lib/openvas/users/admin && openvasad -c remove_user -n admin
test -e /var/lib/openvas/users/root || openvasad -c add_user -n root -r Admin   #<--- Doesn't automate


##### Install htshells ~ http://bugs.kali.org/view.php?id=422
git clone git://github.com/wireghoul/htshells.git /usr/share/htshells/


##### Install veil ~ http://bugs.kali.org/view.php?id=421
apt-get -y install veil


##### Install mingw
apt-get -y install mingw-w64 binutils-mingw-w64 gcc-mingw-w64 mingw-w64-dev mingw-w64-tools


##### Install OP packers
apt-get -y install upx-ucl   #wget http://upx.sourceforge.net/download/upx309w.zip -P /usr/share/packers/ && unzip -o -d /usr/share/packers/ /usr/share/packers/upx309w.zip && rm -f /usr/share/packers/upx309w.zip
mkdir -p /usr/share/packers/
wget "http://www.eskimo.com/~scottlu/win/cexe.exe" -P /usr/share/packers/
wget "http://www.farbrausch.de/~fg/kkrunchy/kkrunchy_023a2.zip" -P /usr/share/packers/ && unzip -o -d /usr/share/packers/ /usr/share/packers/kkrunchy_023a2.zip && rm -f /usr/share/packers/kkrunchy_023a2.zip
#--- Setup hyperion
unzip -o -d /usr/share/windows-binaries/ /usr/share/windows-binaries/Hyperion-1.0.zip
#rm -f /usr/share/windows-binaries/Hyperion-1.0.zip
i686-w64-mingw32-g++ -static-libgcc -static-libstdc++ /usr/share/windows-binaries/Hyperion-1.0/Src/Crypter/*.cpp -o /usr/share/windows-binaries/Hyperion-1.0/Src/Crypter/bin/crypter.exe
ln -s /usr/share/windows-binaries/Hyperion-1.0/Src/Crypter/bin/crypter.exe /usr/share/windows-binaries/Hyperion-1.0/crypter.exe


##### Update wordlists ~ http://bugs.kali.org/view.php?id=429
#--- Extract rockyou wordlist
gzip -dc < /usr/share/wordlists/rockyou.txt.gz > /usr/share/wordlists/rockyou.txt   #gunzip rockyou.txt.gz
#rm -f /usr/share/wordlists/rockyou.txt.gz
#--- Extract sqlmap wordlist
#unzip -o -d /usr/share/sqlmap/txt/ /usr/share/sqlmap/txt/wordlist.zip
#--- Add 10,000 Top/Worst/Common Passwords
wget http://xato.net/files/10k%20most%20common.zip -O /tmp/10kcommon.zip
unzip -o -d /usr/share/wordlists/ /tmp/10kcommon.zip
rm -f /tmp/10kcommon.zip
mv -f /usr/share/wordlists/10k{\ most\ ,_most_}common.txt
#--- Linking to more - folders
#ln -sf /usr/share/dirb/wordlists /usr/share/wordlists/dirb
#ln -sf /usr/share/dirbuster/wordlists /usr/share/wordlists/dirbuster
#ln -sf /usr/share/fern-wifi-cracker/extras/wordlists /usr/share/wordlists/fern-wifi
#ln -sf /usr/share/metasploit-framework/data/john/wordlists /usr/share/wordlists/metasploit-jtr
#ln -sf /usr/share/metasploit-framework/data/wordlists /usr/share/wordlists/metasploit
#ln -sf /opt/metasploit/apps/pro/data/wordlists /usr/share/wordlists/metasploit-pro
#ln -sf /usr/share/webslayer/wordlist /usr/share/wordlists/webslayer
#ln -sf /usr/share/wfuzz/wordlist /usr/share/wordlists/wfuzz
#--- Linking to more - files
#ln -sf /usr/share/sqlmap/txt/wordlist.txt /usr/share/wordlists/sqlmap.txt
#ln -sf /usr/share/dnsmap/wordlist_TLAs.txt /usr/share/wordlists/dnsmap.txt
#ln -sf /usr/share/golismero/wordlist/wfuzz/Discovery/all.txt /usr/share/wordlists/wfuzz.txt
#ln -sf /usr/share/nmap/nselib/data/passwords.lst /usr/share/wordlists/nmap.lst
#ln -sf /usr/share/set/src/fasttrack/wordlist.txt /usr/share/wordlists/fasttrack.txt
#ln -sf /usr/share/termineter/framework/data/smeter_passwords.txt /usr/share/wordlists/termineter.txt
#ln -sf /usr/share/w3af/core/controllers/bruteforce/passwords.txt /usr/share/wordlists/w3af.txt
#ln -sf /usr/share/wpscan/spec/fixtures/wpscan/modules/bruteforce/wordlist.txt /usr/share/wordlists/wpscan.txt
##ln -sf /usr/share/arachni/spec/fixtures/passwords.txt /usr/share/wordlists/arachni
##ln -sf /usr/share/cisco-auditing-tool/lists/passwords /usr/share/wordlists/cisco-auditing-tool/
##ln -sf /usr/share/wpscan/spec/fixtures/wpscan/wpscan_options/wordlist.txt /usr/share/wordlists/wpscan-options.txt
##--- Not enough? Want more? Check below!
##apt-cache search wordlist
##find / \( -iname '*wordlist*' -or -iname '*passwords*' \) #-exec ls -l {} \;


##### Configure samba
#--- Create samba user
useradd -M  -d /nonexistent -s /bin/false samba
#--- Use samba user
grep -q 'guest account =' /etc/samba/smb.conf
if [ $? -eq 0 ]; then sed -i 's/guest account = .*/guest account = samba/' /etc/samba/smb.conf; else sed -i 's/\[global\]/\[global\]\n   guest account = samba/' /etc/samba/smb.conf; fi
#--- Create samba path and configure it
mkdir -p /var/samba/
chown -R samba:samba /var/samba/
chmod -R 0770 /var/samba/
#--- Setup samba paths
grep -q '\[shared\]' /etc/samba/smb.conf || echo -e '\n[shared]\n   comment = Shared\n   path = /var/samba/\n   browseable = yes\n   read only = no\n   guest ok = yes' >> /etc/samba/smb.conf
#grep -q '\[www\]' /etc/samba/smb.conf || echo -e '\n[www]\n   comment = WWW\n   path = /var/www/\n   browseable = yes\n   read only = yes\n   guest ok = yes' >> /etc/samba/smb.conf
#--- Check result
#service samba restart
#smbclient -L \\127.0.0.1 -N
#service samba stop


##### Clean the system
#--- Clean package manager
for ITEM in clean autoremove autoclean; do apt-get -y $ITEM; done
#--- Update slocate database
updatedb
#--- Reset folder location
cd ~/
#--- Remove any history files (as they could contain sensitive info)
history -c    # Will not work in ZSH
for i in $(cut -d: -f6 /etc/passwd | sort | uniq); do
   if [[ -f $i/.*_history ]]; then rm -rf $i/.*_history; fi
done


#### Done!
reboot

# *** Don't forget to take a snapshot (if you're using a VM!) ***
