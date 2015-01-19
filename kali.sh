#!/bin/bash
#-Metadata------------------------------------------------#
#  Filename: kali.sh                 (Update: 2015-01-19) #
#-Info----------------------------------------------------#
#  Personal post install script for Kali Linux.           #
#-Author(s)-----------------------------------------------#
#  g0tmilk ~ https://blog.g0tmi1k.com                     #
#-Operating System----------------------------------------#
#  Designed for: Kali Linux 1.0.9a [x64] (VM - VMware)    #
#     Tested on: Kali Linux 1.0.0 - 1.0.9a [x64 & x84]    #
#-Notes---------------------------------------------------#
#  Run as root, after a fresh/clean install of Kali.      #
#                           ---                           #
#  It will set the time zone & keyboard to UK/GB.         #
#                           ---                           #
#  Skips making the NIC MAC & hostname random on boot.    #
#                           ---                           #
#  Incomplete stuff/buggy search for '***'.               #
#                           ---                           #
#          ** This script is meant for _ME_. **           #
#   ** Wasn't designed with customization in mind. **     #
#       ** EDIT this to meet _YOUR_ requirements! **      #
#---------------------------------------------------------#


if [ 1 -eq 0 ]; then        # This is never true, thus it acts as block comments ;)
### One liner - Grab the latest version and execute! #####################################
wget -qO- https://raw.github.com/g0tmi1k/os-scripts/master/kali.sh | bash
#curl -s -L -k https://raw.github.com/g0tmi1k/kali-postinstall/master/kali_postinstall.sh | nohup bash
###########################################################################################
fi


##### Location information
keyboardlayout="gb"         # Great Britain
keyboardApple=false         # Using a Apple/Macintosh keyboard? (anything other than 'false' will enable)
timezone="Europe/London"    # London, Europe


##### (Optional) Enable debug mode
#set -x


##### Check if we are running as root - else this script will fail (hard!)
if [[ $EUID -ne 0 ]]; then
  echo -e '\e[01;31m[!]\e[00m This script must be run as root' 1>&2
  exit 1
else
  echo -e "\e[01;34m[*]\e[00m Kali Linux post-install script" 1>&2
fi


##### Fixing display output for GUI programs when connecting via SSH
export DISPLAY=:0.0   #[[ -z $SSH_CONNECTION ]] || export DISPLAY=:0.0


##### Fixing NetworkManager issues
echo -e "\n\e[01;32m[+]\e[00m Fixing NetworkManager issues"
service network-manager stop
#--- Fix 'device not managed' issue
file=/etc/network/interfaces; [ -e $file ] && cp -n $file{,.bkup}                   # ...or: /etc/NetworkManager/NetworkManager.conf
echo "iface lo inet loopback" > $file   #sed -i '/iface lo inet loopback/q' $file   # ...or: sed -i 's/managed=.*/managed=true/' $file
#service network-manager restart
#--- Fix 'network disabled' issue
rm -f /var/lib/NetworkManager/NetworkManager.state
#--- Wait a little while before trying to connect out again (just to make sure)
service network-manager restart
sleep 10
for i in {1..60}; do ping -c 1 www.google.com &> /dev/null && break || sleep 1; done


##### Fixing default repositories ~ http://docs.kali.org/general-use/kali-linux-sources-list-repositories
echo -e "\n\e[01;32m[+]\e[00m Fixing default repositories ~ enabling network repositories (if it wasn't selected during install)"
file=/etc/apt/sources.list; [ -e $file ] && cp -n $file{,.bkup}
grep -q 'kali main non-free contrib' $file 2>/dev/null || echo "deb http://http.kali.org/kali kali main non-free contrib" >> $file
grep -q 'kali/updates main contrib non-free' $file 2>/dev/null || echo "deb http://security.kali.org/kali-security kali/updates main contrib non-free" >> $file
apt-get update


##### Installing kernel headers
echo -e "\n\e[01;32m[+]\e[00m Installing kernel headers"
apt-get -y -qq install gcc make linux-headers-$(uname -r)


##### (Optional) Checking to see if Kali is in a VM. If so, install "Virtual Machine Addons/Tools" for a "better" virtual experiment
if [ -e "/etc/vmware-tools" ]; then
  echo -e '\n\e[01;31m[!]\e[00m VMware Tools is already installed. Skipping...'
elif $(dmidecode | grep -iq vmware); then
  ##### Installing virtual machines tools ~ http://docs.kali.org/general-use/install-vmware-tools-kali-guest
  echo -e "\n\e[01;32m[+]\e[00m Installing virtual machines tools"
  #--- VM -> Install VMware Tools.    Note: you may need to apply a patch: https://github.com/offensive-security/kali-vmware-tools-patches
  mkdir -p /mnt/cdrom/
  umount -f /mnt/cdrom 2>/dev/null
  sleep 1
  mount -o ro /dev/cdrom /mnt/cdrom 2>/dev/null; _mount=$?   # Only checks first CD drive (if multiple)
  file=$(find /mnt/cdrom/ -maxdepth 1 -type f -name 'VMwareTools-*.tar.gz' -print -quit)
  if [[ $_mount == 0 ]] && [[ -z $file ]]; then
    echo -e '\e[01;31m[!]\e[00m Incorrect CD/ISO mounted. Skipping...'
  elif [[ $_mount == 0 ]]; then                         # If there is a CD in (and its right!), try to install native Guest Additions
    apt-get -y -qq install gcc make linux-headers-$(uname -r)
    # Kernel 3.14+ - so it doesn't need patching any more
    #file=/usr/sbin/update-rc.d; [ -e $file ] && cp -n $file{,.bkup}
    #grep -q '^cups enabled' $file 2>/dev/null || echo "cups enabled" >> $file
    #grep -q '^vmware-tools enabled' $file 2>/dev/null || echo "vmware-tools enabled" >> $file
    #ln -sf /usr/src/linux-headers-$(uname -r)/include/generated/uapi/linux/version.h /usr/src/linux-headers-$(uname -r)/include/linux/
    cp -f /mnt/cdrom/VMwareTools-*.tar.gz /tmp/
    tar -zxf /tmp/VMwareTools-* -C /tmp/
    cd /tmp/vmware-tools-distrib/
    echo -e '\n' | timeout 300 perl vmware-install.pl     # Press ENTER for all the default options, wait for 5 minutes to try and install else just quit
    cd - &>/dev/null
    umount -f /mnt/cdrom 2>/dev/null
  else                                             # The fallback is 'open vm tools' ~ http://open-vm-tools.sourceforge.net/about.php
    echo -e '\e[01;31m[!]\e[00m VMware Tools CD/ISO isnt mounted. Skipping "Native VMware Tools", switching to "Open VM Tools" instead'
    apt-get -y -qq install open-vm-toolbox
  fi
  #--- Slow mouse? ~ http://docs.kali.org/general-use/install-vmware-tools-kali-guest
  #apt-get -y -qq install xserver-xorg-input-vmmouse
#elif [ -e "/path/to/vbox" ]; then
#  echo -e '\n\e[01;31m[!]\e[00m Virtualbox Guest Additions is already installed. Skipping...'
elif $(dmidecode | grep -iq virtualbox); then
  ##### (Optional) Installing Virtualbox Guest Additions.   Note: Need VirtualBox 4.2.xx+ (http://docs.kali.org/general-use/kali-linux-virtual-box-guest)
  echo -e "\n\e[01;32m[+]\e[00m (Optional) Installing Virtualbox Guest Additions"
  #--- Devices -> Install Guest Additions CD image...
  mkdir -p /mnt/cdrom/
  umount -f /mnt/cdrom 2>/dev/null
  sleep 1
  mount -o ro /dev/cdrom /mnt/cdrom 2>/dev/null; _mount=$?   # Only checks first CD drive (if multiple)
  if [[ $_mount == 0 ]] && [[ -e /mnt/cdrom/VBoxLinuxAdditions.run ]]; then
    echo -e '\e[01;31m[!]\e[00m Incorrect CD/ISO mounted. Skipping...'
  elif [[ $_mount == 0 ]]; then
    apt-get -y -qq install gcc make linux-headers-$(uname -r)
    cp -f /mnt/cdrom/VBoxLinuxAdditions.run /tmp/
    chmod -f 0755 /tmp/VBoxLinuxAdditions.run
    /tmp/VBoxLinuxAdditions.run --nox11
    umount -f /mnt/cdrom 2>/dev/null
  fi
fi


##### Checking to see if there is a second ethernet card (if so, set an static IP address)
ifconfig eth1 &>/dev/null
if [[ $? == 0 ]]; then
  ##### Setting a static IP address (192.168.155.175/24) on eth1
  echo -e "\n\e[01;32m[+]\e[00m Setting a static IP address (192.168.155.175/24) on eth1"
  ifconfig eth1 192.168.155.175/24
  file=/etc/network/interfaces; [ -e $file ] && cp -n $file{,.bkup}
  grep -q '^iface eth1 inet static' $file 2>/dev/null || cat <<EOF >> $file

auto eth1
iface eth1 inet static
    address 192.168.155.175
    netmask 255.255.255.0
    gateway 192.168.155.1
EOF
fi


##### Setting static & protecting DNS name servers.   Note: May cause issues with forced values (e.g. captive portals etc)
echo -e "\n\e[01;32m[+]\e[00m Setting static & protecting DNS name servers"
file=/etc/resolv.conf; [ -e $file ] && cp -n $file{,.bkup}
chattr -i $file 2>/dev/null
#--- Remove duplicate results
#uniq $file > $file.new; mv $file{.new,}
#--- Use OpenDNS DNS
#echo -e 'nameserver 208.67.222.222\nnameserver 208.67.220.220' > $file
#--- Use Google DNS
echo -e 'nameserver 8.8.8.8\nnameserver 8.8.4.4' > $file
#--- Protect it
chattr +i $file 2>/dev/null


##### Updating hostname (to 'kali') - but not domain name
#echo -e "\n\e[01;32m[+]\e[00m Updating hostname (to 'kali')"
#hostname="kali"
##--- Change it now
#hostname "$hostname"
##--- Make sure it sticks after reboot
#file=/etc/hostname; [ -e $file ] && cp -n $file{,.bkup}
#echo "$(hostname)" > $file
##--- Set host file
#file=/etc/hosts; [ -e $file ] && cp -n $file{,.bkup}
#sed -i 's/127.0.1.1.*/127.0.1.1  '$hostname'/' $file    #echo -e "127.0.0.1  localhost.localdomain localhost\n127.0.0.1  $hostname.$domainname $hostname" > $file    #$(hostname) $domainname
##--- Check
##hostname; hostname -f


##### Updating location information - set either value to "" to skip.
echo -e "\n\e[01;32m[+]\e[00m Updating location information ~ keyboard layout & time zone ($keyboardlayout & $timezone)"
#keyboardlayout="gb"         # Great Britain
#timezone="Europe/London"    # London, Europe
#--- Configure keyboard layout
if [ ! -z "$keyboardlayout" ]; then
  file=/etc/default/keyboard; #[ -e $file ] && cp -n $file{,.bkup}
  sed -i 's/XKBLAYOUT=".*"/XKBLAYOUT="'$keyboardlayout'"/' $file
  [ "$keyboardApple" != "false" ] && sed -i 's/XKBVARIANT=".*"/XKBVARIANT="mac"/' $file   ## Enable if you are using Apple based products.
  #dpkg-reconfigure -f noninteractive keyboard-configuration   #dpkg-reconfigure console-setup   #dpkg-reconfigure keyboard-configuration -u    #need to restart xserver for effect
fi
#--- Changing time zone
[ -z "$timezone" ] && timezone=Etc/GMT
ln -sf /usr/share/zoneinfo/$timezone /etc/localtime   #ln -sf /usr/share/zoneinfo/Etc/GMT
echo $timezone > /etc/timezone   #Etc/GMT vs Etc/UTC vs UTC vs Europe/London
ln -sf /usr/share/zoneinfo/$(cat /etc/timezone) /etc/localtime
#--- Setting locale
#sed -i 's/^# en_/en_/' /etc/locale.gen   #en_GB en_US
#locale-gen
##echo -e 'LC_ALL=en_US.UTF-8\nLANG=en_US.UTF-8\nLANGUAGE=en_US:en' > /etc/default/locale
#dpkg-reconfigure -f noninteractive tzdata
##locale -a    # Check
#--- Installing ntp
apt-get -y -qq install ntp
#--- Configuring ntp
#file=/etc/default/ntp; [ -e $file ] && cp -n $file{,.bkup}
#grep -q "interface=127.0.0.1" $file || sed -i "s/NTPD_OPTS='/NTPD_OPTS='--interface=127.0.0.1 /" $file
#ntpdate -b -s -u pool.ntp.org
#--- Start service
service ntp restart
#--- Add to start up
update-rc.d ntp enable 2>/dev/null
#--- Check
#date
#--- Only used for stats at the end
start_time=$(date +%s)


##### Updating OS from repositories
echo -e "\n\e[01;32m[+]\e[00m Updating OS from repositories"
for ITEM in clean autoremove autoclean; do apt-get -y -qq $ITEM; done
export DEBIAN_FRONTEND=noninteractive
apt-get update && apt-get -y -qq dist-upgrade --fix-missing
#--- Enable bleeding edge ~ http://www.kali.org/kali-monday/bleeding-edge-kali-repositories/
#file=/etc/apt/sources.list; [ -e $file ] && cp -n $file{,.bkup}
#grep -q 'kali-bleeding-edge' $file 2>/dev/null || echo -e "\n\n## Bleeding edge\ndeb http://repo.kali.org/kali kali-bleeding-edge main" >> $file
#apt-get update && apt-get -y -qq upgrade


##### Settings services to listen to listen to loopback interface
#echo -e "\n\e[01;32m[+]\e[00m Settings services to listen to listen to loopback interface"
#--- Configuring ntp
#file=/etc/default/ntp; [ -e $file ] && cp -n $file{,.bkup}
#grep -q "interface=127.0.0.1" $file || sed -i "s/^NTPD_OPTS='/NTPD_OPTS='--interface=127.0.0.1 /" $file
#service ntp restart
#--- Configuring rpcbind
#file=/etc/default/rpcbind; [ -e $file ] && cp -n $file{,.bkup}
#if [ -e $file ]; then grep -q "127.0.0.1" $file || sed -i 's/OPTIONS="/OPTIONS="-h 127.0.0.1 /' $file; else echo 'OPTIONS="-w -h 127.0.0.1"' > $file; fi
#service ntp rpcbind
#--- Configuring nfs
#file=/etc/default/rpcbind; [ -e $file ] && cp -n $file{,.bkup}
#grep -q "--name 127.0.0.1" $file || sed -i 's/^STATDOPTS=/STATDOPTS="--name 127.0.0.1"/' $file
#service nfs-common restart


##### Fixing audio issues
echo -e "\n\e[01;32m[+]\e[00m Fixing audio issues"
#--- PulseAudio warnings
#file=/etc/default/pulseaudio; [ -e $file ] && cp -n $file{,.bkup}
#sed -i 's/^PULSEAUDIO_SYSTEM_START=.*/PULSEAUDIO_SYSTEM_START=1/' $file
#--- Unmute on startup
apt-get -y -qq install alsa-utils
#--- Set volume now
amixer set Master unmute >/dev/null
amixer set Master 50% >/dev/null


##### Configuring GRUB
echo -e "\n\e[01;32m[+]\e[00m Configuring GRUB ~ boot manager"
(dmidecode | grep -iq virtual) && grubTimeout=1 || timeout=5
file=/etc/default/grub; [ -e $file ] && cp -n $file{,.bkup}
sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT='$grubTimeout'/' $file                   # Time out (lower if in a virtual machine, else possible dual booting)
sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT=""/' $file   # TTY resolution    #GRUB_CMDLINE_LINUX_DEFAULT="vga=0x0318 quiet"   (crashes VM/vmwgfx)
update-grub


##### Disabling login manager (console login - non GUI)
#echo -e "\n\e[01;32m[+]\e[00m Disabling login (console login - non GUI)"
#--- Disable GUI login screen
#apt-get -y -qq install chkconfig
#chkconfig gdm3 off                                 # ...or: mv -f /etc/rc2.d/S19gdm3 /etc/rc2.d/K17gdm           #file=/etc/X11/default-display-manager; [ -e $file ] && cp -n $file{,.bkup}   #echo /bin/true > $file
#--- Enable auto (gui) login
#file=/etc/gdm3/daemon.conf; [ -e $file ] && cp -n $file{,.bkup}
#sed -i 's/^.*AutomaticLoginEnable = .*/AutomaticLoginEnable = true/' $file
#sed -i 's/^.*AutomaticLogin = .*/AutomaticLogin = root/' $file
#--- Shortcut for when you want to start GUI
#ln -sf /usr/sbin/gdm3 /usr/bin/startx


##### Configuring startup (randomize the hostname, eth0 & wlan0s MAC address)
#echo -e "\n\e[01;32m[+]\e[00m Configuring startup (randomize the hostname, eth0 & wlan0s MAC address)"
#--- Start up
#file=/etc/rc.local; [ -e $file ] && cp -n $file{,.bkup}
#grep -q "macchanger" $file 2>/dev/null || sed -i 's#^exit 0#for INT in eth0 wlan0; do\n  ifconfig $INT down\n  '$(whereis macchanger)' -r $INT \&\& sleep 3\n  ifconfig $INT up\ndone\n\n\nexit 0#' $file
#grep -q "hostname" $file 2>/dev/null || sed -i 's#^exit 0#'$(whereis hostname)' $(cat /dev/urandom | tr -dc "A-Za-z" | head -c8)\nexit 0#' $file
#--- On demand (*** kinda broken)
##file=/etc/init.d/macchanger; [ -e $file ] && cp -n $file{,.bkup}
##echo -e '#!/bin/bash\nfor INT in eth0 wlan0; do\n  echo "Randomizing: $INT"\n  ifconfig $INT down\n  macchanger -r $INT\n  sleep 3\n  ifconfig $INT up\n  echo "--------------------"\ndone\nexit 0' > $file
##chmod -f 0500 $file
#--- Auto on interface change state (untested)
##file=/etc/network/if-pre-up.d/macchanger; [ -e $file ] && cp -n $file{,.bkup}
##echo -e '#!/bin/bash\n[ "$IFACE" == "lo" ] && exit 0\nifconfig $IFACE down\nmacchanger -r $IFACE\nifconfig $IFACE up\nexit 0' > $file
##chmod -f 0500 $file


