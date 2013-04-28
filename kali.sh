#!/bin/sh
#Operating System(s)#######################
# Designed for: Kali Linux (GNOME)        #
#              [x64 & x86]                #
# Working on: 2013-04-27                  #
#Author####################################
# g0tmilk ~ http://g0tmi1k.blogspot.com   #
#Note######################################
# The script wasn't designed to be...     #
# ...execute. Copy & paste commands...    #
# ...into a ternminal window              #
###########################################

##### Remote configuration via SSH (Optional)
services ssh start         # Start SSH to allow for remote config
update-rc.d ssh enable     # Enable SSH at startup
ifconfig eth0              # Get IP of the interface
#--- Use 'remote' computer from here on out!
ssh root@<ip>        # Replace <ip> with the value from ifconfig
export DISPLAY=:0.0  # Allows for remote configuration


##### Fix Networkmanger: device not managed (Optional)
#sed -i 's/managed=.*/managed=true/' /etc/NetworkManager/NetworkManager.conf
if [ ! -e /etc/network/interfaces.bkup ]; then cp -f /etc/network/interfaces{,.bkup}; fi
sed -i '/iface lo inet loopback/q' /etc/network/interfaces    #sed '/^#\|'auto\ lo'\|'iface\ lo'/!d' /etc/network/interfaces
service network-manager restart


##### Fix repositories (Optional)
grep -q 'kali main non-free contrib' /etc/apt/sources.list || echo "deb http://http.kali.org/kali kali main non-free contrib" >>  /etc/apt/sources.list
grep -q 'kali/updates main contrib non-free' /etc/apt/sources.list || echo "deb http://security.kali.org/kali-security kali/updates main contrib non-free" >>  /etc/apt/sources.list


##### Install Virtual Machine tools for better support (Optional)
#--- Install VMware tools ~ http://docs.kali.org/general-use/install-vmware-tools-kali-guest
grep -q 'cups enabled' /usr/sbin/update-rc.d || echo "cups enabled" >> /usr/sbin/update-rc.d
grep -q 'vmware-tools enabled' /usr/sbin/update-rc.d || echo "vmware-tools enabled" >> /usr/sbin/update-rc.d
apt-get -y install gcc make linux-headers-$(uname -r)
ln -s /usr/src/linux-headers-$(uname -r)/include/generated/uapi/linux/version.h /usr/src/linux-headers-$(uname -r)/include/linux/
#VM -> Install VMware Tools.
mkdir -p /mnt/cdrom/
mount -o ro /dev/cdrom /mnt/cdrom
cp -f /mnt/cdrom/VMwareTools-*.tar.gz /tmp
cd /tmp/
tar zxvf VMwareTools*
cd vmware-tools-distrib/
perl vmware-install.pl #<enter> x ???  #<--- Doesn't automate
#--- Install Parallel tools
grep -q 'cups enabled' /usr/sbin/update-rc.d ||  echo "cups enabled" >> /usr/sbin/update-rc.d
grep -q 'vmware-tools enabled' /usr/sbin/update-rc.d ||  echo "vmware-tools enabled" >> /usr/sbin/update-rc.d
apt-get -y install gcc make linux-headers-$(uname -r)
ln -s /usr/src/linux-headers-$(uname -r)/include/generated/uapi/linux/version.h /usr/src/linux-headers-$(uname -r)/include/linux/
#Virtual Machine -> Install Parallels Tools
cd /media/Parallel\ Tools/
./install #<enter>,<enter>,<enter>... #<--- Doesn't automate
#--- Install VirtualBox Guest Additions
# Mount CD - Use autorun


##### Update OS
apt-get update && apt-get -y dist-upgrade
#--- Enable bleeding edge ~ http://www.kali.org/kali-monday/bleeding-edge-kali-repositories/
grep -q 'kali-bleeding-edge' /etc/apt/sources.list || echo -e "\n\n## Bleeding edge\ndeb http://repo.kali.org/kali kali-bleeding-edge main" >> /etc/apt/sources.list
apt-get update && apt-get -y upgrade