##### Configuring GNOME 3
echo -e "\n\e[01;32m[+]\e[00m Configuring GNOME 3 ~ desktop environment"
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
#--- Enable auto hide
#dconf write /org/gnome/gnome-panel/layout/toplevels/top-panel/auto-hide true
#--- Add top 10 tools to toolbar
dconf load /org/gnome/gnome-panel/layout/objects/object-10-top/ << EOF
[instance-config]
menu-path='applications:/Kali/Top 10 Security Tools/'
tooltip='Top 10 Security Tools'

[/]
object-iid='PanelInternalFactory::MenuButton'
toplevel-id='top-panel'
pack-type='start'
pack-index=4
EOF
dconf write /org/gnome/gnome-panel/layout/object-id-list "$(dconf read /org/gnome/gnome-panel/layout/object-id-list | sed "s/]/, 'object-10-top']/")"
#--- Show desktop
dconf load /org/gnome/gnome-panel/layout/objects/object-show-desktop/ << EOF
[/]
object-iid='WnckletFactory::ShowDesktopApplet'
toplevel-id='top-panel'
pack-type='end'
pack-index=0
EOF
dconf write /org/gnome/gnome-panel/layout/object-id-list "$(dconf read /org/gnome/gnome-panel/layout/object-id-list | sed "s/]/, 'object-show-desktop']/")"
#--- Fix icon top 10 shortcut icon
#convert /usr/share/icons/hicolor/48x48/apps/k.png -negate /usr/share/icons/hicolor/48x48/apps/k-invert.png
#/usr/share/icons/gnome/48x48/status/security-medium.png
#--- Enable only two workspaces
gsettings set org.gnome.desktop.wm.preferences num-workspaces 2   #gconftool-2 --type int --set /apps/metacity/general/num_workspaces 2 #dconf write /org/gnome/gnome-panel/layout/objects/workspace-switcher/instance-config/num-rows 4
gsettings set org.gnome.shell.overrides dynamic-workspaces false
#--- Smaller title bar
#sed -i '/title_vertical_pad/s/value="[0-9]\{1,2\}"/value="0"/g' /usr/share/themes/Adwaita/metacity-1/metacity-theme-3.xml
#sed -i 's/title_scale=".*"/title_scale="small"/g' /usr/share/themes/Adwaita/metacity-1/metacity-theme-3.xml
gsettings set org.gnome.desktop.wm.preferences titlebar-font 'Droid Bold 10'   # 'Cantarell Bold 11'
gsettings set org.gnome.desktop.wm.preferences titlebar-uses-system-font false
#--- Hide desktop icon
dconf write /org/gnome/nautilus/desktop/computer-icon-visible false
#--- Add "open with terminal" on right click menu
apt-get -y -qq install nautilus-open-terminal
#--- Enable num lock at start up (might not be smart if you're using a smaller keyboard (laptop?))
apt-get -y -qq install numlockx
file=/etc/gdm3/Init/Default; [ -e $file ] && cp -n $file{,.bkup}     #/etc/rc.local
grep -q '^/usr/bin/numlockx' $file 2>/dev/null || sed -i 's#exit 0#if [ -x /usr/bin/numlockx ]; then\n /usr/bin/numlockx on\nfi\nexit 0#' $file   # GNOME
#--- Change wallpaper & login (happens later)
#wget -q "http://www.kali.org/images/wallpapers-01/kali-wp-june-2014_1920x1080_A.png" -P /usr/share/wallpapers/
#gsettings set org.gnome.desktop.background picture-uri 'file:///usr/share/wallpapers/kali-wp-june-2014_1920x1080_A.png'
#cp -f /usr/share/wallpapers/kali-wp-june-2014_1920x1080_A.png /usr/share/images/desktop-base/login-background.png
#--- Restart GNOME panel to apply/take effect (need to restart xserver for effect)
#timeout 30 killall -q -w gnome-panel >/dev/null && gnome-panel&   # Still need to logoff!


##### Installing & configuring XFCE 4
echo -e "\n\e[01;32m[+]\e[00m Installing & configuring XFCE 4 ~ desktop environment"
apt-get -y -qq install wget
apt-get -y -qq install xfce4 xfce4-places-plugin
#apt-get -y -qq install shiki-colors-xfwm-theme    # theme
#--- Configuring xfce 4
mv -f /usr/bin/startx{,-gnome}
ln -sf /usr/bin/startx{fce4,}
mkdir -p /root/.config/xfce4/{desktop,menu,panel,xfconf,xfwm4}/
mkdir -p /root/.config/xfce4/panel/launcher-1{5,6,7,9}
mkdir -p /root/.config/xfce4/xfconf/xfce-perchannel-xml/
mkdir -p /root/.themes/
cat <<EOF > /root/.config/xfce4/desktop/icons.screen0.rc
[Wastebasket]
row=2
col=0

[File System]
row=1
col=0

[Home]
row=0
col=0
EOF
cat <<EOF > /root/.config/xfce4/panel/places-23.rc
show_button_icon=true
show_button_label=false
label=Places
show_icons=true
show_volumes=true
mount_open_volumes=false
show_bookmarks=true
show_recent=true
show_recent_clear=true
show_recent_number=10
search_cmd=
EOF
cat <<EOF > /root/.config/xfce4/panel/xfce4-mixer-plugin-24.rc
card=PlaybackES1371AudioPCI97AnalogStereoPulseAudioMixer
track=Master
command=xfce4-mixer
EOF
cat <<EOF > /root/.config/xfce4/panel/launcher-15/13684522587.desktop
[Desktop Entry]
Encoding=UTF-8
Name=Iceweasel
Comment=Browse the World Wide Web
GenericName=Web Browser
X-GNOME-FullName=Iceweasel Web Browser
Exec=iceweasel %u
Terminal=false
X-MultipleArgs=false
Type=Application
Icon=iceweasel
Categories=Network;WebBrowser;
MimeType=text/html;text/xml;application/xhtml+xml;application/xml;application/vnd.mozilla.xul+xml;application/rss+xml;application/rdf+xml;image/gif;image/jpeg;image/png;x-scheme-handler/http;x-scheme-handler/https;
StartupWMClass=Iceweasel
StartupNotify=true
X-XFCE-Source=file:///usr/share/applications/iceweasel.desktop
EOF
cat <<EOF > /root/.config/xfce4/panel/launcher-16/13684522758.desktop
[Desktop Entry]
Version=1.0
Type=Application
Exec=exo-open --launch TerminalEmulator
Icon=utilities-terminal
StartupNotify=false
Terminal=false
Categories=Utility;X-XFCE;X-Xfce-Toplevel;
OnlyShowIn=XFCE;
Name=Terminal Emulator
Name[en_GB]=Terminal Emulator
Comment=Use the command line
Comment[en_GB]=Use the command line
X-XFCE-Source=file:///usr/share/applications/exo-terminal-emulator.desktop
EOF
cat <<EOF > /root/.config/xfce4/panel/launcher-17/13684522859.desktop
[Desktop Entry]
Type=Application
Version=1.0
Name=Geany
Name[en_GB]=Geany
GenericName=Integrated Development Environment
GenericName[en_GB]=Integrated Development Environment
Comment=A fast and lightweight IDE using GTK2
Comment[en_GB]=A fast and lightweight IDE using GTK2
Exec=geany %F
Icon=geany
Terminal=false
Categories=GTK;Development;IDE;
MimeType=text/plain;text/x-chdr;text/x-csrc;text/x-c++hdr;text/x-c++src;text/x-java;text/x-dsrc;text/x-pascal;text/x-perl;text/x-python;application/x-php;application/x-httpd-php3;application/x-httpd-php4;application/x-httpd-php5;application/xml;text/html;text/css;text/x-sql;text/x-diff;
StartupNotify=true
X-XFCE-Source=file:///usr/share/applications/geany.desktop
EOF
cat <<EOF > /root/.config/xfce4/panel/launcher-19/136845425410.desktop
[Desktop Entry]
Version=1.0
Name=Application Finder
Name[en_GB]=Application Finder
Comment=Find and launch applications installed on your system
Comment[en_GB]=Find and launch applications installed on your system
Exec=xfce4-appfinder
Icon=xfce4-appfinder
StartupNotify=true
Terminal=false
Type=Application
Categories=X-XFCE;Utility;
X-XFCE-Source=file:///usr/share/applications/xfce4-appfinder.desktop
EOF
cat <<EOF > /root/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-appfinder.xml
<?xml version="1.0" encoding="UTF-8"?>

<channel name="xfce4-appfinder" version="1.0">
  <property name="category" type="string" value="All"/>
  <property name="window-width" type="int" value="640"/>
  <property name="window-height" type="int" value="480"/>
  <property name="close-after-execute" type="bool" value="true"/>
</channel>
EOF
cat <<EOF > /root/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml
<?xml version="1.0" encoding="UTF-8"?>

<channel name="xfce4-desktop" version="1.0">
  <property name="desktop-icons" type="empty">
    <property name="file-icons" type="empty">
      <property name="show-removable" type="bool" value="true"/>
      <property name="show-trash" type="bool" value="false"/>
      <property name="show-filesystem" type="bool" value="false"/>
      <property name="show-home" type="bool" value="false"/>
    </property>
  </property>
</channel>
EOF
cat <<EOF > /root/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml
<?xml version="1.0" encoding="UTF-8"?>

<channel name="xfce4-keyboard-shortcuts" version="1.0">
  <property name="commands" type="empty">
    <property name="custom" type="empty">
      <property name="XF86Display" type="string" value="xfce4-display-settings --minimal"/>
      <property name="&lt;Alt&gt;F2" type="string" value="xfrun4"/>
      <property name="&lt;Primary&gt;&lt;Alt&gt;t" type="string" value="/usr/bin/exo-open --launch TerminalEmulator"/>
      <property name="&lt;Primary&gt;&lt;Alt&gt;Delete" type="string" value="xflock4"/>
      <property name="&lt;Primary&gt;Escape" type="string" value="xfdesktop --menu"/>
      <property name="&lt;Super&gt;p" type="string" value="xfce4-display-settings --minimal"/>
      <property name="override" type="bool" value="true"/>
      <property name="&lt;Primary&gt;space" type="string" value="xfce4-appfinder"/>
    </property>
  </property>
  <property name="xfwm4" type="empty">
    <property name="custom" type="empty">
      <property name="&lt;Alt&gt;&lt;Control&gt;End" type="string" value="move_window_next_workspace_key"/>
      <property name="&lt;Alt&gt;&lt;Control&gt;Home" type="string" value="move_window_prev_workspace_key"/>
      <property name="&lt;Alt&gt;&lt;Control&gt;KP_1" type="string" value="move_window_workspace_1_key"/>
      <property name="&lt;Alt&gt;&lt;Control&gt;KP_2" type="string" value="move_window_workspace_2_key"/>
      <property name="&lt;Alt&gt;&lt;Control&gt;KP_3" type="string" value="move_window_workspace_3_key"/>
      <property name="&lt;Alt&gt;&lt;Control&gt;KP_4" type="string" value="move_window_workspace_4_key"/>
      <property name="&lt;Alt&gt;&lt;Control&gt;KP_5" type="string" value="move_window_workspace_5_key"/>
      <property name="&lt;Alt&gt;&lt;Control&gt;KP_6" type="string" value="move_window_workspace_6_key"/>
      <property name="&lt;Alt&gt;&lt;Control&gt;KP_7" type="string" value="move_window_workspace_7_key"/>
      <property name="&lt;Alt&gt;&lt;Control&gt;KP_8" type="string" value="move_window_workspace_8_key"/>
      <property name="&lt;Alt&gt;&lt;Control&gt;KP_9" type="string" value="move_window_workspace_9_key"/>
      <property name="&lt;Alt&gt;&lt;Shift&gt;Tab" type="string" value="cycle_reverse_windows_key"/>
      <property name="&lt;Alt&gt;Delete" type="string" value="del_workspace_key"/>
      <property name="&lt;Alt&gt;F10" type="string" value="maximize_window_key"/>
      <property name="&lt;Alt&gt;F11" type="string" value="fullscreen_key"/>
      <property name="&lt;Alt&gt;F12" type="string" value="above_key"/>
      <property name="&lt;Alt&gt;F4" type="string" value="close_window_key"/>
      <property name="&lt;Alt&gt;F6" type="string" value="stick_window_key"/>
      <property name="&lt;Alt&gt;F7" type="string" value="move_window_key"/>
      <property name="&lt;Alt&gt;F8" type="string" value="resize_window_key"/>
      <property name="&lt;Alt&gt;F9" type="string" value="hide_window_key"/>
      <property name="&lt;Alt&gt;Insert" type="string" value="add_workspace_key"/>
      <property name="&lt;Alt&gt;space" type="string" value="popup_menu_key"/>
      <property name="&lt;Alt&gt;Tab" type="string" value="cycle_windows_key"/>
      <property name="&lt;Control&gt;&lt;Alt&gt;d" type="string" value="show_desktop_key"/>
      <property name="&lt;Control&gt;&lt;Alt&gt;Down" type="string" value="down_workspace_key"/>
      <property name="&lt;Control&gt;&lt;Alt&gt;Left" type="string" value="left_workspace_key"/>
      <property name="&lt;Control&gt;&lt;Alt&gt;Right" type="string" value="right_workspace_key"/>
      <property name="&lt;Control&gt;&lt;Alt&gt;Up" type="string" value="up_workspace_key"/>
      <property name="&lt;Control&gt;&lt;Shift&gt;&lt;Alt&gt;Left" type="string" value="move_window_left_key"/>
      <property name="&lt;Control&gt;&lt;Shift&gt;&lt;Alt&gt;Right" type="string" value="move_window_right_key"/>
      <property name="&lt;Control&gt;&lt;Shift&gt;&lt;Alt&gt;Up" type="string" value="move_window_up_key"/>
      <property name="&lt;Control&gt;F1" type="string" value="workspace_1_key"/>
      <property name="&lt;Control&gt;F10" type="string" value="workspace_10_key"/>
      <property name="&lt;Control&gt;F11" type="string" value="workspace_11_key"/>
      <property name="&lt;Control&gt;F12" type="string" value="workspace_12_key"/>
      <property name="&lt;Control&gt;F2" type="string" value="workspace_2_key"/>
      <property name="&lt;Control&gt;F3" type="string" value="workspace_3_key"/>
      <property name="&lt;Control&gt;F4" type="string" value="workspace_4_key"/>
      <property name="&lt;Control&gt;F5" type="string" value="workspace_5_key"/>
      <property name="&lt;Control&gt;F6" type="string" value="workspace_6_key"/>
      <property name="&lt;Control&gt;F7" type="string" value="workspace_7_key"/>
      <property name="&lt;Control&gt;F8" type="string" value="workspace_8_key"/>
      <property name="&lt;Control&gt;F9" type="string" value="workspace_9_key"/>
      <property name="&lt;Shift&gt;&lt;Alt&gt;Page_Down" type="string" value="lower_window_key"/>
      <property name="&lt;Shift&gt;&lt;Alt&gt;Page_Up" type="string" value="raise_window_key"/>
      <property name="&lt;Super&gt;Tab" type="string" value="switch_window_key"/>
      <property name="Down" type="string" value="down_key"/>
      <property name="Escape" type="string" value="cancel_key"/>
      <property name="Left" type="string" value="left_key"/>
      <property name="Right" type="string" value="right_key"/>
      <property name="Up" type="string" value="up_key"/>
      <property name="override" type="bool" value="true"/>
    </property>
  </property>
  <property name="providers" type="array">
    <value type="string" value="xfwm4"/>
    <value type="string" value="commands"/>
  </property>
</channel>
EOF
cat <<EOF > /root/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-mixer.xml
<?xml version="1.0" encoding="UTF-8"?>

<channel name="xfce4-mixer" version="1.0">
  <property name="active-card" type="string" value="PlaybackES1371AudioPCI97AnalogStereoPulseAudioMixer"/>
  <property name="volume-step-size" type="uint" value="5"/>
  <property name="sound-card" type="string" value="PlaybackES1371AudioPCI97AnalogStereoPulseAudioMixer"/>
  <property name="sound-cards" type="empty">
    <property name="PlaybackES1371AudioPCI97AnalogStereoPulseAudioMixer" type="array">
      <value type="string" value="Master"/>
    </property>
  </property>
  <property name="window-height" type="int" value="400"/>
  <property name="window-width" type="int" value="738"/>
</channel>
EOF
cat <<EOF > /root/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml
<?xml version="1.0" encoding="UTF-8"?>

<channel name="xfce4-panel" version="1.0">
  <property name="panels" type="uint" value="1">
    <property name="panel-0" type="empty">
      <property name="position" type="string" value="p=6;x=0;y=0"/>
      <property name="length" type="uint" value="100"/>
      <property name="position-locked" type="bool" value="true"/>
      <property name="plugin-ids" type="array">
        <value type="int" value="1"/>
        <value type="int" value="15"/>
        <value type="int" value="16"/>
        <value type="int" value="17"/>
        <value type="int" value="21"/>
        <value type="int" value="23"/>
        <value type="int" value="19"/>
        <value type="int" value="3"/>
        <value type="int" value="24"/>
        <value type="int" value="6"/>
        <value type="int" value="2"/>
        <value type="int" value="5"/>
        <value type="int" value="4"/>
        <value type="int" value="25"/>
      </property>
      <property name="background-alpha" type="uint" value="90"/>
    </property>
  </property>
  <property name="plugins" type="empty">
    <property name="plugin-1" type="string" value="applicationsmenu">
      <property name="button-icon" type="string" value="kali-menu"/>
      <property name="show-button-title" type="bool" value="false"/>
      <property name="show-generic-names" type="bool" value="true"/>
      <property name="show-tooltips" type="bool" value="true"/>
    </property>
    <property name="plugin-2" type="string" value="actions"/>
    <property name="plugin-3" type="string" value="tasklist"/>
    <property name="plugin-4" type="string" value="pager">
      <property name="rows" type="uint" value="1"/>
    </property>
    <property name="plugin-5" type="string" value="clock">
      <property name="digital-format" type="string" value="%R, %A %d %B %Y"/>
    </property>
    <property name="plugin-6" type="string" value="systray">
      <property name="names-visible" type="array">
        <value type="string" value="networkmanager applet"/>
      </property>
    </property>
    <property name="plugin-15" type="string" value="launcher">
      <property name="items" type="array">
        <value type="string" value="13684522587.desktop"/>
      </property>
    </property>
    <property name="plugin-16" type="string" value="launcher">
      <property name="items" type="array">
        <value type="string" value="13684522758.desktop"/>
      </property>
    </property>
    <property name="plugin-17" type="string" value="launcher">
      <property name="items" type="array">
        <value type="string" value="13684522859.desktop"/>
      </property>
    </property>
    <property name="plugin-21" type="string" value="applicationsmenu">
      <property name="custom-menu" type="bool" value="true"/>
      <property name="custom-menu-file" type="string" value="/root/.config/xfce4/menu/top10.menu"/>
      <property name="button-icon" type="string" value="security-medium"/>
      <property name="show-button-title" type="bool" value="false"/>
      <property name="button-title" type="string" value="Top 10"/>
    </property>
    <property name="plugin-19" type="string" value="launcher">
      <property name="items" type="array">
        <value type="string" value="136845425410.desktop"/>
      </property>
    </property>
    <property name="plugin-22" type="empty">
      <property name="base-directory" type="string" value="/root"/>
      <property name="hidden-files" type="bool" value="false"/>
    </property>
    <property name="plugin-23" type="string" value="places"/>
    <property name="plugin-24" type="string" value="xfce4-mixer-plugin"/>
    <property name="plugin-25" type="string" value="showdesktop"/>
  </property>