##### Configure GNOME 3
#--- Move bottom panel to top panel
gsettings set org.gnome.gnome-panel.layout toplevel-id-list "['top-panel']"
dconf write /org/gnome/gnome-panel/layout/objects/workspace-switcher/toplevel-id "'top-panel'"
dconf write /org/gnome/gnome-panel/layout/objects/window-list/toplevel-id "'top-panel'"
#--- Panel position
dconf write /org/gnome/gnome-panel/layout/toplevels/top-panel/orientation "'right'"
#--- Panel ordering
dconf write /org/gnome/gnome-panel/layout/objects/menu-bar/pack-type "'start'"
dconf write /org/gnome/gnome-panel/layout/objects/menu-bar/pack-index 0
dconf write /org/gnome/gnome-panel/layout/objects/window-list/pack-type "'center'"
dconf write /org/gnome/gnome-panel/layout/objects/window-list/pack-index 0
dconf write /org/gnome/gnome-panel/layout/objects/workspace-switcher/pack-type "'end'"
dconf write /org/gnome/gnome-panel/layout/objects/clock/pack-type "'end'"
dconf write /org/gnome/gnome-panel/layout/objects/user-menu/pack-type "'end'"
dconf write /org/gnome/gnome-panel/layout/objects/notification-area/pack-type "'end'"
dconf write /org/gnome/gnome-panel/layout/objects/workspace-switcher/pack-index 0
dconf write /org/gnome/gnome-panel/layout/objects/clock/pack-index 1
dconf write /org/gnome/gnome-panel/layout/objects/user-menu/pack-index 2
dconf write /org/gnome/gnome-panel/layout/objects/notification-area/pack-index 3
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
#--- Fix icon top 10 shortcut icon
#convert /usr/share/icons/hicolor/48x48/apps/k.png -negate /usr/share/icons/hicolor/48x48/apps/k-invert.png
#/usr/share/icons/gnome/48x48/status/security-medium.png
#--- Enable only two workspaces
gsettings set org.gnome.desktop.wm.preferences num-workspaces 2     #gconftool-2 --type int --set /apps/metacity/general/num_workspaces 2 #dconf write /org/gnome/gnome-panel/layout/objects/workspace-switcher/instance-config/num-rows 4
gsettings set org.gnome.shell.overrides dynamic-workspaces false
#--- Smaller title bar
#sed -i "/title_vertical_pad/s/value=\"[0-9]\{1,2\}\"/value=\"0\"/g" /usr/share/themes/Adwaita/metacity-1/metacity-theme-3.xml
#sed -i 's/title_scale=".*"/title_scale="small"/g' /usr/share/themes/Adwaita/metacity-1/metacity-theme-3.xml
gsettings set org.gnome.desktop.wm.preferences titlebar-font 'Droid Bold 10' # 'Cantarell Bold 11'
gsettings set org.gnome.desktop.wm.preferences titlebar-uses-system-font false
#--- Restart GNOME panel to apply/take effect (Need to restart xserver)
#killall gnome-panel && gnome-panel&   #Still need to logoff!


##### Setup terminal (Need to restart xserver)
#gconftool-2 --type bool --set /apps/gnome-terminal/profiles/Default/scrollback_unlimited true #Terminal -> Edit -> Profile Preferences -> Scrolling -> Scrollback: Unlimited -> Close


##### Setup screen
if [ ! -e /root/.screenrc.bkup ] && [ -e /root/.screenrc ]; then cp -f /root/.screenrc{,.bkup}; fi
echo -e "# Don't display the copyright page\nstartup_message off\n\n# tab-completion flash in heading bar\nvbell off\n\n# keep scrollback n lines\ndefscrollback 1000\n\n# hardstatus is a bar of text that is visible in all screens\nhardstatus on\nhardstatus alwayslastline\nhardstatus string '%{gk}%{G}%H %{g}[%{Y}%l%{g}] %= %{wk}%?%-w%?%{=b kR}(%{W}%n %t%?(%u)%?%{=b kR})%{= kw}%?%+w%?%?%= %{g} %{Y} %Y-%m-%d %C%a %{W}'\n\n# title bar\ntermcapinfo xterm ti@:te@\n\n# default windows (syntax: screen -t label order command)\nscreen -t bash1 0\nscreen -t bash2 1\n\n# select the default window\nselect 1" > /root/.screenrc


##### Add extra aliases
cp -n /etc/bashrc{,.bkup} # Should fail  #/root/.bash_aliases
echo -e '\n### axel\nalias axel="axel -a"\n\n### Screen\nalias screen="screen -xRR"\n\n### Directory navigation aliases\nalias ..="cd .."\nalias ...="cd ../.."\nalias ....="cd ../../.."\nalias .....="cd ../../../.."\n\n    \n### Add more aliases\nalias upd="sudo apt-get update"\nalias upg="sudo apt-get upgrade"\nalias ins="sudo apt-get install"\nalias rem="sudo apt-get purge"\nalias fix="sudo apt-get install -f"\n\n\n### Extract file, example. "ex package.tar.bz2"\nex() {\n    if [[ -f $1 ]]; then\n        case $1 in\n            *.tar.bz2)   tar xjf $1  ;;\n            *.tar.gz)    tar xzf $1  ;;\n            *.bz2)       bunzip2 $1  ;;\n            *.rar)       rar x $1    ;;\n            *.gz)        gunzip $1   ;;\n            *.tar)       tar xf $1   ;;\n            *.tbz2)      tar xjf $1  ;;\n            *.tgz)       tar xzf $1  ;;\n            *.zip)       unzip $1    ;;\n            *.Z)         uncompress $1  ;;\n            *.7z)        7z x $1     ;;\n            *)           echo $1 cannot be extracted ;;\n        esac\n    else\n        echo $1 is not a valid file\n    fi\n}\n' >> /etc/bashrc


##### Bash completion
#sed -i '/# enable bash completion in/,+3{/enable bash completion/!s/^#//}' /etc/bash.bashrc


##### Setup file browser (Need to restart xserver)
mkdir -p /root/.config/gtk-2.0/
if [ -e /root/.config/gtk-2.0/gtkfilechooser.ini ]; then sed -i 's/^.*ShowHidden.*/ShowHidden=true/' /root/.config/gtk-2.0/gtkfilechooser.ini; else echo -e "\n[Filechooser Settings]\nLocationMode=path-bar\nShowHidden=true\nExpandFolders=false\nShowSizeColumn=true\nGeometryX=66\nGeometryY=39\nGeometryWidth=780\nGeometryHeight=618\nSortColumn=name\nSortOrder=ascending\n" > /root/.config/gtk-2.0/gtkfilechooser.ini; fi #Open/save Window -> Right click -> Show Hidden Files: Enabled
dconf write /org/gnome/nautilus/preferences/show-hidden-files true
if [ ! -e /root/.gtk-bookmarks.bkup ]; then cp -f /root/.gtk-bookmarks{,.bkup}; fi
echo -e 'file:///var/www www\nfile:///usr/share apps\nfile:///tmp tmp\nfile:///usr/local/src/ src' >> /root/.gtk-bookmarks #Places -> Location: {/usr/share,/var/www/,/tmp/, /usr/local/src/} -> Bookmarks -> Add bookmark