</channel>
EOF
cat <<EOF > /root/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-settings-editor.xml
<?xml version="1.0" encoding="UTF-8"?>

<channel name="xfce4-settings-editor" version="1.0">
  <property name="window-width" type="int" value="600"/>
  <property name="window-height" type="int" value="380"/>
  <property name="hpaned-position" type="int" value="200"/>
</channel>
EOF
cat <<EOF > /root/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml
<?xml version="1.0" encoding="UTF-8"?>

<channel name="xfwm4" version="1.0">
  <property name="general" type="empty">
    <property name="activate_action" type="string" value="bring"/>
    <property name="borderless_maximize" type="bool" value="true"/>
    <property name="box_move" type="bool" value="false"/>
    <property name="box_resize" type="bool" value="false"/>
    <property name="button_layout" type="string" value="O|SHMC"/>
    <property name="button_offset" type="int" value="0"/>
    <property name="button_spacing" type="int" value="0"/>
    <property name="click_to_focus" type="bool" value="true"/>
    <property name="focus_delay" type="int" value="250"/>
    <property name="cycle_apps_only" type="bool" value="false"/>
    <property name="cycle_draw_frame" type="bool" value="true"/>
    <property name="cycle_hidden" type="bool" value="true"/>
    <property name="cycle_minimum" type="bool" value="true"/>
    <property name="cycle_workspaces" type="bool" value="false"/>
    <property name="double_click_time" type="int" value="250"/>
    <property name="double_click_distance" type="int" value="5"/>
    <property name="double_click_action" type="string" value="maximize"/>
    <property name="easy_click" type="string" value="Alt"/>
    <property name="focus_hint" type="bool" value="true"/>
    <property name="focus_new" type="bool" value="true"/>
    <property name="frame_opacity" type="int" value="100"/>
    <property name="full_width_title" type="bool" value="true"/>
    <property name="inactive_opacity" type="int" value="100"/>
    <property name="maximized_offset" type="int" value="0"/>
    <property name="move_opacity" type="int" value="100"/>
    <property name="placement_ratio" type="int" value="20"/>
    <property name="placement_mode" type="string" value="center"/>
    <property name="popup_opacity" type="int" value="100"/>
    <property name="mousewheel_rollup" type="bool" value="true"/>
    <property name="prevent_focus_stealing" type="bool" value="false"/>
    <property name="raise_delay" type="int" value="250"/>
    <property name="raise_on_click" type="bool" value="true"/>
    <property name="raise_on_focus" type="bool" value="false"/>
    <property name="raise_with_any_button" type="bool" value="true"/>
    <property name="repeat_urgent_blink" type="bool" value="false"/>
    <property name="resize_opacity" type="int" value="100"/>
    <property name="restore_on_move" type="bool" value="true"/>
    <property name="scroll_workspaces" type="bool" value="true"/>
    <property name="shadow_delta_height" type="int" value="0"/>
    <property name="shadow_delta_width" type="int" value="0"/>
    <property name="shadow_delta_x" type="int" value="0"/>
    <property name="shadow_delta_y" type="int" value="-3"/>
    <property name="shadow_opacity" type="int" value="50"/>
    <property name="show_app_icon" type="bool" value="false"/>
    <property name="show_dock_shadow" type="bool" value="true"/>
    <property name="show_frame_shadow" type="bool" value="false"/>
    <property name="show_popup_shadow" type="bool" value="false"/>
    <property name="snap_resist" type="bool" value="false"/>
    <property name="snap_to_border" type="bool" value="true"/>
    <property name="snap_to_windows" type="bool" value="false"/>
    <property name="snap_width" type="int" value="10"/>
    <property name="theme" type="string" value="Shiki-Colors-Light-Menus"/>
    <property name="title_alignment" type="string" value="center"/>
    <property name="title_font" type="string" value="Sans Bold 9"/>
    <property name="title_horizontal_offset" type="int" value="0"/>
    <property name="title_shadow_active" type="string" value="false"/>
    <property name="title_shadow_inactive" type="string" value="false"/>
    <property name="title_vertical_offset_active" type="int" value="0"/>
    <property name="title_vertical_offset_inactive" type="int" value="0"/>
    <property name="toggle_workspaces" type="bool" value="false"/>
    <property name="unredirect_overlays" type="bool" value="true"/>
    <property name="urgent_blink" type="bool" value="false"/>
    <property name="use_compositing" type="bool" value="true"/>
    <property name="workspace_count" type="int" value="2"/>
    <property name="wrap_cycle" type="bool" value="true"/>
    <property name="wrap_layout" type="bool" value="true"/>
    <property name="wrap_resistance" type="int" value="10"/>
    <property name="wrap_windows" type="bool" value="true"/>
    <property name="wrap_workspaces" type="bool" value="false"/>
    <property name="workspace_names" type="array">
      <value type="string" value="Workspace 1"/>
      <value type="string" value="Workspace 2"/>
      <value type="string" value="Workspace 3"/>
      <value type="string" value="Workspace 4"/>
    </property>
  </property>
</channel>
EOF
cat <<EOF > /root/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml
<?xml version="1.0" encoding="UTF-8"?>

<channel name="xsettings" version="1.0">
  <property name="Net" type="empty">
    <property name="ThemeName" type="empty"/>
    <property name="IconThemeName" type="empty"/>
    <property name="DoubleClickTime" type="int" value="250"/>
    <property name="DoubleClickDistance" type="int" value="5"/>
    <property name="DndDragThreshold" type="int" value="8"/>
    <property name="CursorBlink" type="bool" value="true"/>
    <property name="CursorBlinkTime" type="int" value="1200"/>
    <property name="SoundThemeName" type="string" value="default"/>
    <property name="EnableEventSounds" type="bool" value="false"/>
    <property name="EnableInputFeedbackSounds" type="bool" value="false"/>
  </property>
  <property name="Xft" type="empty">
    <property name="DPI" type="empty"/>
    <property name="Antialias" type="int" value="-1"/>
    <property name="Hinting" type="int" value="-1"/>
    <property name="HintStyle" type="string" value="hintnone"/>
    <property name="RGBA" type="string" value="none"/>
  </property>
  <property name="Gtk" type="empty">
    <property name="CanChangeAccels" type="bool" value="false"/>
    <property name="ColorPalette" type="string" value="black:white:gray50:red:purple:blue:light blue:green:yellow:orange:lavender:brown:goldenrod4:dodger blue:pink:light green:gray10:gray30:gray75:gray90"/>
    <property name="FontName" type="string" value="Sans 10"/>
    <property name="IconSizes" type="string" value=""/>
    <property name="KeyThemeName" type="string" value=""/>
    <property name="ToolbarStyle" type="string" value="icons"/>
    <property name="ToolbarIconSize" type="int" value="3"/>
    <property name="IMPreeditStyle" type="string" value=""/>
    <property name="IMStatusStyle" type="string" value=""/>
    <property name="MenuImages" type="bool" value="true"/>
    <property name="ButtonImages" type="bool" value="true"/>
    <property name="MenuBarAccel" type="string" value="F10"/>
    <property name="CursorThemeName" type="string" value=""/>
    <property name="CursorThemeSize" type="int" value="0"/>
    <property name="IMModule" type="string" value=""/>
  </property>
</channel>
EOF
cat <<EOF > /root/.config/xfce4/menu/top10.menu
<Menu>
  <Name>Top 10</Name>
  <DefaultAppDirs/>
  <Directory>top10.directory</Directory>
  <Include>
    <Category>top10</Category>
  </Include>
</Menu>
EOF
#--- Get shiki-colors-light theme
wget -q "http://xfce-look.org/CONTENT/content-files/142110-Shiki-Colors-Light-Menus.tar.gz" -O /tmp/Shiki-Colors-Light-Menus.tar.gz
tar zxf /tmp/Shiki-Colors-Light-Menus.tar.gz -C /root/.themes/
xfconf-query -c xsettings -p /Net/ThemeName -s "Shiki-Colors-Light-Menus"
xfconf-query -c xsettings -p /Net/IconThemeName -s "gnome-brave"
#--- Enable compositing
xfconf-query -c xfwm4 -p /general/use_compositing -s true
#--- Fix gnome keyring issue
file=/etc/xdg/autostart/gnome-keyring-pkcs11.desktop;   #[ -e $file ] && cp -n $file{,.bkup}
grep -q XFCE $file || sed 's/^OnlyShowIn=*/OnlyShowIn=XFCE;/' $file | grep OnlyShowIn
#--- Disable user folders
apt-get -y -qq install xdg-user-dirs
xdg-user-dirs-update
file=/etc/xdg/user-dirs.conf; [ -e $file ] && cp -n $file{,.bkup}
sed -i 's/^enable=.*/enable=False/' $file   #sed -i 's/^XDG_/#XDG_/; s/^#XDG_DESKTOP/XDG_DESKTOP/;' /root/.config/user-dirs.dirs
rm -rf /root/{Documents,Music,Pictures,Public,Templates,Videos}/
xdg-user-dirs-update
#--- Get new desktop wallpaper
wget -q "http://www.kali.org/images/wallpapers-01/kali-wp-june-2014_1920x1080_A.png" -O /usr/share/wallpapers/kali_blue_3d_a.png
wget -q "http://www.kali.org/images/wallpapers-01/kali-wp-june-2014_1920x1080_B.png" -O /usr/share/wallpapers/kali_blue_3d_b.png
wget -q "http://www.kali.org/images/wallpapers-01/kali-wp-june-2014_1920x1080_G.png" -O /usr/share/wallpapers/kali_black_honeycomb.png
wget -q "http://imageshack.us/a/img17/4646/vzex.png" -O /usr/share/wallpapers/kali_blue_splat.png
wget -q "http://www.n1tr0g3n.com/wp-content/uploads/2013/03/Kali-Linux-faded-no-Dragon-small-text.png" -O /usr/share/wallpapers/kali_black_clean.png
wget -q "http://1hdwallpapers.com/wallpapers/kali_linux.jpg" -O /usr/share/wallpapers/kali_black_stripes.jpg
#--- Change desktop wallpaper (single random pick - on each install).   Note: For now...
wallpaper=$(shuf -n1 -e /usr/share/wallpapers/kali_*)   #wallpaper=/usr/share/wallpapers/kali_blue_splat.png
xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/image-show -s true
xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/image-path -s $wallpaper
#--- Change login wallpaper
cp -f $wallpaper /usr/share/images/desktop-base/login-background.png
#--- Reload XFCE
#/usr/bin/xfdesktop --reload
#--- New wallpaper - add to startup (random each login)
file=/usr/local/bin/wallpaper.sh; [ -e $file ] && cp -n $file{,.bkup}
cat <<EOF > $file
#!/bin/bash

wallpaper=$(shuf -n1 -e /usr/share/wallpapers/kali_*)
xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/image-path -s $wallpaper
cp -f $wallpaper /usr/share/images/desktop-base/login-background.png
/usr/bin/xfdesktop --reload
EOF
chmod -f 0500 $file
mkdir -p /root/.config/autostart/
file=/root/.config/autostart/wallpaper.sh.desktop; [ -e $file ] && cp -n $file{,.bkup}
cat <<EOF > $file
[Desktop Entry]
Type=Application
Exec=/usr/local/bin/wallpaper.sh
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name[en_US]=wallpaper
Name=wallpaper
Comment[en_US]=
Comment=
EOF
#--- Configure file browser (need to re-login for effect)
mkdir -p /root/.config/Thunar/
file=/root/.config/Thunar/thunarrc; [ -e $file ] && cp -n $file{,.bkup}
sed -i 's/LastShowHidden=.*/LastShowHidden=TRUE/' $file 2>/dev/null || echo -e "[Configuration]\nLastShowHidden=TRUE" > /root/.config/Thunar/thunarrc;
#--- Enable num lock at start up (might not be smart if you're using a smaller keyboard (laptop?)) ~ https://wiki.xfce.org/faq
#xfconf-query -c keyboards -p /Default/Numlock -s true
apt-get -y -qq install numlockx
file=/etc/xdg/xfce4/xinitrc; [ -e $file ] && cp -n $file{,.bkup}     #/etc/rc.local
grep -q '^/usr/bin/numlockx' $file 2>/dev/null || echo "/usr/bin/numlockx on" >> $file
#--- XFCE fixes for default applications
mkdir -p /root/.local/share/applications/
file=/root/.local/share/applications/mimeapps.list; [ -e $file ] && cp -n $file{,.bkup}
[ ! -e $file ] && echo '[Added Associations]' > $file
for VALUE in file trash; do
  sed -i 's#x-scheme-handler/'$VALUE'=.*#x-scheme-handler/'$VALUE'=exo-file-manager.desktop#' $file
  grep -q '^x-scheme-handler/'$VALUE'=' $file 2>/dev/null || echo -e 'x-scheme-handler/'$VALUE'=exo-file-manager.desktop' >> $file
done
for VALUE in http https; do
  sed -i 's#^x-scheme-handler/'$VALUE'=.*#x-scheme-handler/'$VALUE'=exo-web-browser.desktop#' $file
  grep -q '^x-scheme-handler/'$VALUE'=' $file 2>/dev/null || echo -e 'x-scheme-handler/'$VALUE'=exo-web-browser.desktop' >> $file
done
[[ $(tail -n 1 $file) != "" ]] && echo >> $file
file=/root/.config/xfce4/helpers.rc; [ -e $file ] && cp -n $file{,.bkup}    #exo-preferred-applications   #xdg-mime default
sed -i 's#^FileManager=.*#FileManager=Thunar#' $file 2>/dev/null
grep -q '^FileManager=Thunar' $file 2>/dev/null || echo -e 'FileManager=Thunar' >> $file
#--- Remove any old sessions
rm -f /root/.cache/sessions/*
#--- XFCE fixes for terminator (We do this later)
#mkdir -p /root/.local/share/xfce4/helpers/
#file=/root/.local/share/xfce4/helpers/custom-TerminalEmulator.desktop; [ -e $file ] && cp -n $file{,.bkup}
#sed -i 's#^X-XFCE-CommandsWithParameter=.*#X-XFCE-CommandsWithParameter=/usr/bin/terminator --command="%s"#' $file 2>/dev/null || echo -e '[Desktop Entry]\nNoDisplay=true\nVersion=1.0\nEncoding=UTF-8\nType=X-XFCE-Helper\nX-XFCE-Category=TerminalEmulator\nX-XFCE-CommandsWithParameter=/usr/bin/terminator --command="%s"\nIcon=terminator\nName=terminator\nX-XFCE-Commands=/usr/bin/terminator' > $file
#file=/root/.config/xfce4/helpers.rc; [ -e $file ] && cp -n $file{,.bkup}    #exo-preferred-applications   #xdg-mime default
#sed -i 's#^TerminalEmulator=.*#TerminalEmulator=custom-TerminalEmulator#' $file
#grep -q '^TerminalEmulator=custom-TerminalEmulator' $file 2>/dev/null || echo -e 'TerminalEmulator=custom-TerminalEmulator' >> $file
#--- Set XFCE as default desktop manager
file=/root/.xsession; [ -e $file ] && cp -n $file{,.bkup}       #~/.xsession
echo xfce4-session > $file
#--- Add keyboard shortcut (CTRL+SPACE) to open Application Finder
file=/root/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml   #; [ -e $file ] && cp -n $file{,.bkup}
grep -q '<property name="&lt;Primary&gt;space" type="string" value="xfce4-appfinder"/>' $file || sed -i 's#<property name="\&lt;Alt\&gt;F2" type="string" value="xfrun4"/>#<property name="\&lt;Alt\&gt;F2" type="string" value="xfrun4"/>\n      <property name="\&lt;Primary\&gt;space" type="string" value="xfce4-appfinder"/>#' $file
#--- Add keyboard shortcut (CTRL+ALT+t) to start a terminal window
file=/root/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml   #; [ -e $file ] && cp -n $file{,.bkup}
grep -q '<property name="&lt;Primary&gt;&lt;Alt&gt;t" type="string" value="/usr/bin/exo-open --launch TerminalEmulator"/>' $file || sed -i 's#<property name="\&lt;Alt\&gt;F2" type="string" value="xfrun4"/>#<property name="\&lt;Alt\&gt;F2" type="string" value="xfrun4"/>\n      <property name="\&lt;Primary\&gt;\&lt;Alt\&gt;t" type="string" value="/usr/bin/exo-open --launch TerminalEmulator"/>#' $file
#--- Create Conky refresh script (conky gets installed later)
file=/usr/local/bin/conky_refresh.sh; [ -e $file ] && cp -n $file{,.bkup}
echo -e '#!/bin/bash\n\n/usr/bin/timeout 5 /usr/bin/killall -9 -q -w conky\n/usr/bin/conky &' > $file
chmod -f 0500 $file
#--- Add keyboard shortcut (CTRL+r) to run the conky refresh script
file=/root/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml   #; [ -e $file ] && cp -n $file{,.bkup}
grep -q '<property name="&lt;Primary&gt;r" type="string" value="/usr/local/bin/conky_refresh.sh"/>' $file || sed -i 's#<property name="\&lt;Alt\&gt;F2" type="string" value="xfrun4"/>#<property name="\&lt;Alt\&gt;F2" type="string" value="xfrun4"/>\n      <property name="\&lt;Primary\&gt;r" type="string" value="/usr/local/bin/conky_refresh.sh"/>#' $file


##### Configuring file browser   Note: need to restart xserver for effect
echo -e "\n\e[01;32m[+]\e[00m Configuring file browser"
mkdir -p /root/.config/gtk-2.0/
file=/root/.config/gtk-2.0/gtkfilechooser.ini; [ -e $file ] && cp -n $file{,.bkup}
sed -i 's/^.*ShowHidden.*/ShowHidden=true/' $file 2>/dev/null || echo -e "\n[Filechooser Settings]\nLocationMode=path-bar\nShowHidden=true\nExpandFolders=false\nShowSizeColumn=true\nGeometryX=66\nGeometryY=39\nGeometryWidth=780\nGeometryHeight=618\nSortColumn=name\nSortOrder=ascending" > $file    #Open/save Window -> Right click -> Show Hidden Files: Enabled
dconf write /org/gnome/nautilus/preferences/show-hidden-files true
file=/root/.gtk-bookmarks; [ -e $file ] && cp -n $file{,.bkup}
$(dmidecode | grep -iq vmware) && (mkdir -p /mnt/hgfs/; grep -q '^file:///mnt/hgfs ' $file 2>/dev/null || echo 'file:///mnt/hgfs vmshare' >> $file)
grep -q '^file:///tmp ' $file 2>/dev/null || echo 'file:///tmp tmp' >> $file
grep -q '^file:///usr/local/src ' $file 2>/dev/null || echo 'file:///usr/local/src src' >> $file
grep -q '^file:///usr/share ' $file 2>/dev/null || echo 'file:///usr/share kali' >> $file
grep -q '^file:///var/ftp ' $file 2>/dev/null || echo 'file:///var/ftp ftp' >> $file
grep -q '^file:///var/samba ' $file 2>/dev/null || echo 'file:///var/samba samba' >> $file
grep -q '^file:///var/tftp ' $file 2>/dev/null || echo 'file:///var/tftp tftp' >> $file
grep -q '^file:///var/www ' $file 2>/dev/null || echo 'file:///var/www www' >> $file