##### Install conky
apt-get -y install conky
#- Configure conky
if [ ! -e /root/.conkyrc.bkup ] && [ -e /root/.conkyrc ]; then cp -f /root/.conkyrc{,.bkup}; fi
echo -e '#http://forums.opensuse.org/english/get-technical-help-here/how-faq-forums/unreviewed-how-faq/464737-easy-configuring-conky-conkyconf.html\nbackground yes\n\nfont Monospace:size=8:weight=bold\nuse_xft yes\n\nupdate_interval 2.0\n\nown_window yes\nown_window_type normal\nown_window_transparent yes\nown_window_class conky-semi\nown_window_argb_visual no  # YES # KDE\nown_window_colour brown\nown_window_hints undecorated,below,sticky,skip_taskbar,skip_pager\n\ndouble_buffer yes\nmaximum_width 250\n\ndraw_shades yes\ndraw_outline no\ndraw_borders no\n\nstippled_borders 3\nborder_margin 9\nborder_width 10\n\ndefault_color grey\n\nalignment bottom_right\n#gap_x 55 # KDE\ngap_x 0\ngap_y 0\n\nuppercase no\nuse_spacer right\n\nTEXT\n${color orange}SYSTEM INFORMATION ${hr 2}$color\n${color white}${time %A},${time %e} ${time %B} ${time %G}${alignr}${time %H:%M:%S}\n${color white}Machine:$color $nodename ${alignr}${color white}Uptime:$color $uptime\n\n${color orange}CPU ${hr 2}$color\n${font Arial:bold:size=8}${color #ff9999}${execi 99999 cat /proc/cpuinfo | grep "model name" -m1 | cut -d":" -f2 | cut -d" " -f2- | sed "s#Processor ##"}$font$color\n${color white}CPU:$color ${freq}GHz ${color #c0ff3e}${acpitemp}C  $color${alignr}${color white}Processes:$color $running_processes/$processes (${cpu cpu0}% ${cpu cpu1}%)\n#${execi 20 sensors |grep "Core0 Temp" | cut -d" " -f4}$font$color$alignr${freq_g 2} ${execi 20 sensors |grep "Core1 Temp" | cut -d" " -f4}\n${cpugraph cpu1 25,120 000000 ff6600 } ${cpugraph cpu2 25,120 000000 cc0033}\n${color #ff6600}${cpubar cpu1 3,120} ${color #cc0033}${cpubar cpu2 3,120}$color\n\n${color orange}TOP 5 PROCESSES ${hr 2}$color\n${color #ff9999}NAME               PID      CPU      MEM\n${color #ffff99}1. ${top name 1}${top pid 1}   ${top cpu 1}   ${top mem 1}$color\n2. ${top name 2}${top pid 2}   ${top cpu 2}   ${top mem 2}\n3. ${top name 3}${top pid 3}   ${top cpu 3}   ${top mem 3}\n4. ${top name 4}${top pid 4}   ${top cpu 4}   ${top mem 4}\n5. ${top name 5}${top pid 5}   ${top cpu 5}   ${top mem 5}\n\n${color orange}MEMORY & SWAP ${hr 2}$color\n${color white}RAM$color   $memperc%   ${membar 6}$color\n${color white}Swap$color  $swapperc%   ${swapbar 6}$color\n\n${color orange}FILESYSTEM${hr 2}$color\n${color white}root$color ${fs_free_perc /}% free$alignr${fs_free /}/ ${fs_size /}\n${fs_bar 3 /}$color\n${color white}home$color ${fs_free_perc /home}% free$alignr${fs_free /home}/ ${fs_size /home}\n${fs_bar 3 /home}$color\n\n${color orange}LAN (${addr eth0}) ${hr 2}$color\n${color white}Down:$color  ${downspeed eth0} KB/s${alignr}${color white}Up:$color ${upspeed eth0} KB/s\n${color white}Downloaded:$color ${totaldown eth0} ${alignr}${color white}Uploaded:$color ${totalup eth0}\n${downspeedgraph eth0 25,120 000000 00ff00} ${alignr}${upspeedgraph eth0 25,120 000000 ff0000}$color\n${color orange}WiFi (${addr wlan0}) ${hr 2}$color\n${color white}Down:$color  ${downspeed wlan0} KB/s${alignr}${color white}Up:$color ${upspeed wlan0} KB/s\n${color white}Downloaded:$color ${totaldown wlan0} ${alignr}${color white}Uploaded:$color ${totalup wlan0}\n${downspeedgraph wlan0 25,120 000000 00ff00} ${alignr}${upspeedgraph wlan0 25,120 000000 ff0000}$color\n\n${color orange}CONNECTIONS ${hr 2}$color\n${color white}Inbound: $color${tcp_portmon 1 32767 count}${color white}  ${alignc}Outbound: $color${tcp_portmon 32768 61000 count}${alignr} ${color white}ALL: $color${tcp_portmon 1 65535 count}\n${color white}Inbound Connection ${alignr} Local Service/Port$color\n$color ${tcp_portmon 1 32767 rhost 0} ${alignr} ${tcp_portmon 1 32767 lservice 0}\n$color ${tcp_portmon 1 32767 rhost 1} ${alignr} ${tcp_portmon 1 32767 lservice 1}\n$color ${tcp_portmon 1 32767 rhost 2} ${alignr} ${tcp_portmon 1 32767 lservice 2}\n${color white}Outbound Connection ${alignr} Remote Service/Port$color\n$color ${tcp_portmon 32768 61000 rhost 0} ${alignr} ${tcp_portmon 32768 61000 rservice 0}\n$color ${tcp_portmon 32768 61000 rhost 1} ${alignr} ${tcp_portmon 32768 61000 rservice 1}\n$color ${tcp_portmon 32768 61000 rhost 2} ${alignr} ${tcp_portmon 32768 61000 rservice 2}' > /root/.conkyrc
# Add to startup
echo -e '#!/bin/bash\nsleep 25 && conky;' > /root/.conkyscript.sh
chmod +x /root/.conkyscript.sh
mkdir -p /root/.config/autostart/
echo -e '\n[Desktop Entry]\nType=Application\nExec=/root/.conkyscript.sh\nHidden=false\nNoDisplay=false\nX-GNOME-Autostart-enabled=true\nName[en_US]=conky\nName=conky\nComment[en_US]=\nComment=' > /root/.config/autostart/.conkyscript.sh.desktop #system -> Preferences -> Startup Applications -> Add -> Name: conky -> Command: /root/.conkyscript.sh -> Add -> Close


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
geany & sleep 5; killall geany   # Start and kill. Files needed for first time run
#Geany -> Edit -> Preferences. Editor -> Newline strips trailing spaces: Enable. -> Indentation -> Type: Spaces. -> Files -> Strip trailing spaces and tabs: Enable. Replace tabs by space: Enable. -> Apply -> Ok
sed -i 's/^.*indent_type.*/indent_type=0/' /root/.config/geany/geany.conf
sed -i 's/^.*pref_editor_newline_strip.*/pref_editor_newline_strip=true/' /root/.config/geany/geany.conf
sed -i 's/^.*pref_editor_replace_tabs.*/pref_editor_replace_tabs=true/' /root/.config/geany/geany.conf
sed -i 's/^.*pref_editor_trail_space.*/pref_editor_trail_space=true/' /root/.config/geany/geany.conf
#Geany -> Tools -> Plugin Manger -> Save Actions -> HTML Characters: Enabled. Split WIndows: Enabled. Save Actions: Enabled. -> Preferences -> Backup Copy -> Enable -> Directory to save backup files in: /root/backups/geany/. Directory levels to include in the backup destination: 5 -> Apply -> Ok -> Ok
sed -i 's/^.*active_plugins.*/active_plugins=\/usr\/lib\/geany\/htmlchars.so;\/usr\/lib\/geany\/saveactions.so;\/usr\/lib\/geany\/splitwindow.so;/' /root/.config/geany/geany.conf
mkdir -p /root/backups/geany/
mkdir -p /root/.config/geany/plugins/saveactions/
echo -e '\n[saveactions]\nenable_autosave=false\nenable_instantsave=false\nenable_backupcopy=true\n\n[autosave]\nprint_messages=false\nsave_all=false\ninterval=300\n\n[instantsave]\ndefault_ft=None\n\n[backupcopy]\ndir_levels=5\ntime_fmt=%Y-%m-%d-%H-%M-%S\nbackup_dir=/root/backups/geany' > /root/.config/geany/plugins/saveactions/saveactions.conf


##### Randomize the eth0 & wlan0's MAC address on startup
#if [[ `grep macchanger /etc/rc.local -q; echo $?` == 1 ]]; then sed -i 's#^exit 0#for int in eth0 wlan0; do\n\tifconfig $int down\n\t/usr/bin/macchanger -r $int \&\& sleep 3\n\tifconfig $int up\ndone\n\n\nexit 0#' /etc/rc.local; fi
##echo -e '#!/bin/bash\nfor int in eth0 wlan0; do\n\techo "Randomizing: $int"\n\tifconfig $int down\n\tmacchanger -r $int\n\tsleep 3\n\tifconfig $int up\n\techo "--------------------"\ndone\nexit 0' > /etc/init.d/macchanger
##echo -e '#!/bin/bash\n[ "$IFACE" == "lo" ] && exit 0\nifconfig $IFACE down\nmacchanger -r $IFACE\nifconfig $IFACE up\nexit 0' > /etc/network/if-pre-up.d/macchanger


##### Gparted
apt-get -y install gparted


##### DaemonFS
apt-get -y install daemonfs


##### Install FileZilla
apt-get -y install filezilla
filezilla & sleep 5; killall filezilla   # Start and kill. Files needed for first time run
sed -i 's/^.*"Default editor".*/\t<Setting name="Default editor" type="string">2\/usr\/bin\/geany<\/Setting>/' /root/.filezilla/filezilla.xml


##### Install tftp
apt-get -y install tftp


##### Install lynx
apt-get -y install lynx