##### Configuring terminal   Note: need to restart xserver for effect
echo -e "\n\e[01;32m[+]\e[00m Configuring terminal"
gconftool-2 --type bool --set /apps/gnome-terminal/profiles/Default/scrollback_unlimited true                   # Terminal -> Edit -> Profile Preferences -> Scrolling -> Scrollback: Unlimited -> Close
gconftool-2 --type string --set /apps/gnome-terminal/profiles/Default/background_darkness 0.85611499999999996   # Not working 100%!
gconftool-2 --type string --set /apps/gnome-terminal/profiles/Default/background_type transparent


##### Configuring bash - all users
echo -e "\n\e[01;32m[+]\e[00m Configuring bash"
file=/etc/bash.bashrc; [ -e $file ] && cp -n $file{,.bkup}    #/root/.bashrc
grep -q "cdspell" $file || echo "shopt -sq cdspell" >> $file             # Spell check 'cd' commands
grep -q "checkwinsize" $file || echo "shopt -sq checkwinsize" >> $file   # Wrap lines correctly after resizing
grep -q "nocaseglob" $file || echo "shopt -sq nocaseglob" >> $file       # Case insensitive pathname expansion
grep -q "HISTSIZE" $file || echo "HISTSIZE=10000" >> $file               # Bash history (memory scroll back)
grep -q "HISTFILESIZE" $file || echo "HISTFILESIZE=10000" >> $file       # Bash history (file .bash_history)
#--- Apply new configs
[ $SHELL == "/bin/zsh" ] && source ~/.zshrc || source $file


##### Configuring bash colour - all users
echo -e "\n\e[01;32m[+]\e[00m Configuring bash colour"
file=/etc/bash.bashrc; [ -e $file ] && cp -n $file{,.bkup}   #/root/.bashrc
sed -i 's/.*force_color_prompt=.*/force_color_prompt=yes/' $file
grep -q '^force_color_prompt' $file 2>/dev/null || echo 'force_color_prompt=yes' >> $file
sed -i 's#PS1='"'"'.*'"'"'#PS1='"'"'${debian_chroot:+($debian_chroot)}\\[\\033\[01;31m\\]\\u@\\h\\\[\\033\[00m\\]:\\[\\033\[01;34m\\]\\w\\[\\033\[00m\\]\\$ '"'"'#' $file
#--- All other users that are made afterwards
file=/etc/skel/.bashrc   #; [ -e $file ] && cp -n $file{,.bkup}
sed -i 's/.*force_color_prompt=.*/force_color_prompt=yes/' $file
#--- Apply new colours
[ $SHELL == "/bin/zsh" ] && source ~/.zshrc || source $file


##### Installing bash completion - all users
echo -e "\n\e[01;32m[+]\e[00m Installing bash completion"
apt-get -y -qq install bash-completion
file=/etc/bash.bashrc; [ -e $file ] && cp -n $file{,.bkup}    #/root/.bashrc
sed -i '/# enable bash completion in/,+7{/enable bash completion/!s/^#//}' $file
#--- Apply new function
[ $SHELL == "/bin/zsh" ] && source ~/.zshrc || source $file


##### Configuring aliases - root user
echo -e "\n\e[01;32m[+]\e[00m Configuring aliases"
#--- Enable defaults - root user
for FILE in /etc/bash.bashrc /root/.bashrc /root/.bash_aliases; do    #/etc/profile /etc/bashrc /etc/bash_aliases /etc/bash.bash_aliases
  [ ! -e $FILE ] && continue
  cp -n $FILE{,.bkup}
  sed -i 's/#alias/alias/g' $FILE
done
#--- General system ones
file=/root/.bash_aliases; [ -e $file ] && cp -n $file{,.bkup}   #/etc/bash.bash_aliases
grep -q '^## grep aliases' $file 2>/dev/null || echo -e '## grep aliases\nalias grep="grep --color=always"\nalias ngrep="grep -n"\n\n' >> $file
grep -q '^alias egrep=' $file 2>/dev/null || echo 'alias egrep="egrep --color=auto"\n\n' >> $file
grep -q '^alias fgrep=' $file 2>/dev/null || echo 'alias fgrep="fgrep --color=auto"\n\n' >> $file
#--- Add in ours (OS programs)
grep -q '^alias tmux' $file 2>/dev/null || echo -e '## tmux\nalias tmux="tmux attach || tmux new"\n\n' >> $file    #alias tmux="tmux attach -t $HOST || tmux new -s $HOST"
grep -q '^alias axel' $file 2>/dev/null || echo -e '## axel\nalias axel="axel -a"\n\n' >> $file
grep -q '^alias screen' $file 2>/dev/null || echo -e '## screen\nalias screen="screen -xRR"\n\n' >> $file
#--- Add in ours (shortcuts)
grep -q '^## Checksums' $file 2>/dev/null || echo -e '## Checksums\nalias sha1="openssl sha1"\nalias md5="openssl md5"\n\n' >> $file
grep -q '^## Force create folders' $file 2>/dev/null || echo -e '## Force create folders\nalias mkdir="/bin/mkdir -pv"\n\n' >> $file
#grep -q '^## Mount' $file 2>/dev/null || echo -e '## Mount\nalias mount="mount | column -t"\n\n' >> $file
grep -q '^## List open ports' $file 2>/dev/null || echo -e '## List open ports\nalias ports="netstat -tulanp"\n\n' >> $file
grep -q '^## Get headers' $file 2>/dev/null || echo -e '## Get headers\nalias header="curl -I"\n\n' >> $file
grep -q '^## Get external IP address' $file 2>/dev/null || echo -e '## Get external IP address\nalias ipx="curl -s http://ipinfo.io/ip"\n\n' >> $file
grep -q '^## Directory navigation aliases' $file 2>/dev/null || echo -e '## Directory navigation aliases\nalias ..="cd .."\nalias ...="cd ../.."\nalias ....="cd ../../.."\nalias .....="cd ../../../.."\n\n' >> $file
grep -q '^## Add more aliases' $file 2>/dev/null || echo -e '## Add more aliases\nalias upd="sudo apt-get update"\nalias upg="sudo apt-get upgrade"\nalias ins="sudo apt-get install"\nalias rem="sudo apt-get purge"\nalias fix="sudo apt-get install -f"\n\n' >> $file
grep -q '^## Extract file' $file 2>/dev/null || echo -e '## Extract file, example. "ex package.tar.bz2"\nex() {\n    if [[ -f $1 ]]; then\n        case $1 in\n            *.tar.bz2)   tar xjf $1  ;;\n            *.tar.gz)    tar xzf $1  ;;\n            *.bz2)       bunzip2 $1  ;;\n            *.rar)       rar x $1    ;;\n            *.gz)        gunzip $1   ;;\n            *.tar)       tar xf $1   ;;\n            *.tbz2)      tar xjf $1  ;;\n            *.tgz)       tar xzf $1  ;;\n            *.zip)       unzip $1    ;;\n            *.Z)         uncompress $1  ;;\n            *.7z)        7z x $1     ;;\n            *)           echo $1 cannot be extracted ;;\n        esac\n    else\n        echo $1 is not a valid file\n    fi\n}\n\n' >> $file
grep -q '^## strings' $file 2>/dev/null || echo -e '## strings\nalias strings="strings -a"\n\n' >> $file
#--- Add in tools
grep -q '^## nmap' $file 2>/dev/null || echo -e '## nmap\nalias nmap="nmap --reason"\n\n' >> $file
grep -q '^## aircrack-ng' $file 2>/dev/null || echo -e '## aircrack-ng\nalias aircrack-ng="aircrack-ng -z"\n\n' >> $file
grep -q '^## metasploit' $file 2>/dev/null || echo -e '## metasploit\nalias msfc="service postgresql start; service metasploit start; msfconsole -q"\n\n' >> $file
#airmon-vz --verbose
#--- Apply new aliases
[ $SHELL == "/bin/zsh" ] && source ~/.zshrc || source $file
#--- Check
#alias


##### Installing terminator
echo -e "\n\e[01;32m[+]\e[00m Installing terminator ~ multiple terminals in a single window"
apt-get -y -qq install terminator
#--- Configure terminator
mkdir -p /root/.config/terminator/
file=/root/.config/terminator/config; [ -e $file ] && cp -n $file{,.bkup}
cat <<EOF > $file
[global_config]
  enabled_plugins = TerminalShot, LaunchpadCodeURLHandler, APTURLHandler, LaunchpadBugURLHandler
[keybindings]
[profiles]
  [[default]]
    background_darkness = 0.9
    scroll_on_output = False
    copy_on_selection = True
    background_type = transparent
    scrollback_infinite = True
    show_titlebar = False
[layouts]
  [[default]]
    [[[child1]]]
      type = Terminal
      parent = window0
    [[[window0]]]
      type = Window
      parent = ""
[plugins]
EOF
#--- xfce fix for terminator
mkdir -p /root/.local/share/xfce4/helpers/
file=/root/.local/share/xfce4/helpers/custom-TerminalEmulator.desktop; [ -e $file ] && cp -n $file{,.bkup}
sed -i 's#^X-XFCE-CommandsWithParameter=.*#X-XFCE-CommandsWithParameter=/usr/bin/terminator --command="%s"#' $file 2>/dev/null || cat <<EOF > $file
[Desktop Entry]
NoDisplay=true
Version=1.0
Encoding=UTF-8
Type=X-XFCE-Helper
X-XFCE-Category=TerminalEmulator
X-XFCE-CommandsWithParameter=/usr/bin/terminator --command="%s"
Icon=terminator
Name=terminator
X-XFCE-Commands=/usr/bin/terminator
EOF
file=/root/.config/xfce4/helpers.rc; [ -e $file ] && cp -n $file{,.bkup}    #exo-preferred-applications   #xdg-mime default
sed -i 's#^TerminalEmulator=.*#TerminalEmulator=custom-TerminalEmulator#' $file
grep -q '^TerminalEmulator=custom-TerminalEmulator' $file 2>/dev/null || echo -e 'TerminalEmulator=custom-TerminalEmulator' >> $file


##### Installing ZSH & Oh-My-ZSH - root user.   Note: If you use thurar, 'Open terminal here', will not work.
echo -e "\n\e[01;32m[+]\e[00m Installing ZSH & Oh-My-ZSH ~ unix shell"
group="sudo"
apt-get -y -qq install zsh git curl
#--- Setup oh-my-zsh
curl --progress -k -L https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh | sh     #curl -s -L https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh
#--- Configure zsh
file=/root/.zshrc; [ -e $file ] && cp -n $file{,.bkup}   #/etc/zsh/zshrc
grep -q 'interactivecomments' $file 2>/dev/null || echo 'setopt interactivecomments' >> $file
grep -q 'ignoreeof' $file 2>/dev/null || echo 'setopt ignoreeof' >> $file
grep -q 'correctall' $file 2>/dev/null || echo 'setopt correctall' >> $file
grep -q 'globdots' $file 2>/dev/null || echo 'setopt globdots' >> $file
grep -q '.bash_aliases' $file 2>/dev/null || echo 'source $HOME/.bash_aliases' >> $file
grep -q '/usr/bin/tmux' $file 2>/dev/null || echo 'if ([[ -z "$TMUX" ]] && [[ -n "$SSH_CONNECTION" ]]); then /usr/bin/tmux attach || /usr/bin/tmux new; fi' >> $file   # If not already in tmux and via SSH
#--- Configure zsh (themes) ~ https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
sed -i 's/ZSH_THEME=.*/ZSH_THEME="alanpeabody"/' $file   # Other themes: alanpeabody, jreese,   mh,   candy,   terminalparty, kardan,   nicoulaj, sunaku
#--- Configure oh-my-zsh
sed -i 's/.*DISABLE_AUTO_UPDATE="true"/DISABLE_AUTO_UPDATE="true"/' $file
sed -i 's/plugins=(.*)/plugins=(git tmux last-working-dir)/' $file
#--- Set zsh as default shell (current user)
chsh -s $(which zsh)
#--- Use it ~ Not much point to it being a post-install script
#/usr/bin/env zsh      # Use it
#source $file          # Make sure to reload our config
#--- Copy it to other user(s)
#if [ -e /home/$username/ ]; then   # Will do this later on again, if there isn't already a user
#  cp -f /{root,home/$username}/.zshrc
#  cp -rf /{root,home/$username}/.oh-my-zsh/
#  chown -R $username\:$group /home/$username/.zshrc /home/$username/.oh-my-zsh/
#  chsh $username -s $(which zsh)
#fi


##### Installing tmux - all users
echo -e "\n\e[01;32m[+]\e[00m Installing tmux ~ multiplex virtual consoles"
group="sudo"
#apt-get -y -qq remove screen   # Optional: If we're going to have/use tmux, why have screen?
apt-get -y -qq install tmux
#--- Configure tmux
file=/root/.tmux.conf; [ -e $file ] && cp -n $file{,.bkup}   #/etc/tmux.conf
cat <<EOF > $file
#-Settings---------------------------------------------------------------------
## Make it like screen (use CTRL+a)
unbind C-b
set -g prefix C-a

## Pane switching (ALT+ARROWS)
bind -n M-Left select-pane -L
bind -n M-Right select-pane -R
bind -n M-Up select-pane -U
bind -n M-Down select-pane -D

## Windows re-ording (CTRL+SHIFT+ARROWS)
bind-key -n C-S-Left swap-window -t -1
bind-key -n C-S-Right swap-window -t +1

## Activity Monitoring
setw -g monitor-activity on
set -g visual-activity on

## Set defaults
set -g default-terminal screen-256color
set -g history-limit 5000

## Default windows titles
set -g set-titles on
set -g set-titles-string '#(whoami)@#H - #I:#W'

## Last window switch
bind-key C-a last-window

## Reload settings (CTRL+a -> r)
unbind r
bind r source-file /etc/tmux.conf

## Load custom sources
#source ~/.bashrc   #(issues if you use /bin/bash & Debian)

EOF
[ -e /bin/zsh ] && echo -e '## Use ZSH as default shell\nset-option -g default-shell /bin/zsh\n' >> $file      # Need to have ZSH installed before running this command/line
cat <<EOF >> $file
## Show tmux messages for longer
set -g display-time 3000

## Status bar is redrawn every minute
set -g status-interval 60


#-Theme------------------------------------------------------------------------
## Default colours
set -g status-bg black
set -g status-fg white

## Left hand side
set -g status-left-length '34'
set -g status-left '#[fg=green,bold]#(whoami)#[default]@#[fg=yellow,dim]#H #[fg=green,dim][#[fg=yellow]#(cut -d " " -f 1-3 /proc/loadavg)#[fg=green,dim]]'

## Inactive windows in status bar
set-window-option -g window-status-format '#[fg=red,dim]#I#[fg=grey,dim]:#[default,dim]#W#[fg=grey,dim]'

## Current or active window in status bar
#set-window-option -g window-status-current-format '#[bg=white,fg=red]#I#[bg=white,fg=grey]:#[bg=white,fg=black]#W#[fg=dim]#F'
set-window-option -g window-status-current-format '#[fg=red,bold](#[fg=white,bold]#I#[fg=red,dim]:#[fg=white,bold]#W#[fg=red,bold])'

## Right hand side
set -g status-right '#[fg=green][#[fg=yellow]%Y-%m-%d #[fg=white]%H:%M#[fg=green]]'
EOF
#--- Setup alias
file=/root/.bash_aliases; [ -e $file ] && cp -n $file{,.bkup}   #/etc/bash.bash_aliases
grep -q '^alias tmux' $file 2>/dev/null || echo -e '## tmux\nalias tmux="tmux attach || tmux new"\n\n' >> $file    #alias tmux="tmux attach -t $HOST || tmux new -s $HOST"
#--- Apply new aliases
[ $SHELL == "/bin/zsh" ] && source ~/.zshrc || source $file
#--- Copy it to other user(s) ~
#if [ -e /home/$username/ ]; then   # Will do this later on again, if there isn't already a user
#  cp -f /{etc/,home/$username/.}tmux.conf    #cp -f /{root,home/$username}/.tmux.conf
#  chown $username\:$group /home/$username/.tmux.conf
#  file=/home/$username/.bash_aliases; [ -e $file ] && cp -n $file{,.bkup}
#  grep -q '^alias tmux' $file 2>/dev/null || echo -e '## tmux\nalias tmux="tmux attach || tmux new"\n\n' >> $file    #alias tmux="tmux attach -t $HOST || tmux new -s $HOST"
#fi
#--- Use it ~ bit pointless if used in a post-install script
#tmux


##### Configuring screen ~ if possible, use tmux instead!
echo -e "\n\e[01;32m[+]\e[00m Configuring screen ~ multiplex virtual consoles"
#apt-get -y -qq install screen
#--- Configure screen
file=/root/.screenrc; [ -e $file ] && cp -n $file{,.bkup}
cat <<EOF > $file
## Don't display the copyright page
startup_message off

## tab-completion flash in heading bar
vbell off

## Keep scrollback n lines
defscrollback 1000

## Hardstatus is a bar of text that is visible in all screens
hardstatus on
hardstatus alwayslastline
hardstatus string '%{gk}%{G}%H %{g}[%{Y}%l%{g}] %= %{wk}%?%-w%?%{=b kR}(%{W}%n %t%?(%u)%?%{=b kR})%{= kw}%?%+w%?%?%= %{g} %{Y} %Y-%m-%d %C%a %{W}'

## Title bar
termcapinfo xterm ti@:te@

## Default windows (syntax: screen -t label order command)
screen -t bash1 0
screen -t bash2 1

## Select the default window
select 0
EOF


##### Configuring vim - all users
echo -e "\n\e[01;32m[+]\e[00m Configuring vim ~ CLI text editor"
apt-get -y -qq install vim
#--- Configure vim
file=/etc/vim/vimrc; [ -e $file ] && cp -n $file{,.bkup}   #/root/.vimrc
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
grep -q '^set number' $file 2>/dev/null || echo 'set number' >> $file                                                                        # Add line numbers
grep -q '^set autoindent' $file 2>/dev/null || echo 'set autoindent' >> $file                                                                # Set auto indent
grep -q '^set expandtab' $file 2>/dev/null || echo -e 'set expandtab\nset smarttab' >> $file                                                 # Set use spaces instead of tabs
grep -q '^set softtabstop' $file 2>/dev/null || echo -e 'set softtabstop=4\nset shiftwidth=4' >> $file                                       # Set 4 spaces as a 'tab'
grep -q '^set foldmethod=marker' $file 2>/dev/null || echo 'set foldmethod=marker' >> $file                                                  # Folding
grep -q '^nnoremap <space> za' $file 2>/dev/null || echo 'nnoremap <space> za' >> $file                                                      # Space toggle folds
grep -q '^set hlsearch' $file 2>/dev/null || echo 'set hlsearch' >> $file                                                                    # Highlight search results
grep -q '^set laststatus' $file 2>/dev/null || echo -e 'set laststatus=2\nset statusline=%F%m%r%h%w\ (%{&ff}){%Y}\ [%l,%v][%p%%]' >> $file   # Status bar
grep -q '^filetype on' $file 2>/dev/null || echo -e 'filetype on\nfiletype plugin on\nsyntax enable\nset grepprg=grep\ -nH\ $*' >> $file     # Syntax highlighting
grep -q '^set wildmenu' $file 2>/dev/null || echo -e 'set wildmenu\nset wildmode=list:longest,full' >> $file                                 # Tab completion
grep -q '^set pastetoggle=<F9>' $file 2>/dev/null || echo -e 'set pastetoggle=<F9>' >> $file                                                 # Hotkey - turning off auto indent when pasting
#--- Set as default editor
export EDITOR="vim"   #update-alternatives --config editor
file=/etc/bash.bashrc; [ -e $file ] && cp -n $file{,.bkup}
grep -q '^EDITOR' $file 2>/dev/null || echo 'EDITOR="vim"' >> $file
git config --global core.editor "vim"
#--- Set as default mergetool
git config --global merge.tool vimdiff
git config --global merge.conflictstyle diff3
git config --global mergetool.prompt false


##### Setting up iceweasel
echo -e "\n\e[01;32m[+]\e[00m Setting up iceweasel ~ GUI web browser"
apt-get install -y -qq unzip curl wget iceweasel
#--- Configure iceweasel
export DISPLAY=:0.0   #[[ -z $SSH_CONNECTION ]] || export DISPLAY=:0.0
timeout 15 iceweasel   #iceweasel & sleep 15; killall -q -w iceweasel >/dev/null   # Start and kill. Files needed for first time run
timeout 5 killall -9 -q -w iceweasel >/dev/null
file=$(find /root/.mozilla/firefox/*.default*/ -maxdepth 1 -type f -name 'prefs.js' -print -quit) && [ -e $file ] && cp -n $file{,.bkup}   #/etc/iceweasel/pref/*.js
sed -i 's/^.*browser.startup.page.*/user_pref("browser.startup.page", 0);' $file 2>/dev/null || echo 'user_pref("browser.startup.page", 0);' >> $file                                              # Iceweasel -> Edit -> Preferences -> General -> When firefox starts: Show a blank page
sed -i 's/^.*privacy.donottrackheader.enabled.*/user_pref("privacy.donottrackheader.enabled", true);' $file 2>/dev/null || echo 'user_pref("privacy.donottrackheader.enabled", true);' >> $file    # Privacy -> Enable: Tell websites I do not want to be tracked
sed -i 's/^.*browser.showQuitWarning.*/user_pref("browser.showQuitWarning", true);' $file 2>/dev/null || echo 'user_pref("browser.showQuitWarning", true);' >> $file                               # Stop Ctrl+Q from quitting without warning
#--- Replace bookmarks (base: http://pentest-bookmarks.googlecode.com)
file=$(find /root/.mozilla/firefox/*.default*/ -maxdepth 1 -type f -name 'bookmarks.html' -print -quit) && [ -e $file ] && cp -n $file{,.bkup}   #/etc/iceweasel/profile/bookmarks.html
wget -q "http://pentest-bookmarks.googlecode.com/files/bookmarksv1.5.html" -O /tmp/bookmarks_new.html     #***!!! hardcoded version! Need to manually check for updates
#--- Configure bookmarks
awk '!a[$0]++' /tmp/bookmarks_new.html | \egrep -v ">(Latest Headlines|Getting Started|Recently Bookmarked|Recent Tags|Mozilla Firefox|Help and Tutorials|Customize Firefox|Get Involved|About Us|Hacker Media|Bookmarks Toolbar|Most Visited)</" | \egrep -v "^    </DL><p>" | \egrep -v "^<DD>Add" > $file
sed -i 's#^</DL><p>#        </DL><p>\n    </DL><p>\n</DL><p>#' $file                                                                                                                                              # Fix import issues
sed -i 's#^    <DL><p>#    <DL><p>\n    <DT><A HREF="http://127.0.0.1/">localhost</A>#' $file                                                                                                                     # Add localhost to bookmark toolbar
sed -i 's#^</DL><p>#    <DT><A HREF="https://127.0.0.1:8834/">Nessus</A>\n    <DT><A HREF="https://127.0.0.1:3790/">MSF Community</A>\n    <DT><A HREF="https://127.0.0.1:9392/">OpenVAS</A>\n</DL><p>#' $file    # Add in Nessus, MSF & OpenVAS to bookmark toolbar
sed -i 's#^</DL><p>#    <DT><A HREF="http://127.0.0.1/rips/">RIPS</A>\n</DL><p>#' $file                                                                                                                           # Add in RIPs to bookmark toolbar
sed -i 's#^</DL><p>#    <DT><A HREF="https://paulschou.com/tools/xlate/">XLATE</A>\n</DL><p>#' $file                                                                                                              # Add in XLATE to bookmark toolbar
sed -i 's#<HR>#<DT><H3 ADD_DATE="1303667175" LAST_MODIFIED="1303667175" PERSONAL_TOOLBAR_FOLDER="true">Bookmarks Toolbar</H3>\n<DD>Add bookmarks to this folder to see them displayed on the Bookmarks Toolbar#' $file
#--- Clear bookmark cache
find /root/.mozilla/firefox/*.default*/ -maxdepth 1 -mindepth 1 -type f -name places.sqlite -delete
find /root/.mozilla/firefox/*.default*/bookmarkbackups/ -type f -delete
#--- Download extensions
ffpath="$(find /root/.mozilla/firefox/*.default*/ -maxdepth 0 -mindepth 0 -type d -print -quit)/extensions"
mkdir -p $ffpath/
curl --progress -k -L https://addons.mozilla.org/firefox/downloads/latest/5817/addon-5817-latest.xpi?src=dp-btn-primary -o $ffpath/SQLiteManager@mrinalkant.blogspot.com.xpi           # SQLite Manager
curl --progress -k -L https://addons.mozilla.org/firefox/downloads/latest/1865/addon-1865-latest.xpi?src=dp-btn-primary -o $ffpath/{d10d0bf8-f5b5-c8b4-a8b2-2b9879e08c5d}.xpi          # Adblock Plus
curl --progress -k -L https://addons.mozilla.org/firefox/downloads/latest/92079/addon-92079-latest.xpi?src=dp-btn-primary -o $ffpath/{bb6bc1bb-f824-4702-90cd-35e2fb24f25d}.xpi        # Cookies Manager+
curl --progress -k -L https://addons.mozilla.org/firefox/downloads/latest/1843/addon-1843-latest.xpi?src=dp-btn-primary -o $ffpath/firebug@software.joehewitt.com.xpi                  # Firebug
curl --progress -k -L https://addons.mozilla.org/firefox/downloads/latest/15023/addon-15023-latest.xpi?src=dp-btn-primary -o /tmp/FoxyProxyBasic.zip && unzip -q -o -d $ffpath/foxyproxy-basic@eric.h.jung/ /tmp/FoxyProxyBasic.zip; rm -f /tmp/FoxyProxyBasic.zip   # FoxyProxy Basic
curl --progress -k -L https://addons.mozilla.org/firefox/downloads/latest/429678/addon-429678-latest.xpi?src=dp-btn-primary -o $ffpath/useragentoverrider@qixinglu.com.xpi             # User Agent Overrider
#curl --progress -k -L https://github.com/mozmark/ringleader/blob/master/fx_pnh.xpi?raw=true                                                                                           # plug-n-hack
#curl --progress -k -L https://addons.mozilla.org/firefox/downloads/latest/284030/addon-284030-latest.xpi?src=dp-btn-primary -o $ffpath/{6bdc61ae-7b80-44a3-9476-e1d121ec2238}.xpi     # HTTPS Finder
curl --progress -k -L https://www.eff.org/files/https-everywhere-latest.xpi -o $ffpath/https-everywhere@eff.org.xpi                                                                    # HTTPS Everywhere
curl --progress -k -L https://addons.mozilla.org/firefox/downloads/latest/3829/addon-3829-latest.xpi?src=dp-btn-primary -o $ffpath/{8f8fe09b-0bd3-4470-bc1b-8cad42b8203a}.xpi          # Live HTTP Headers
curl --progress -k -L https://addons.mozilla.org/firefox/downloads/latest/966/addon-966-latest.xpi?src=dp-btn-primary -o $ffpath/{9c51bd27-6ed8-4000-a2bf-36cb95c0c947}.xpi        # Tamper Data
curl --progress -k -L https://addons.mozilla.org/firefox/downloads/latest/300254/addon-300254-latest.xpi?src=dp-btn-primary -o $ffpath/check-compatibility@dactyl.googlecode.com.xpi   # Disable Add-on Compatibility Checks
#--- Installing extensions
for FILE in $(find $ffpath -maxdepth 1 -type f -name '*.xpi'); do
  d="$(basename $FILE .xpi)"
  mkdir -p $ffpath/$d/
  unzip -q -o -d $ffpath/$d/ $FILE
  rm -f $FILE
done
#--- Enable Iceweasel's addons/plugins/extensions
timeout 15 iceweasel   #iceweasel & sleep 15; killall -q -w iceweasel >/dev/null
file=$(find /root/.mozilla/firefox/*.default*/ -maxdepth 1 -type f -name 'extensions.sqlite' -print -quit)   #&& [ -e $file ] && cp -n $file{,.bkup}
if [ ! -e $file ] || [ -z $file ]; then
  #echo -e '\e[01;31m[!]\e[00m Something went wrong enabling iceweasels extensions via method #1. Trying method #2...'
  false
else
  echo -e "\e[01;33m[i]\e[00m Enabling iceweasel's extensions via method #1: Success!"
  apt-get install -y -qq sqlite3
  rm -f /tmp/iceweasel.sql; touch /tmp/iceweasel.sql
  echo "UPDATE 'main'.'addon' SET 'active' = 1, 'userDisabled' = 0;" > /tmp/iceweasel.sql    # Force them all!
  sqlite3 $file < /tmp/iceweasel.sql      #fuser extensions.sqlite
fi
file=$(find /root/.mozilla/firefox/*.default*/ -maxdepth 1 -type f -name 'extensions.json' -print -quit)   #&& [ -e $file ] && cp -n $file{,.bkup}
if [ ! -e $file ] || [ -z $file ]; then
  #echo -e '\e[01;31m[!]\e[00m Something went wrong enabling iceweasels extensions via method #2. Did method #1 also fail?''
  false
else
  echo -e "\e[01;33m[i]\e[00m Enabling iceweasel's extensions via method #2: Success!"
  sed -i 's/"active":false,/"active":true,/g' $file                # Force them all!
  sed -i 's/"userDisabled":true,/"userDisabled":false,/g' $file    # Force them all!
fi
file=$(find /root/.mozilla/firefox/*.default*/ -maxdepth 1 -type f -name 'prefs.js' -print -quit)   #&& [ -e $file ] && cp -n $file{,.bkup}
[ ! -z $file ] && sed -i '/extensions.installCache/d' $file
timeout 15 iceweasel >/dev/null   # For extensions that just work without restarting
timeout 15 iceweasel >/dev/null   # ...for (most) extensions, as they need iceweasel to restart
#--- Configure foxyproxy
file=$(find /root/.mozilla/firefox/*.default*/ -maxdepth 1 -type f -name 'foxyproxy.xml' -print -quit)   #&& [ -e $file ] && cp -n $file{,.bkup}
if [ -z $file ]; then
  echo -e '\e[01;31m[!]\e[00m Something went wrong with the foxyproxy iceweasel extension (did extensions install?). Skipping...'
elif [ -e $file ]; then
  grep -q 'localhost:8080' $file 2>/dev/null || sed -i 's#<proxy name="Default"#<proxy name="localhost:8080" id="1145138293" notes="e.g. Burp, w3af" fromSubscription="false" enabled="true" mode="manual" selectedTabIndex="0" lastresort="false" animatedIcons="true" includeInCycle="false" color="\#07753E" proxyDNS="true" noInternalIPs="false" autoconfMode="pac" clearCacheBeforeUse="true" disableCache="true" clearCookiesBeforeUse="false" rejectCookies="false"><matches/><autoconf url="" loadNotification="true" errorNotification="true" autoReload="false" reloadFreqMins="60" disableOnBadPAC="true"/><autoconf url="http://wpad/wpad.dat" loadNotification="true" errorNotification="true" autoReload="false" reloadFreqMins="60" disableOnBadPAC="true"/><manualconf host="127.0.0.1" port="8080" socksversion="5" isSocks="false" username="" password="" domain=""/></proxy><proxy name="Default"#' $file          # localhost:8080
  grep -q 'localhost:8081' $file 2>/dev/null || sed -i 's#<proxy name="Default"#<proxy name="localhost:8081 (socket5)" id="212586674" notes="e.g. SSH" fromSubscription="false" enabled="true" mode="manual" selectedTabIndex="0" lastresort="false" animatedIcons="true" includeInCycle="false" color="\#917504" proxyDNS="true" noInternalIPs="false" autoconfMode="pac" clearCacheBeforeUse="true" disableCache="true" clearCookiesBeforeUse="false" rejectCookies="false"><matches/><autoconf url="" loadNotification="true" errorNotification="true" autoReload="false" reloadFreqMins="60" disableOnBadPAC="true"/><autoconf url="http://wpad/wpad.dat" loadNotification="true" errorNotification="true" autoReload="false" reloadFreqMins="60" disableOnBadPAC="true"/><manualconf host="127.0.0.1" port="8081" socksversion="5" isSocks="true" username="" password="" domain=""/></proxy><proxy name="Default"#' $file         # localhost:8081 (socket5)
  grep -q '"No Caching"' $file 2>/dev/null   || sed -i 's#<proxy name="Default"#<proxy name="No Caching" id="3884644610" notes="" fromSubscription="false" enabled="true" mode="system" selectedTabIndex="0" lastresort="false" animatedIcons="true" includeInCycle="false" color="\#990DA6" proxyDNS="true" noInternalIPs="false" autoconfMode="pac" clearCacheBeforeUse="true" disableCache="true" clearCookiesBeforeUse="false" rejectCookies="false"><matches/><autoconf url="" loadNotification="true" errorNotification="true" autoReload="false" reloadFreqMins="60" disableOnBadPAC="true"/><autoconf url="http://wpad/wpad.dat" loadNotification="true" errorNotification="true" autoReload="false" reloadFreqMins="60" disableOnBadPAC="true"/><manualconf host="" port="" socksversion="5" isSocks="false" username="" password="" domain=""/></proxy><proxy name="Default"#' $file                                          # No caching