##### Setup iceweasel & replace bookmarks
iceweasel & sleep 15; killall iceweasel   # Start and kill. Files needed for first time run
if [[ `grep "browser.startup.page" /root/.mozilla/firefox/*.default/prefs.js -q; echo $?` == 1 ]]; then echo 'user_pref("browser.startup.page", 0);' >> /root/.mozilla/firefox/*.default/prefs.js; else sed -i 's/^.*browser.startup.page.*/user_pref("browser.startup.page", 0);' /root/.mozilla/firefox/*.default/prefs.js; fi #Iceweasel -> Edit -> Preferences -> General -> When firefox starts: Show a blank page
if [[ `grep "privacy.donottrackheader.enabled" /root/.mozilla/firefox/*.default/prefs.js -q; echo $?` == 1 ]]; then echo 'user_pref("privacy.donottrackheader.enabled", true);' >> /root/.mozilla/firefox/*.default/prefs.js; else sed -i 's/^.*privacy.donottrackheader.enabled.*/user_pref("privacy.donottrackheader.enabled", true);' /root/.mozilla/firefox/*.default/prefs.js; fi #Privacy -> Enable: Tell websites I do not want to be tracked
if [[ `grep " browser.showQuitWarning" /root/.mozilla/firefox/*.default/prefs.js -q; echo $?` == 1 ]]; then echo 'user_pref("browser.showQuitWarning", true);' >> /root/.mozilla/firefox/*.default/prefs.js; else sed -i 's/^.*browser.showQuitWarning.*/user_pref("browser.showQuitWarning", true);' /root/.mozilla/firefox/*.default/prefs.js; fi # Stop Ctrl + Q from quitting without warning
cd /root/.mozilla/firefox/*.default/
wget http://pentest-bookmarks.googlecode.com/files/bookmarksv1.5.html  # ****!! hardcoded version! Need to manually check for updates
awk '!a[$0]++' bookmarksv*.html > bookmarks.html
rm -f /root/.mozilla/firefox/*.default/places.sqlite
rm -f /root/.mozilla/firefox/*.default/bookmarkbackups/*
cd /root/.mozilla/firefox/*.default/
mkdir -p extensions/
cd /root/.mozilla/firefox/*.default/extensions/
wget https://addons.mozilla.org/firefox/downloads/latest/1865/addon-1865-latest.xpi?src=dp-btn-primary -O {d10d0bf8-f5b5-c8b4-a8b2-2b9879e08c5d}.xpi #Adblock Plus
wget https://addons.mozilla.org/firefox/downloads/latest/1843/addon-1843-latest.xpi?src=dp-btn-primary -O firebug@software.joehewitt.com.xpi #Firebug
wget https://addons.mozilla.org/firefox/downloads/file/150692/foxyproxy_basic-2.6.2-fx+tb+sm.xpi?src=search -O FoxyProxyBasic.zip && unzip FoxyProxyBasic.zip -d foxyproxy-basic@eric.h.jung/ && rm FoxyProxyBasic.zip #FoxyProxy Basic
wget https://addons.mozilla.org/firefox/downloads/latest/284030/addon-284030-latest.xpi?src=dp-btn-primary -O {6bdc61ae-7b80-44a3-9476-e1d121ec2238}.xpi #HTTPS Finder
wget https://addons.mozilla.org/firefox/downloads/latest/3829/addon-3829-latest.xpi?src=dp-btn-primary -O {8f8fe09b-0bd3-4470-bc1b-8cad42b8203a}.xpi #Live HTTP Headers
iceweasel #<--- Doesn't automate
#for z in *.xpi; do
# d=`basename $z .xpi`
# mkdir $d && unzip $z -d $d
#done
cd ~/


##### Install nessus
cd /tmp/
#--- Get download link
iceweasel http://www.tenable.com/products/nessus/select-your-operating-system
wget "http://downloads.nessus.org/<file>" -O nessus.deb   #***!!! Hardcoded version value
dpkg -i nessus.deb
rm -rf nessus.deb
/opt/nessus/sbin/nessus-adduser #<--- Doesn't automate
iceweasel http://www.tenable.com/products/nessus/nessus-plugins/register-a-homefeed
#--- Check email
 /opt/nessus/bin/nessus-fetch --register <key> #<--- Doesn't automate
service nessusd start


##### Setup metasploit ~ http://docs.kali.org/general-use/starting-metasploit-framework-in-kali
service postgresql start
service metasploit start
echo exit > /tmp/msf.rc
msfconsole -r /tmp/msf.rc
rm /tmp/msf.rc


##### Add htshells
cd /usr/share/
git clone git://github.com/wireghoul/htshells.git


##### Add 10,000 Top/Worst/Common Passwords
cd /usr/share/wordlists
wget http://xato.net/files/10k%20most%20common.zip && unzip "10k most common.zip" && rm -f "10k most common.zip"


##### Extract rockyou wordlist
cd /usr/share/wordlists
gunzip rockyou.txt.gz


##### Cleaning system
apt-get -y clean
apt-get -y autoremove
apt-get -y autoclean
history -c


#### Done!
reboot

# Don't forget to take a snapshot if you're using a VM!