else
  echo -ne '<?xml version="1.0" encoding="UTF-8"?>\n<foxyproxy mode="disabled" selectedTabIndex="0" toolbaricon="true" toolsMenu="true" contextMenu="true" advancedMenus="false" previousMode="disabled" resetIconColors="true" useStatusBarPrefix="true" excludePatternsFromCycling="false" excludeDisabledFromCycling="false" ignoreProxyScheme="false" apiDisabled="false" proxyForVersionCheck=""><random includeDirect="false" includeDisabled="false"/><statusbar icon="true" text="false" left="options" middle="cycle" right="contextmenu" width="0"/><toolbar left="options" middle="cycle" right="contextmenu"/><logg enabled="false" maxSize="500" noURLs="false" header="&lt;?xml version=&quot;1.0&quot; encoding=&quot;UTF-8&quot;?&gt;\n&lt;!DOCTYPE html PUBLIC &quot;-//W3C//DTD XHTML 1.0 Strict//EN&quot; &quot;http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd&quot;&gt;\n&lt;html xmlns=&quot;http://www.w3.org/1999/xhtml&quot;&gt;&lt;head&gt;&lt;title&gt;&lt;/title&gt;&lt;link rel=&quot;icon&quot; href=&quot;http://getfoxyproxy.org/favicon.ico&quot;/&gt;&lt;link rel=&quot;shortcut icon&quot; href=&quot;http://getfoxyproxy.org/favicon.ico&quot;/&gt;&lt;link rel=&quot;stylesheet&quot; href=&quot;http://getfoxyproxy.org/styles/log.css&quot; type=&quot;text/css&quot;/&gt;&lt;/head&gt;&lt;body&gt;&lt;table class=&quot;log-table&quot;&gt;&lt;thead&gt;&lt;tr&gt;&lt;td class=&quot;heading&quot;&gt;${timestamp-heading}&lt;/td&gt;&lt;td class=&quot;heading&quot;&gt;${url-heading}&lt;/td&gt;&lt;td class=&quot;heading&quot;&gt;${proxy-name-heading}&lt;/td&gt;&lt;td class=&quot;heading&quot;&gt;${proxy-notes-heading}&lt;/td&gt;&lt;td class=&quot;heading&quot;&gt;${pattern-name-heading}&lt;/td&gt;&lt;td class=&quot;heading&quot;&gt;${pattern-heading}&lt;/td&gt;&lt;td class=&quot;heading&quot;&gt;${pattern-case-heading}&lt;/td&gt;&lt;td class=&quot;heading&quot;&gt;${pattern-type-heading}&lt;/td&gt;&lt;td class=&quot;heading&quot;&gt;${pattern-color-heading}&lt;/td&gt;&lt;td class=&quot;heading&quot;&gt;${pac-result-heading}&lt;/td&gt;&lt;td class=&quot;heading&quot;&gt;${error-msg-heading}&lt;/td&gt;&lt;/tr&gt;&lt;/thead&gt;&lt;tfoot&gt;&lt;tr&gt;&lt;td/&gt;&lt;/tr&gt;&lt;/tfoot&gt;&lt;tbody&gt;" row="&lt;tr&gt;&lt;td class=&quot;timestamp&quot;&gt;${timestamp}&lt;/td&gt;&lt;td class=&quot;url&quot;&gt;&lt;a href=&quot;${url}&quot;&gt;${url}&lt;/a&gt;&lt;/td&gt;&lt;td class=&quot;proxy-name&quot;&gt;${proxy-name}&lt;/td&gt;&lt;td class=&quot;proxy-notes&quot;&gt;${proxy-notes}&lt;/td&gt;&lt;td class=&quot;pattern-name&quot;&gt;${pattern-name}&lt;/td&gt;&lt;td class=&quot;pattern&quot;&gt;${pattern}&lt;/td&gt;&lt;td class=&quot;pattern-case&quot;&gt;${pattern-case}&lt;/td&gt;&lt;td class=&quot;pattern-type&quot;&gt;${pattern-type}&lt;/td&gt;&lt;td class=&quot;pattern-color&quot;&gt;${pattern-color}&lt;/td&gt;&lt;td class=&quot;pac-result&quot;&gt;${pac-result}&lt;/td&gt;&lt;td class=&quot;error-msg&quot;&gt;${error-msg}&lt;/td&gt;&lt;/tr&gt;" footer="&lt;/tbody&gt;&lt;/table&gt;&lt;/body&gt;&lt;/html&gt;"/><warnings/><autoadd enabled="false" temp="false" reload="true" notify="true" notifyWhenCanceled="true" prompt="true"><match enabled="true" name="Dynamic AutoAdd Pattern" pattern="*://${3}${6}/*" isRegEx="false" isBlackList="false" isMultiLine="false" caseSensitive="false" fromSubscription="false"/><match enabled="true" name="" pattern="*You are not authorized to view this page*" isRegEx="false" isBlackList="false" isMultiLine="true" caseSensitive="false" fromSubscription="false"/></autoadd><quickadd enabled="false" temp="false" reload="true" notify="true" notifyWhenCanceled="true" prompt="true"><match enabled="true" name="Dynamic QuickAdd Pattern" pattern="*://${3}${6}/*" isRegEx="false" isBlackList="false" isMultiLine="false" caseSensitive="false" fromSubscription="false"/></quickadd><defaultPrefs origPrefetch="null"/><proxies>' > $file
  echo -ne '<proxy name="localhost:8080" id="1145138293" notes="e.g. Burp, w3af" fromSubscription="false" enabled="true" mode="manual" selectedTabIndex="0" lastresort="false" animatedIcons="true" includeInCycle="false" color="#07753E" proxyDNS="true" noInternalIPs="false" autoconfMode="pac" clearCacheBeforeUse="true" disableCache="true" clearCookiesBeforeUse="false" rejectCookies="false"><matches/><autoconf url="" loadNotification="true" errorNotification="true" autoReload="false" reloadFreqMins="60" disableOnBadPAC="true"/><autoconf url="http://wpad/wpad.dat" loadNotification="true" errorNotification="true" autoReload="false" reloadFreqMins="60" disableOnBadPAC="true"/><manualconf host="127.0.0.1" port="8080" socksversion="5" isSocks="false" username="" password="" domain=""/></proxy>' >> $file
  echo -ne '<proxy name="localhost:8081 (socket5)" id="212586674" notes="e.g. SSH" fromSubscription="false" enabled="true" mode="manual" selectedTabIndex="0" lastresort="false" animatedIcons="true" includeInCycle="false" color="#917504" proxyDNS="true" noInternalIPs="false" autoconfMode="pac" clearCacheBeforeUse="true" disableCache="true" clearCookiesBeforeUse="false" rejectCookies="false"><matches/><autoconf url="" loadNotification="true" errorNotification="true" autoReload="false" reloadFreqMins="60" disableOnBadPAC="true"/><autoconf url="http://wpad/wpad.dat" loadNotification="true" errorNotification="true" autoReload="false" reloadFreqMins="60" disableOnBadPAC="true"/><manualconf host="127.0.0.1" port="8081" socksversion="5" isSocks="true" username="" password="" domain=""/></proxy>' >> $file
  echo -ne '<proxy name="No Caching" id="3884644610" notes="" fromSubscription="false" enabled="true" mode="system" selectedTabIndex="0" lastresort="false" animatedIcons="true" includeInCycle="false" color="#990DA6" proxyDNS="true" noInternalIPs="false" autoconfMode="pac" clearCacheBeforeUse="true" disableCache="true" clearCookiesBeforeUse="false" rejectCookies="false"><matches/><autoconf url="" loadNotification="true" errorNotification="true" autoReload="false" reloadFreqMins="60" disableOnBadPAC="true"/><autoconf url="http://wpad/wpad.dat" loadNotification="true" errorNotification="true" autoReload="false" reloadFreqMins="60" disableOnBadPAC="true"/><manualconf host="" port="" socksversion="5" isSocks="false" username="" password="" domain=""/></proxy>' >> $file
  echo -ne '<proxy name="Default" id="3377581719" notes="" fromSubscription="false" enabled="true" mode="direct" selectedTabIndex="0" lastresort="true" animatedIcons="false" includeInCycle="true" color="#0055E5" proxyDNS="true" noInternalIPs="false" autoconfMode="pac" clearCacheBeforeUse="false" disableCache="false" clearCookiesBeforeUse="false" rejectCookies="false"><matches><match enabled="true" name="All" pattern="*" isRegEx="false" isBlackList="false" isMultiLine="false" caseSensitive="false" fromSubscription="false"/></matches><autoconf url="" loadNotification="true" errorNotification="true" autoReload="false" reloadFreqMins="60" disableOnBadPAC="true"/><autoconf url="http://wpad/wpad.dat" loadNotification="true" errorNotification="true" autoReload="false" reloadFreqMins="60" disableOnBadPAC="true"/><manualconf host="" port="" socksversion="5" isSocks="false" username="" password=""/></proxy>' >> $file
  echo -e '</proxies></foxyproxy>' >> $file
fi
#--- Wipe session (due to force close)
find /root/.mozilla/firefox/*.default*/ -maxdepth 1 -type f -name 'sessionstore.*' -delete
#--- Restore to folder
cd - &>/dev/null
#--- Remove any leftovers
rm -f /tmp/iceweasel.sql /tmp/bookmarks_new.html


##### Installing conky
echo -e "\n\e[01;32m[+]\e[00m Installing conky ~ GUI desktop monitor"
apt-get -y -qq install conky
#--- Configure conky
file=/root/.conkyrc; [ -e $file ] && cp -n $file{,.bkup}
cat <<EOF > $file
## Useful: http://forums.opensuse.org/english/get-technical-help-here/how-faq-forums/unreviewed-how-faq/464737-easy-configuring-conky-conkyconf.html
background yes

font Monospace:size=8:weight=bold
use_xft yes

update_interval 2.0

own_window yes
own_window_type normal
own_window_transparent yes
own_window_class conky-semi
own_window_argb_visual yes   # GNOME & XFCE yes, KDE no
own_window_colour brown
own_window_hints undecorated,below,sticky,skip_taskbar,skip_pager

double_buffer yes
maximum_width 260

draw_shades yes
draw_outline no
draw_borders no

stippled_borders 3
#border_margin 9   # Old command
border_inner_margin 9
border_width 10

default_color grey

alignment bottom_right
#gap_x 55   # KDE
#gap_x 0    # GNOME
gap_x 5
gap_y 0

uppercase no
use_spacer right

TEXT
\${color dodgerblue3}SYSTEM \${hr 2}\$color
#\${color white}\${time %A},\${time %e} \${time %B} \${time %G}\${alignr}\${time %H:%M:%S}
\${color white}Host\$color: \$nodename  \${alignr}\${color white}Uptime\$color: \$uptime

\${color dodgerblue3}CPU \${hr 2}\$color
#\${font Arial:bold:size=8}\${execi 99999 grep "model name" -m1 /proc/cpuinfo | cut -d":" -f2 | cut -d" " -f2- | sed "s#Processor ##"}\$font\$color
\${color white}MHz\$color: \${freq} \${alignr}\${color white}Load\$color: \${exec uptime | awk -F "load average: "  '{print \$2}'}
\${color white}Tasks\$color: \$running_processes/\$processes \${alignr}\${color white}CPU0\$color: \${cpu cpu0}% \${color white}CPU1\$color: \${cpu cpu1}%
#\${color #c0ff3e}\${acpitemp}C
#\${execi 20 sensors |grep "Core0 Temp" | cut -d" " -f4}\$font\$color\${alignr}\${freq_g 2} \${execi 20 sensors |grep "Core1 Temp" | cut -d" " -f4}
\${cpugraph cpu0 25,120 000000 white} \${alignr}\${cpugraph cpu1 25,120 000000 white}
\${color white}\${cpubar cpu1 3,120} \${alignr}\${color white}\${cpubar cpu2 3,120}\$color

\${color dodgerblue3}PROCESSES \${hr 2}\$color
\${color white}NAME             PID     CPU     MEM
\${color white}\${top name 1}\${top pid 1}  \${top cpu 1}  \${top mem 1}\$color
\${top name 2}\${top pid 2}  \${top cpu 2}  \${top mem 2}
\${top name 3}\${top pid 3}  \${top cpu 3}  \${top mem 3}
\${top name 4}\${top pid 4}  \${top cpu 4}  \${top mem 4}
\${top name 5}\${top pid 5}  \${top cpu 5}  \${top mem 5}

\${color dodgerblue3}MEMORY & SWAP \${hr 2}\$color
\${color white}RAM\$color   \$memperc%  \${membar 6}\$color
\${color white}Swap\$color   \$swapperc%  \${swapbar 6}\$color

\${color dodgerblue3}FILESYSTEM \${hr 2}\$color
\${color white}root\$color \${fs_free_perc /}% free\${alignr}\${fs_free /}/ \${fs_size /}
\${fs_bar 3 /}\$color
#\${color white}home\$color \${fs_free_perc /home}% free\${alignr}\${fs_free /home}/ \${fs_size /home}
#\${fs_bar 3 /home}\$color

\${color dodgerblue3}LAN eth0 (\${addr eth0}) \${hr 2}\$color
\${color white}Down\$color:  \${downspeed eth0} KB/s\${alignr}\${color white}Up\$color: \${upspeed eth0} KB/s
\${color white}Downloaded\$color: \${totaldown eth0} \${alignr}\${color white}Uploaded\$color: \${totalup eth0}
\${downspeedgraph eth0 25,120 000000 00ff00} \${alignr}\${upspeedgraph eth0 25,120 000000 ff0000}\$color
EOF
ifconfig eth1 &>/devnull && cat <<EOF >> $file
\${color dodgerblue3}LAN eth1 (\${addr eth1}) \${hr 2}\$color
\${color white}Down\$color:  \${downspeed eth1} KB/s\${alignr}\${color white}Up\$color: \${upspeed eth1} KB/s
\${color white}Downloaded\$color: \${totaldown eth1} \${alignr}\${color white}Uploaded\$color: \${totalup eth1}
\${downspeedgraph eth1 25,120 000000 00ff00} \${alignr}\${upspeedgraph eth1 25,120 000000 ff0000}\$color
EOF
cat <<EOF >> $file
\${color dodgerblue3}Wi-Fi (\${addr wlan0}) \${hr 2}\$color
\${color white}Down\$color:  \${downspeed wlan0} KB/s\${alignr}\${color white}Up\$color: \${upspeed wlan0} KB/s
\${color white}Downloaded\$color: \${totaldown wlan0} \${alignr}\${color white}Uploaded\$color: \${totalup wlan0}
\${downspeedgraph wlan0 25,120 000000 00ff00} \${alignr}\${upspeedgraph wlan0 25,120 000000 ff0000}\$color

\${color dodgerblue3}CONNECTIONS \${hr 2}\$color
\${color white}Inbound: \$color\${tcp_portmon 1 32767 count}  \${alignc}\${color white}Outbound: \$color\${tcp_portmon 32768 61000 count}\${alignr}\${color white}Total: \$color\${tcp_portmon 1 65535 count}
\${color white}Inbound \${alignr}Local Service/Port\$color
\$color \${tcp_portmon 1 32767 rhost 0} \${alignr}\${tcp_portmon 1 32767 lservice 0}
\$color \${tcp_portmon 1 32767 rhost 1} \${alignr}\${tcp_portmon 1 32767 lservice 1}
\$color \${tcp_portmon 1 32767 rhost 2} \${alignr}\${tcp_portmon 1 32767 lservice 2}
\${color white}Outbound \${alignr}Remote Service/Port\$color
\$color \${tcp_portmon 32768 61000 rhost 0} \${alignr}\${tcp_portmon 32768 61000 rservice 0}
\$color \${tcp_portmon 32768 61000 rhost 1} \${alignr}\${tcp_portmon 32768 61000 rservice 1}
\$color \${tcp_portmon 32768 61000 rhost 2} \${alignr}\${tcp_portmon 32768 61000 rservice 2}
EOF
#--- Add to startup (each login)
file=/usr/local/bin/conky.sh; [ -e $file ] && cp -n $file{,.bkup}
echo -e '#!/bin/bash\n\ntimeout 10 killall -q conky\nsleep 15\nconky &' > $file
chmod -f 0500 $file
mkdir -p /root/.config/autostart/
file=/root/.config/autostart/conkyscript.sh.desktop; [ -e $file ] && cp -n $file{,.bkup}
cat <<EOF > $file
[Desktop Entry]
Type=Application
Exec=/usr/local/bin/conky.sh
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name[en_US]=conky
Name=conky
Comment[en_US]=
Comment=
EOF
#--- Run now
#bash /usr/local/bin/conky.sh


##### Configuring metasploit ~ http://docs.kali.org/general-use/starting-metasploit-framework-in-kali
echo -e "\n\e[01;32m[+]\e[00m Configuring metasploit ~ exploit framework"
#--- Start services
service postgresql start
service metasploit start
#--- Add to start up
#update-rc.d postgresql enable
#update-rc.d metasploit enable
#--- Misc
export GOCOW=1   # Always a cow logo ;)
file=/root/.bashrc; [ -e $file ] && cp -n $file{,.bkup}
grep -q '^GOCOW' $file 2>/dev/null || echo 'GOCOW=1' >> $file
#--- Metasploit 4.10.x+ database fix #1 ~ https://community.rapid7.com/community/metasploit/blog/2014/08/25/not-reinventing-the-wheel
mkdir -p /root/.msf4/
ln -sf /opt/metasploit/apps/pro/ui/config/database.yml /root/.msf4/database.yml   #cp -f   #find / -name database.yml -type f | grep metasploit | grep -v gems   # /usr/share/metasploit-framework/config/database.yml
#--- Metasploit 4.10.x+ database fix #2 ~ Using method #1, so this isn't needed
#file=/root/.bash_aliases; [ -e $file ] && cp -n $file{,.bkup}   #/etc/bash.bash_aliasesa
#grep -q '^alias msfconsole' $file 2>/dev/null || echo -e '## Metasploit Framework\nalias msfconsole="msfconsole db_connect -y /opt/metasploit/apps/pro/ui/config/database.yml"\n\n' >> $file
#--- Apply new alias
[ $SHELL == "/bin/zsh" ] && source ~/.zshrc || source $file
#--- First time run
echo -e 'sleep 10\ndb_rebuild_cache\nsleep 300\nexit' > /tmp/msf.rc   #echo -e 'go_pro' > /tmp/msf.rc
msfconsole -r /tmp/msf.rc
#--- Setup GUI
#bash /opt/metasploit/scripts/launchui.sh    #*** Doesn't automate. Takes a little while to kick in...
#xdg-open https://127.0.0.1:3790/
#--- Remove any leftovers
rm -f /tmp/msf.rc


##### Installing geany
echo -e "\n\e[01;32m[+]\e[00m Installing geany ~ GUI text editor"
apt-get -y -qq install geany
#--- Add to panel
dconf load /org/gnome/gnome-panel/layout/objects/geany/ << EOF
[instance-config]
location='/usr/share/applications/geany.desktop'

[/]
object-iid='PanelInternalFactory::Launcher'
pack-index=3
pack-type='start'
toplevel-id='top-panel'
EOF
dconf write /org/gnome/gnome-panel/layout/object-id-list "$(dconf read /org/gnome/gnome-panel/layout/object-id-list | sed "s/]/, 'geany']/")"
#--- Configure geany
export DISPLAY=:0.0   #[[ -z $SSH_CONNECTION ]] || export DISPLAY=:0.0
timeout 15 geany   #geany & sleep 5; killall -q -w geany >/dev/null   # Start and kill. Files needed for first time run
# Geany -> Edit -> Preferences. Editor -> Newline strips trailing spaces: Enable. -> Indentation -> Type: Spaces. -> Files -> Strip trailing spaces and tabs: Enable. Replace tabs by space: Enable. -> Apply -> Ok
file=/root/.config/geany/geany.conf; [ -e $file ] && cp -n $file{,.bkup}
sed -i 's/^.*indent_type.*/indent_type=0/' $file     # Spaces over tabs
sed -i 's/^.*pref_editor_newline_strip.*/pref_editor_newline_strip=true/' $file
sed -i 's/^.*pref_editor_replace_tabs.*/pref_editor_replace_tabs=true/' $file
sed -i 's/^.*pref_editor_trail_space.*/pref_editor_trail_space=true/' $file
sed -i 's/^check_detect_indent=.*/check_detect_indent=true/' $file
sed -i 's/^pref_editor_ensure_convert_line_endings=.*/pref_editor_ensure_convert_line_endings=true/' $file
# Geany -> Tools -> Plugin Manger -> Save Actions -> HTML Characters: Enabled. Split Windows: Enabled. Save Actions: Enabled. -> Preferences -> Backup Copy -> Enable -> Directory to save backup files in: /root/backups/geany/. Directory levels to include in the backup destination: 5 -> Apply -> Ok -> Ok
sed -i 's#^.*active_plugins.*#active_plugins=/usr/lib/geany/htmlchars.so;/usr/lib/geany/saveactions.so;/usr/lib/geany/splitwindow.so;#' $file
mkdir -p /root/backups/geany/
mkdir -p /root/.config/geany/plugins/saveactions/
file=/root/.config/geany/plugins/saveactions/saveactions.conf; [ -e $file ] && cp -n $file{,.bkup}
cat <<EOF > $file
[saveactions]
enable_autosave=false
enable_instantsave=false
enable_backupcopy=true

[autosave]
print_messages=false
save_all=false
interval=300

[instantsave]
default_ft=None

[backupcopy]
dir_levels=5
time_fmt=%Y-%m-%d-%H-%M-%S
backup_dir=/root/backups/geany
EOF


##### Installing meld
echo -e "\n\e[01;32m[+]\e[00m Installing meld ~ GUI text compare"
apt-get -y -qq install meld
#--- Configure meld
gconftool-2 --type bool --set /apps/meld/show_line_numbers true
gconftool-2 --type bool --set /apps/meld/show_whitespace true
gconftool-2 --type bool --set /apps/meld/use_syntax_highlighting true
gconftool-2 --type int --set /apps/meld/edit_wrap_lines 2


##### Installing bless
echo -e "\n\e[01;32m[+]\e[00m Installing bless ~ GUI hex editor"
apt-get -y -qq install bless


##### Installing nessus
#echo -e "\n\e[01;32m[+]\e[00m Installing nessus ~ vulnerability scanner"
#--- Get download link
#xdg-open http://www.tenable.com/products/nessus/select-your-operating-system    *** #wget -q "http://downloads.nessus.org/<file>" -O /usr/local/src/nessus.deb   #***!!! Hardcoded version value
#dpkg -i /usr/local/src/Nessus-*-debian6_*.deb
#service nessusd start
#xdg-open http://www.tenable.com/products/nessus-home
#/opt/nessus/sbin/nessus-adduser   #*** Doesn't automate
##rm -f /usr/local/src/Nessus-*-debian6_*.deb
#--- Check email
# /opt/nessus/bin/nessus-fetch --register <key>   #*** Doesn't automate
#xdg-open https://127.0.0.1:8834/
#--- Remove from start up
#update-rc.d -f nessusd remove


##### Installing openvas
echo -e "\n\e[01;32m[+]\e[00m Installing openvas ~ vulnerability scanner"
apt-get -y -qq install openvas
#openvas-setup   #*** Doesn't automate
#--- Remove 'default' user (admin), and create a new admin user (root).
#test -e /var/lib/openvas/users/admin && openvasad -c remove_user -n admin
#test -e /var/lib/openvas/users/root || openvasad -c add_user -n root -r Admin   #*** Doesn't automate


##### Configuring burp suite
echo -e "\n\e[01;32m[+]\e[00m Configuring burp suite ~ web application proxy"
mkdir -p /root/.java/.userPrefs/burp/
file=/root/.java/.userPrefs/burp/prefs.xml;   #[ -e $file ] && cp -n $file{,.bkup}
[ -e $file ] || cat <<EOF > $file
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<!DOCTYPE map SYSTEM "http://java.sun.com/dtd/preferences.dtd" >
<map MAP_XML_VERSION="1.0">
  <entry key="eulafree" value="2"/>
  <entry key="free.suite.feedbackReportingEnabled" value="false"/>
</map>
EOF
#--- Extract CA
find /tmp/ -maxdepth 1 -name 'burp*.tmp' -delete
export DISPLAY=:0.0   #[[ -z $SSH_CONNECTION ]] || export DISPLAY=:0.0
timeout 60 burpsuite &
PID=$!
sleep 10
#echo "-----BEGIN CERTIFICATE-----" > /tmp/PortSwiggerCA && grep caCert /root/.java/.userPrefs/burp/prefs.xml | awk -F '"' '{print $4}' | fold -w 64 >> /tmp/PortSwiggerCA && echo "-----END CERTIFICATE-----" >> /tmp/PortSwiggerCA
export http_proxy="http://127.0.0.1:8080"
rm -f /tmp/burp.crt
while test -d /proc/$PID; do
  sleep 1
  curl --progress -k -L http://burp/cert -o /tmp/burp.crt 2>/dev/null
  [ -f /tmp/burp.crt ] && break
done
timeout 5 kill $PID 2>/dev/null
unset http_proxy
#--- Installing CA
if [ -f /tmp/burp.crt ]; then
  apt-get -y -qq install libnss3-tools
  folder=$(find /root/.mozilla/firefox/ -maxdepth 1 -type d -name '*.default' -print -quit)
  certutil -A -n Burp -t "CT,c,c" -d $folder -i /tmp/burp.crt
  timeout 15 iceweasel
  #mkdir -p /usr/share/ca-certificates/burp/
  #cp -f /tmp/burp.crt /usr/share/ca-certificates/burp/
  #dpkg-reconfigure ca-certificates
  #cp -f /tmp/burp.crt /root/Desktop/burp.crt
else
  echo -e '\e[01;31m[!]\e[00m Didnt extract burp suite Certificate Authority (CA). Skipping...'
fi
#--- Remove any leftovers
sleep 1
find /tmp/ -maxdepth 1 -name 'burp*.tmp' -delete
find /root/.mozilla/firefox/*.default*/ -maxdepth 1 -type f -name 'sessionstore.*' -delete
rm -f /tmp/burp.crt
unset http_proxy


##### Installing sparta
echo -e "\n\e[01;32m[+]\e[00m Installing sparta ~ GUI automatic wrapper"
apt-get -y -qq install git
git clone git://github.com/secforce/sparta.git /usr/share/sparta_git/
cd /usr/share/sparta_git/ && git pull
cd - &>/dev/null
file=/usr/local/bin/sparta_git
cat <<EOF > $file
#!/bin/bash

cd /usr/share/sparta_git/ && ./sparta.py "\$@"
EOF
chmod +x $file


##### Configuring wireshark
echo -e "\n\e[01;32m[+]\e[00m Configuring wireshark ~ GUI network protocol analyzer"
mkdir -p /root/.wireshark/
file=/root/.wireshark/recent_common;   #[ -e $file ] && cp -n $file{,.bkup}
[ -e $file ] || echo "privs.warn_if_elevated: FALSE" > $file


##### Installing vfeed
echo -e "\n\e[01;32m[+]\e[00m Installing vfeed ~ vulnerability database"
apt-get -y -qq install vfeed


##### Installing checksec
echo -e "\n\e[01;32m[+]\e[00m Installing checksec ~ check *nix OS for security features"
apt-get -y -qq install wget
mkdir -p /usr/share/checksec/
file=/usr/share/checksec/checksec.sh
wget -q "http://www.trapkit.de/tools/checksec.sh" -O $file
chmod +x $file


##### Installing rips
echo -e "\n\e[01;32m[+]\e[00m Installing rips ~ source code review"
apt-get -y -qq install apache2 php5 wget
mkdir -p /usr/share/rips/
wget -q "http://downloads.sourceforge.net/project/rips-scanner/rips-0.54.zip" -O /tmp/rips.zip && unzip -q -o -d /usr/share/rips/ /tmp/rips.zip; rm -f /tmp/rips.zip
file=/etc/apache2/conf.d/rips.conf
cat <<EOF > $file
Alias /rips /usr/share/rips

<Directory /usr/share/rips/ >
  Options FollowSymLinks
  AllowOverride None
  Order deny,allow
  Deny from all
  Allow from 127.0.0.0/255.0.0.0 ::1/128
</Directory>
EOF
service apache2 restart


##### Installing libreoffice
echo -e "\n\e[01;32m[+]\e[00m Installing libreoffice ~ GUI office suite"
apt-get -y -qq install libreoffice


##### Installing cherrytree
echo -e "\n\e[01;32m[+]\e[00m Installing cherrytree ~ GUI note taking"
apt-get -y -qq install cherrytree


##### Installing sipcalc
echo -e "\n\e[01;32m[+]\e[00m Installing sipcalc ~ CLI subnet calculator"
apt-get -y -qq install sipcalc


##### Installing recordmydesktop
echo -e "\n\e[01;32m[+]\e[00m Installing recordmydesktop ~ GUI video screen capture"
apt-get -y -qq install recordmydesktop
#--- Installing GUI front end
apt-get -y -qq install gtk-recordmydesktop


##### Installing gimp
#echo -e "\n\e[01;32m[+]\e[00m Installing gimp ~ GUI image editing"
#apt-get -y -qq install gimp


##### Installing shutter
echo -e "\n\e[01;32m[+]\e[00m Installing shutter ~ GUI still screen capture"
apt-get -y -qq install shutter


##### Installing gdebi
echo -e "\n\e[01;32m[+]\e[00m Installing gdebi ~ GUI package installer"
apt-get -y -qq install gdebi


##### Installing psmisc ~ allows for 'killall command' to be used
echo -e "\n\e[01;32m[+]\e[00m Installing psmisc ~ tools to help with running processes"
apt-get -y -qq install psmisc


##### Installing midnight commander
#echo -e "\n\e[01;32m[+]\e[00m Installing midnight commander ~ CLI file manager"
#apt-get -y -qq install mc


##### Installing htop
echo -e "\n\e[01;32m[+]\e[00m Installing htop ~ CLI process viewer"
apt-get -y -qq install htop


##### Installing iotop
echo -e "\n\e[01;32m[+]\e[00m Installing iotop ~ CLI I/O usage"
apt-get -y -qq install iotop


##### Installing glance
#echo -e "\n\e[01;32m[+]\e[00m Installing glance ~ CLI process viewer"
#apt-get -y -qq install glance


##### Installing axel
echo -e "\n\e[01;32m[+]\e[00m Installing axel ~ CLI download manager"
apt-get -y -qq install axel
#--- Setup alias
file=/root/.bash_aliases; [ -e $file ] && cp -n $file{,.bkup}   #/etc/bash.bash_aliases
grep -q '^alias axel' $file 2>/dev/null || echo -e '## axel\nalias axel="axel -a"\n\n' >> $file
#--- Apply new aliases
[ $SHELL == "/bin/zsh" ] && source ~/.zshrc || source $file


##### Installing gparted
echo -e "\n\e[01;32m[+]\e[00m Installing gparted ~ GUI partition manager"
apt-get -y -qq install gparted


##### Installing daemonfs
echo -e "\n\e[01;32m[+]\e[00m Installing daemonfs ~ GUI file monitor"
apt-get -y -qq install daemonfs


##### Installing filezilla
echo -e "\n\e[01;32m[+]\e[00m Installing filezilla ~ GUI file transfer"
apt-get -y -qq install filezilla
#--- Configure filezilla
export DISPLAY=:0.0   #[[ -z $SSH_CONNECTION ]] || export DISPLAY=:0.0
timeout 15 filezilla   #filezilla & sleep 5; killall -q -w filezilla >/dev/null     # Start and kill. Files needed for first time run
file=/root/.filezilla/filezilla.xml; [ -e $file ] && cp -n $file{,.bkup}
sed -i 's#^.*"Default editor".*#\t<Setting name="Default editor" type="string">2/usr/bin/geany</Setting>#' $file


##### Installing remmina
echo -e "\n\e[01;32m[+]\e[00m Installing remmina ~ GUI remote desktop"
apt-get -y -qq install remmina


##### Installing x2go client
echo -e "\n\e[01;32m[+]\e[00m Installing x2go client ~ GUI remote desktop"
apt-get -y -qq install x2goclient


##### Setting up tftp client & server
echo -e "\n\e[01;32m[+]\e[00m Setting up tftp client & server ~ file transfer methods"
apt-get -y -qq install tftp      # tftp client
apt-get -y -qq install atftpd    # tftp Server
#--- Configure atftpd
file=/etc/default/atftpd; [ -e $file ] && cp -n $file{,.bkup}
echo -e 'USE_INETD=false\nOPTIONS="--tftpd-timeout 300 --retry-timeout 5 --maxthread 100 --verbose=5 --daemon --port 69 /var/tftp"' > $file
mkdir -p /var/tftp/
chown -R nobody\:root /var/tftp/
chmod -R 0755 /var/tftp/
#--- Remove from start up
update-rc.d -f atftpd remove
#--- Disabling IPv6 can help
#echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6
#echo 1 > /proc/sys/net/ipv6/conf/default/disable_ipv6


##### Installing pure-ftpd
echo -e "\n\e[01;32m[+]\e[00m Installing pure-ftpd ~ FTP server/file transfer method"
apt-get -y -qq install pure-ftpd
#--- Setup pure-ftpd
mkdir -p /var/ftp/
groupdel ftpgroup 2>/dev/null; groupadd ftpgroup
userdel ftp 2>/dev/null; useradd -d /var/ftp/ -s /bin/false -c "FTP user" -g ftpgroup ftp
chown -R ftp\:ftpgroup /var/ftp/
chmod -R 0755 /var/ftp/
pure-pw userdel ftp 2>/dev/null; echo -e '\n' | pure-pw useradd ftp -u ftp -d /var/ftp/
pure-pw mkdb
#--- Configure pure-ftpd
echo "no" > /etc/pure-ftpd/conf/UnixAuthentication
echo "no" > /etc/pure-ftpd/conf/PAMAuthentication
echo "yes" > /etc/pure-ftpd/conf/NoChmod
echo "yes" > /etc/pure-ftpd/conf/ChrootEveryone
#echo "yes" > /etc/pure-ftpd/conf/AnonymousOnly
echo "no" > /etc/pure-ftpd/conf/NoAnonymous
echo "yes" > /etc/pure-ftpd/conf/AnonymousCanCreateDirs
echo "yes" > /etc/pure-ftpd/conf/AllowAnonymousFXP
echo "no" > /etc/pure-ftpd/conf/AnonymousCantUpload
#mkdir -p /etc/ssl/private/
#openssl req -x509 -nodes -newkey rsa:4096 -keyout /etc/ssl/private/pure-ftpd.pem -out /etc/ssl/private/pure-ftpd.pem
#chmod -f 0600 /etc/ssl/private/*.pem
ln -sf /etc/pure-ftpd/conf/PureDB /etc/pure-ftpd/auth/50pure
#--- Remove from start up
update-rc.d -f pure-ftpd remove


##### Installing lynx
echo -e "\n\e[01;32m[+]\e[00m Installing lynx ~ CLI web browser"
apt-get -y -qq install lynx


##### Installing p7zip
echo -e "\n\e[01;32m[+]\e[00m Installing p7zip ~ CLI file extractor"
apt-get -y -qq install p7zip-full


##### Installing zip & unzip
echo -e "\n\e[01;32m[+]\e[00m Installing zip & unzip ~ CLI file extractors"
apt-get -y -qq install zip      # Compress
apt-get -y -qq install unzip    # Decompress


##### Installing file roller
echo -e "\n\e[01;32m[+]\e[00m Installing file roller ~ GUI file extractor"
apt-get -y -qq install file-roller                                            # gui program
apt-get -y -qq install unace unrar rar unzip zip p7zip p7zip-full p7zip-rar   # supported file compressions


##### Installing PPTP VPN support
echo -e "\n\e[01;32m[+]\e[00m Installing PPTP VPN support"
apt-get -y -qq install network-manager-pptp-gnome network-manager-pptp


##### Installing flash
echo -e "\n\e[01;32m[+]\e[00m Installing flash ~ multimedia web plugin"
apt-get -y -qq install flashplugin-nonfree
update-flashplugin-nonfree --install


##### Installing java
#echo -e "\n\e[01;32m[+]\e[00m Installing java ~ web plugin"
#*** Insert bash fu here


##### Installing hashid
echo -e "\n\e[01;32m[+]\e[00m Installing hashid ~ identify hash types"
apt-get -y -qq install hashid


##### Installing bully
echo -e "\n\e[01;32m[+]\e[00m Installing bully ~ WPS pin brute force"
apt-get -y -qq install bully


##### Installing httprint
echo -e "\n\e[01;32m[+]\e[00m Installing httprint ~ GUI web server fingerprint"
apt-get -y -qq install httprint


##### Installing lbd
echo -e "\n\e[01;32m[+]\e[00m Installing lbd ~ load balancing detector"
apt-get -y -qq install lbd


##### Installing wafw00f
echo -e "\n\e[01;32m[+]\e[00m Installing wafw00f ~ WAF detector"
apt-get -y -qq install git python python-pip
git clone git://github.com/sandrogauci/wafw00f.git /usr/share/wafw00f_git/
cd /usr/share/wafw00f_git/
git pull
python setup.py install
cd - &>/dev/null


##### Installing unicornscan
echo -e "\n\e[01;32m[+]\e[00m Installing unicornscan ~ fast port scanner"
apt-get -y -qq install unicornscan


##### Installing onetwopunch
echo -e "\n\e[01;32m[+]\e[00m Installing onetwopunch ~ unicornscan & nmap wrapper"
apt-get -y -qq install git nmap unicornscan
git clone git://github.com/superkojiman/onetwopunch.git /usr/share/onetwopunch_git/
cd /usr/share/onetwopunch_git/ && git pull
cd - &>/dev/null
file=/usr/local/bin/onetwopunch
cat <<EOF > $file
#!/bin/bash

cd /usr/share/onetwopunch_git/ && ./onetwopunch.sh "\$@"
EOF
chmod +x $file


##### Installing clusterd
echo -e "\n\e[01;32m[+]\e[00m Installing clusterd ~ clustered attack toolkit (jboss, coldfusion, weblogic, tomcat etc)"
apt-get -y -qq install clusterd


##### Installing webhandler
echo -e "\n\e[01;32m[+]\e[00m Installing webhandler ~ shell TTY handler"
apt-get -y -qq install webhandler


##### Installing azazel
echo -e "\n\e[01;32m[+]\e[00m Installing azazel ~ linux userland rootkit"
apt-get -y -qq install git
git clone git://github.com/chokepoint/azazel.git /usr/share/azazel_git/
cd /usr/share/azazel_git/ && git pull
cd - &>/dev/null


##### Installing b374k
echo -e "\n\e[01;32m[+]\e[00m Installing b374k ~ (PHP) web shell"
apt-get -y -qq install git php5-cli
git clone git://github.com/b374k/b374k.git /usr/share/b374k_git/
cd /usr/share/b374k_git/
git pull
php index.php -o b374k.php -s
cd - &>/dev/null
ln -sf /usr/share/b374k_git /usr/share/webshells/php/b374k


##### Installing jsp file browser
echo -e "\n\e[01;32m[+]\e[00m Installing jsp file browser ~ (JSP) web shell"
wget -q "http://www.vonloesch.de/files/browser.zip" -O /tmp/jsp.zip && unzip -q -o -d /usr/share/webshells_jsp/ /tmp/jsp.zip; rm -f /tmp/jsp.zip


##### Installing htshells
echo -e "\n\e[01;32m[+]\e[00m Installing htshells ~ (htdocs/apache) web shells"
apt-get -y -qq install htshells


##### Installing bridge-utils
echo -e "\n\e[01;32m[+]\e[00m Installing bridge-utils ~ bridge network interfaces"
apt-get -y -qq install bridge-utils


##### Installing mana
echo -e "\n\e[01;32m[+]\e[00m Installing mana ~ rogue AP todo MITM Wi-Fi"
apt-get -y -qq install mana-toolkit
mkdir -p /usr/share/mana-toolkit/www/facebook/    #*** BUG FIX: https://bugs.kali.org/view.php?id=1839


##### Installing wifiphisher
echo -e "\n\e[01;32m[+]\e[00m Installing wifiphisher ~ automated WiFi phishing"
apt-get -y -qq install git
git clone git://github.com/sophron/wifiphisher.git /usr/share/wifiphisher_git/
cd /usr/share/wifiphisher_git/ && git pull
cd - &> /dev/null
file=/usr/local/bin/wifiphisher_git
cat <<EOF > $file
#!/bin/bash

cd /usr/share/wifiphisher_git/ && python wifiphisher.py "\$@"
EOF
chmod +x $file


##### Installing hostapd-wpe-extended
echo -e "\n\e[01;32m[+]\e[00m Installing hostapd-wpe-extended ~ rogue AP for WPA-Enterprise"
apt-get -y -qq install git
git clone git://github.com/NerdyProjects/hostapd-wpe-extended.git /usr/share/hostapd-wpe-extended_git/
cd /usr/share/hostapd-wpe-extended_git/ && git pull
cd - &> /dev/null


##### Installing httptunnel
echo -e "\n\e[01;32m[+]\e[00m Installing httptunnel ~ tunnels data streams in HTTP requests"
apt-get -y -qq install http-tunnel


##### Installing sshuttle
echo -e "\n\e[01;32m[+]\e[00m Installing sshuttle ~ proxy server for VPN over SSH"
apt-get -y -qq install sshuttle
#sshuttle --dns --remote root@123.9.9.9 0/0 -vv


##### Installing iodine
echo -e "\n\e[01;32m[+]\e[00m Installing iodine ~ DNS tunneling (IP over DNS)"
apt-get -y -qq install ptunnel
#iodined -f -P password1 10.0.0.1 dns.mydomain.com
#iodine -f -P password1 123.9.9.9 dns.mydomain.com; ssh -C -D 8081 root@10.0.0.1


##### Installing dns2tcp
echo -e "\n\e[01;32m[+]\e[00m Installing dns2tcp ~ DNS tunneling (TCP over DNS)"
apt-get -y -qq install dns2tcp
#file=/etc/dns2tcpd.conf; [ -e $file ] && cp -n $file{,.bkup}; echo -e "listen = 0.0.0.0\nport = 53\nuser = nobody\nchroot = /tmp\ndomain = dnstunnel.mydomain.com\nkey = password1\nressources = ssh:127.0.0.1:22" > $file; dns2tcpd -F -d 1 -f /etc/dns2tcpd.conf
#file=/etc/dns2tcpc.conf; [ -e $file ] && cp -n $file{,.bkup}; echo -e "domain = dnstunnel.mydomain.com\nkey = password1\nresources = ssh\nlocal_port = 8000\ndebug_level=1" > $file; dns2tcpc -f /etc/dns2tcpc.conf 178.62.206.227; ssh -C -D 8081 -p 8000 root@127.0.0.1


##### Installing ptunnel
echo -e "\n\e[01;32m[+]\e[00m Installing ptunnel ~ IMCP tunneling"
apt-get -y -qq install ptunnel
#ptunnel -x password1
#ptunnel -x password1 -p 123.9.9.9 -lp 8000 -da 127.0.0.1 -dp 22; ssh -C -D 8081 -p 8000 root@127.0.0.1


##### Installing zerofree
echo -e "\n\e[01;32m[+]\e[00m Installing zerofree ~ CLI nulls free blocks on a HDD"
apt-get -y -qq install zerofree
#fdisk -l
#zerofree -v /dev/sda1   #for i in $(mount | grep sda | grep ext | cut -b 9); do  mount -o remount,ro /dev/sda$i && zerofree -v /dev/sda$i && mount -o remount,rw /dev/sda$i; done


##### Installing gcc & multilib
echo -e "\n\e[01;32m[+]\e[00m Installing gcc & multilibc ~ compiling libraries"
apt-get -y -qq install gcc-multilib libc6 libc6-dev
#*** I know its messy...
apt-get -y -qq install libc6-amd64 libc6-dev-amd64
apt-get -y -qq install libc6-i386 libc6-dev-i386
apt-get -y -qq install libc6-i686 libc6-dev-i686


##### Installing mingw & cross compiling tools
echo -e "\n\e[01;32m[+]\e[00m Installing mingw & cross compiling tools"
apt-get -y -qq install mingw-w64 binutils-mingw-w64 gcc-mingw-w64 cmake
apt-get -y -qq install mingw-w64-dev mingw-w64-tools
apt-get -y -qq install gcc-mingw-w64-i686


##### Installing wine
echo -e "\n\e[01;32m[+]\e[00m Installing wine ~ run windows programs on *nix"
apt-get -y -qq install wine
#--- x64?
if [[ "$(uname -m)" == 'x86_64' ]]; then
  echo -e "\e[01;32m[+]\e[00m Configuring wine for x64"
  dpkg --add-architecture i386
  apt-get update
  apt-get -y -qq install wine-bin:i386
fi
#--- Run WINE for the first time
[ -e /usr/share/windows-binaries/whoami.exe ] && wine /usr/share/windows-binaries/whoami.exe &>/dev/null


##### Installing the backdoor factory
echo -e "\n\e[01;32m[+]\e[00m Installing backdoor factory ~ bypassing anti-virus"
apt-get -y -qq install backdoor-factory


##### Installing the Backdoor Factory Proxy (BDFProxy)
echo -e "\n\e[01;32m[+]\e[00m Installing backdoor factory ~ patches binaries files via MITM"
apt-get -y -qq install git
git clone git://github.com/secretsquirrel/BDFProxy.git /usr/share/bdfproxy_git/
cd /usr/share/bdfproxy_git/ && git pull
cd - &>/dev/null


##### Installing veil framework
echo -e "\n\e[01;32m[+]\e[00m Installing veil framework ~ bypassing anti-virus"
apt-get -y -qq install veil


##### Installing OP packers
echo -e "\n\e[01;32m[+]\e[00m Installing OP packers ~ bypassing anti-virus"
apt-get -y -qq install upx-ucl   #wget -q "http://upx.sourceforge.net/download/upx309w.zip" -P /usr/share/packers/ && unzip -q -o -d /usr/share/packers/ /usr/share/packers/upx309w.zip; rm -f /usr/share/packers/upx309w.zip
mkdir -p /usr/share/packers/
wget -q "http://www.eskimo.com/~scottlu/win/cexe.exe" -P /usr/share/packers/
wget -q "http://www.farbrausch.de/~fg/kkrunchy/kkrunchy_023a2.zip" -P /usr/share/packers/ && unzip -q -o -d /usr/share/packers/ /usr/share/packers/kkrunchy_023a2.zip; rm -f /usr/share/packers/kkrunchy_023a2.zip
#*** Need to make a bash script like hyperion...


##### Installing hyperion
echo -e "\n\e[01;32m[+]\e[00m Installing hyperion ~ bypassing anti-virus"
unzip -q -o -d /usr/share/windows-binaries/ /usr/share/windows-binaries/Hyperion-1.0.zip
#rm -f /usr/share/windows-binaries/Hyperion-1.0.zip
i686-w64-mingw32-g++ -static-libgcc -static-libstdc++ /usr/share/windows-binaries/Hyperion-1.0/Src/Crypter/*.cpp -o /usr/share/windows-binaries/Hyperion-1.0/Src/Crypter/bin/crypter.exe
ln -sf /usr/share/windows-binaries/Hyperion-1.0/Src/Crypter/bin/crypter.exe /usr/share/windows-binaries/Hyperion-1.0/crypter.exe
file=/usr/local/bin/hyperion
cat <<EOF > $file
#!/bin/bash

## Note: This is far from perfect...

CWD=\$(pwd)/
BWD="?"

## Using full path?
[ -e "/\${1}" ] && BWD=""

## Using relative path?
[ -e "./\${1}" ] && BWD="\${CWD}"

## Can't find input file!
[[ "\${BWD}" == "?" ]] && echo -e '\e[01;31m[!]\e[00m Cant find \$1. Quitting...' && exit

## The magic!
cd /usr/share/windows-binaries/Hyperion-1.0/
$(which wine) ./Src/Crypter/bin/crypter.exe \${BWD}\${1} output.exe

## Restore our path
cd \${CWD}/
sleep 1

## Move the output file
mv -f /usr/share/windows-binaries/Hyperion-1.0/output.exe \${2}

## Generate file hashes
for FILE in \${1} \${2}; do
  echo "[i] \$(md5sum \${FILE})"
done
EOF
chmod +x $file


##### Installing fuzzdb
echo -e "\n\e[01;32m[+]\e[00m Installing fuzzdb ~ multiple types of (word)lists (and similar things)"
svn -q checkout http://fuzzdb.googlecode.com/svn/trunk/ /usr/share/fuzzdb/


##### Installing seclist
echo -e "\n\e[01;32m[+]\e[00m Installing seclist ~ multiple types of (word)lists (and similar things)"
apt-get -y -qq install seclists


##### Updating wordlists
echo -e "\n\e[01;32m[+]\e[00m Updating wordlists ~ collection of wordlists"
#--- Extract rockyou wordlist
[ -e /usr/share/wordlists/rockyou.txt.gz ] && gzip -dc < /usr/share/wordlists/rockyou.txt.gz > /usr/share/wordlists/rockyou.txt   #gunzip rockyou.txt.gz
#rm -f /usr/share/wordlists/rockyou.txt.gz
#--- Extract sqlmap wordlist
#unzip -o -d /usr/share/sqlmap/txt/ /usr/share/sqlmap/txt/wordlist.zip
#--- Add 10,000 Top/Worst/Common Passwords
mkdir -p /usr/share/wordlists/
wget -q "http://xato.net/files/10k most common.zip" -O /tmp/10kcommon.zip && unzip -q -o -d /usr/share/wordlists/ /tmp/10kcommon.zip && mv -f /usr/share/wordlists/10k{\ most\ ,_most_}common.txt; rm -f /tmp/10kcommon.zip
#--- Linking to more - folders
[ -e /usr/share/dirb/wordlists ] && ln -sf /usr/share/dirb/wordlists /usr/share/wordlists/dirb
#--- Linking to more - files
#ln -sf /usr/share/sqlmap/txt/wordlist.txt /usr/share/wordlists/sqlmap.txt
##--- Not enough? Want more? Check below!
##apt-cache search wordlist
##find / \( -iname '*wordlist*' -or -iname '*passwords*' \) #-exec ls -l {} \;


##### Installing apt-file
echo -e "\n\e[01;32m[+]\e[00m Installing apt-file ~ find which package includes a specific file"
apt-get -y -qq install apt-file
apt-file update


##### Installing sqlmap (GIT)
echo -e "\n\e[01;32m[+]\e[00m Installing sqlmap (GIT) ~ automatic SQL injection"
apt-get -y -qq install git
git clone git://github.com/sqlmapproject/sqlmap.git /usr/share/sqlmap_git/
cd /usr/share/sqlmap_git/ && git pull
cd - &>/dev/null
file=/usr/local/bin/sqlmap_git
cat <<EOF > $file
#!/bin/bash

cd /usr/share/sqlmap_git/ && ./sqlmap.py "\$@"
EOF
chmod +x $file


##### Installing Babel scripts
echo -e "\n\e[01;32m[+]\e[00m Installing Babel scripts ~ post exploitation scripts"
apt-get -y -qq install git
git clone git://github.com/attackdebris/babel-sf.git /usr/share/babel-sf_git/
cd /usr/share/babel-sf_git/ && git pull
cd - &>/dev/null


##### Installing python-pty-shells
echo -e "\n\e[01;32m[+]\e[00m Installing python-pty-shells ~ PTY shells"
apt-get -y -qq install git
git clone git://github.com/infodox/python-pty-shells.git /usr/share/python-pty-shells_git/
cd /usr/share/python-pty-shells_git/ && git pull
cd - &>/dev/null


##### Installing pwntools
echo -e "\n\e[01;32m[+]\e[00m Installing pwntools ~ handy CTF tools"
apt-get -y -qq install git
git clone git://github.com/Gallopsled/pwntools.git /usr/share/pwntools_git/
cd /usr/share/pwntools_git/ && git pull
cd - &>/dev/null


##### Installing CMSmap
echo -e "\n\e[01;32m[+]\e[00m Installing CMSmap ~ CMS detection"
apt-get -y -qq install git
git clone git://github.com/Dionach/CMSmap.git /usr/share/cmsmap_git/
file=/usr/local/bin/cmsmap_git
cat <<EOF > $file
#!/bin/bash

cd /usr/share/cmsmap_git/ && ./cmsmap.py "\$@"
EOF
chmod +x $file


##### Installing CMSScanner
#echo -e "\n\e[01;32m[+]\e[00m Installing CMSScanner ~ CMS detection"
#apt-get -y -qq install git
#git clone git://github.com/wpscanteam/CMSScanner.git /usr/share/cmsscanner_git/
#cd /usr/share/cmsscanner_git/
#git pull
#bundle install
#cd - &>/dev/null


##### Installing droopescan (GIT)
echo -e "\n\e[01;32m[+]\e[00m Installing droopescan (GIT) ~ Drupal vulnerability scanner"
apt-get -y -qq install git
git clone git://github.com/droope/droopescan.git /usr/share/droopescan_git/
cd /usr/share/droopescan_git/ && git pull
cd - &>/dev/null
file=/usr/local/bin/droopescan_git
cat <<EOF > $file
#!/bin/bash

cd /usr/share/droopescan_git/ && ./droopescan "\$@"
EOF
chmod +x $file


##### Installing wpscan (GIT)
echo -e "\n\e[01;32m[+]\e[00m Installing wpscan (GIT) ~ WordPress vulnerability scanner"
apt-get -y -qq install git
git clone git://github.com/wpscanteam/wpscan.git /usr/share/wpscan_git/
cd /usr/share/wpscan_git/ && git pull
cd - &>/dev/null
file=/usr/local/bin/wpscan_git
cat <<EOF > $file
#!/bin/bash

cd /usr/share/wpscan_git/ && ./wpscan.rb "\$@"
EOF
chmod +x $file


##### Configuring samba
echo -e "\n\e[01;32m[+]\e[00m Configuring samba ~ file transfer method"
#--- Installing samba
apt-get -y -qq install samba
#--- Create samba user
useradd -M -d /nonexistent -s /bin/false samba
#--- Use the samba user
file=/etc/samba/smb.conf; [ -e $file ] && cp -n $file{,.bkup}
sed -i 's/guest account = .*/guest account = samba/' $file 2>/dev/null || sed -i 's#\[global\]#\[global\]\n   guest account = samba#' $file
#--- Setup samba paths
grep -q '^\[shared\]' $file 2>/dev/null || cat <<EOF >> $file

[shared]
  comment = Shared
  path = /var/samba/
  browseable = yes
  read only = no
  guest ok = yes
EOF
#--- Create samba path and configure it
mkdir -p /var/samba/
chown -R samba\:samba /var/samba/
chmod -R 0770 /var/samba/
#--- Check result
#service samba restart
#smbclient -L \\127.0.0.1 -N
#--- Disable samba at startup
service samba stop
update-rc.d -f samba remove


##### Installing rsh-client
echo -e "\n\e[01;32m[+]\e[00m Installing rsh-client ~ remote shell connections"
apt-get -y -qq install rsh-client


##### Setting up SSH
echo -e "\n\e[01;32m[+]\e[00m Setting up SSH"
apt-get -y -qq install openssh-server
#--- Wipe current keys
rm -f /etc/ssh/ssh_host_*
rm -f /root/.ssh/*
#--- Generate new keys
#ssh-keygen -A   # Automatic method - we lose control of amount of bits used
ssh-keygen -b 4096 -t rsa1 -f /etc/ssh/ssh_host_key -P ""
ssh-keygen -b 4096 -t rsa -f /etc/ssh/ssh_host_rsa_key -P ""
ssh-keygen -b 1024 -t dsa -f /etc/ssh/ssh_host_dsa_key -P ""
ssh-keygen -b 521 -t ecdsa -f /etc/ssh/ssh_host_ecdsa_key -P ""
ssh-keygen -b 4096 -t rsa -f /root/.ssh/id_rsa -P ""
#--- Change SSH port
#file=/etc/ssh/sshd_config; [ -e $file ] && cp -n $file{,.bkup}
#sed -i 's/^Port .*/Port 2222/g' $file
#--- Enable ssh at startup
#update-rc.d -f ssh enable


##### Cleaning the system
echo -e "\n\e[01;32m[+]\e[00m Cleaning the system"
#--- Clean package manager
for FILE in clean autoremove autoclean; do apt-get -y -qq $FILE; done         # Clean up
apt-get -y purge $(dpkg -l | tail -n +6 | grep -v '^ii' | awk '{print $2}')   # Purged packages
#--- Update slocate database
updatedb
#--- Reset folder location
cd ~/ &>/dev/null
#--- Remove any history files (as they could contain sensitive info)
[ $SHELL == "/bin/zsh" ] || history -c
for i in $(cut -d: -f6 /etc/passwd | sort | uniq); do
  [ -e "$i" ] && find "$i" -type f -name '.*_history' -delete
done


##### Time (roughly) taken
finish_time=$(date +%s)
echo -e "\n\e[01;33m[i]\e[00m Time (roughly) taken: $(( $(( finish_time - start_time )) / 60 )) minutes"


#-Done--------------------------------------------------#


##### Done!
echo -e "\n\e[01;33m[i]\e[00m Do not forget to:"
echo -e "\e[01;33m[i]\e[00m   + Check the above output (everything installed/no errors?)"
echo -e "\e[01;33m[i]\e[00m   + Check that Iceweasel's extensions are enabled (as well as FoxyProxy profiles)"
echo -e "\e[01;33m[i]\e[00m   + Manually install: Nessus, Nexpose, Metasploit Community and/or OpenVAS"
echo -e "\e[01;33m[i]\e[00m   + Agree/Accept to: Maltego, OWASP ZAP, w3af etc"
echo -e "\e[01;33m[i]\e[00m   + Change time zone & keyboard layout (...if different to $timezone/$keyboardlayout)"
echo -e "\e[01;33m[i]\e[00m   + Reboot"
echo -e "\e[01;33m[i]\e[00m   + Take a snapshot (...if you are using a VM)"

echo -e '\n\e[01;34m[*]\e[00m Done!\n'
#reboot
exit 0
