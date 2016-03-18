#!/bin/sh
#Operating System(s)#######################
# Designed for: Backtrack 5 R3 (GNOME)    #
#              [x64 & x86]                #
# Working on: 2012-09-14                  #
#Author####################################
#  g0tmilk ~ https://blog.g0tmi1k.com/    #
#Note######################################
# Everything has been automated EXECPT... #
# 1.) Altering root's password            #
# 2.) Accepting firefox's addons          #
# 3.) Nessus adding user & registering    #
# 4.) OpenVAS adding users                #
# 5.) Timezone & keyboard layout          #
# 6.) Running update script               #
# 7.) VM tools installation (Optional)    #
# --------------------------------------- #
# Some settings will only take affect...  #
# ...when xserver is reloaded             #
# --------------------------------------- #
# For some reason, the bottom pannel...   #
# ...doesn't become centered              #
# --------------------------------------- #
# This will WIPE your...                  #
# 1.) Firefox bookmarks                   #
# 2.) Cosmetics                           #
# --------------------------------------- #
# The script wasn't designed to be...     #
# ...execute. Copy & paste commands       #
###########################################
# Login and change default password
#root:toor
passwd #<--- Doesn't automate

# Setup SSH
sshd-generate
startx

##############################(Optional)###
# Allows for the rest of the configuration to happen via SSH
services ssh start
ifconfig eth0

# Run the rest on the remote computer
ssh root@<ip> # replace <ip> with the information from ifconfig
export DISPLAY=:0.0
##############################(Optional)###
# Install VMware tools ~ http://www.backtrack-linux.org/wiki/index.php/VMware_Tools
prepare-kernel-sources; cd /usr/src/linux/; cp -rf include/generated/* include/linux/
#VM -> Install VMware Tools.
mkdir /mnt/cdrom
mount -o ro /dev/cdrom /mnt/cdrom
cp -f /mnt/cdrom/VMwareTools-*.tar.gz /tmp
cd /tmp/
tar zxvf VMwareTools*
cd vmware-tools-distrib/
perl vmware-install.pl #<enter>,<enter>,<enter>... #<--- Doesn't automate
##############################(Optional)###
# Install Parallel tools
prepare-kernel-sources; cd /usr/src/linux/; cp -rf include/generated/* include/linux/
#Virtual Machine -> Install Parallels Tools
cd /media/Parallel\ Tools/
./install #<enter>,<enter>,<enter>... #<--- Doesn't automate
##############################(Optional)###
# Install VirtualBox Guest Additions
# Mount CD - Use autorun
###########################################

# Update OS
apt-get update && apt-get -y dist-upgrade

# Make sure we are fully upgraded (http://www.backtrack-linux.org/backtrack/upgrade-from-backtrack-5-r2-to-backtrack-5-r3/ & http://redmine.backtrack-linux.org:8080/issues/817)
command="libcrafter blueranger dbd inundator intersect mercury cutycapt trixd00r rifiuti2 netgear-telnetenable jboss-autopwn deblaze sakis3g voiphoney apache-users phrasendrescher kautilya manglefizz rainbowcrack rainbowcrack-mt lynis-audit spooftooph wifihoney twofi truecrack acccheck statsprocessor iphoneanalyzer jad javasnoop mitmproxy ewizard multimac netsniff-ng smbexec websploit dnmap johnny unix-privesc-check sslcaudit dhcpig intercepter-ng u3-pwn binwalk laudanum wifite tnscmd10g bluepot dotdotpwn subterfuge jigsaw urlcrazy creddump android-sdk apktool ded dex2jar droidbox smali termineter bbqsql htexploit smartphone-pentest-framework fern-wifi-cracker powersploit webhandler"
if [[ `uname -m` == *x64* ]]; then
    command="$command multiforcer"
else
    command="$command artemisa uberharvest"
fi
apt-get -y install $command

# Install conky
apt-get -y install conky
if [ ! -e /root/.conkyrc.bkup ] && [ -e /root/.conkyrc ]; then cp -f /root/.conkyrc{,.bkup}; fi
echo -e '#http://forums.opensuse.org/english/get-technical-help-here/how-faq-forums/unreviewed-how-faq/464737-easy-configuring-conky-conkyconf.html\nbackground yes\n\nfont Monospace:size=8:weight=bold\nuse_xft yes\n\nupdate_interval 2.0\n\nown_window yes\nown_window_type normal\nown_window_transparent yes\nown_window_class conky-semi\nown_window_argb_visual no  # YES # KDE\nown_window_colour brown\nown_window_hints undecorated,below,sticky,skip_taskbar,skip_pager\n\ndouble_buffer yes\nmaximum_width 250\n\ndraw_shades yes\ndraw_outline no\ndraw_borders no\n\nstippled_borders 3\nborder_margin 9\nborder_width 10\n\ndefault_color grey\n\nalignment bottom_right\n#gap_x 55 # KDE\ngap_x 0\ngap_y 0\n\nuppercase no\nuse_spacer right\n\nTEXT\n${color orange}SYSTEM INFORMATION ${hr 2}$color\n${color white}${time %A},${time %e} ${time %B} ${time %G}${alignr}${time %H:%M:%S}\n${color white}Machine:$color $nodename ${alignr}${color white}Uptime:$color $uptime\n\n${color orange}CPU ${hr 2}$color\n${font Arial:bold:size=8}${color #ff9999}${execi 99999 cat /proc/cpuinfo | grep "model name" -m1 | cut -d":" -f2 | cut -d" " -f2- | sed "s#Processor ##"}$font$color\n${color white}CPU:$color ${freq}GHz ${color #c0ff3e}${acpitemp}C  $color${alignr}${color white}Processes:$color $running_processes/$processes (${cpu cpu0}% ${cpu cpu1}%)\n#${execi 20 sensors |grep "Core0 Temp" | cut -d" " -f4}$font$color$alignr${freq_g 2} ${execi 20 sensors |grep "Core1 Temp" | cut -d" " -f4}\n${cpugraph cpu1 25,120 000000 ff6600 } ${cpugraph cpu2 25,120 000000 cc0033}\n${color #ff6600}${cpubar cpu1 3,120} ${color #cc0033}${cpubar cpu2 3,120}$color\n\n${color orange}TOP 5 PROCESSES ${hr 2}$color\n${color #ff9999}NAME               PID      CPU      MEM\n${color #ffff99}1. ${top name 1}${top pid 1}   ${top cpu 1}   ${top mem 1}$color\n2. ${top name 2}${top pid 2}   ${top cpu 2}   ${top mem 2}\n3. ${top name 3}${top pid 3}   ${top cpu 3}   ${top mem 3}\n4. ${top name 4}${top pid 4}   ${top cpu 4}   ${top mem 4}\n5. ${top name 5}${top pid 5}   ${top cpu 5}   ${top mem 5}\n\n${color orange}MEMORY & SWAP ${hr 2}$color\n${color white}RAM$color   $memperc%   ${membar 6}$color\n${color white}Swap$color  $swapperc%   ${swapbar 6}$color\n\n${color orange}FILESYSTEM${hr 2}$color\n${color white}root$color ${fs_free_perc /}% free$alignr${fs_free /}/ ${fs_size /}\n${fs_bar 3 /}$color\n${color white}home$color ${fs_free_perc /home}% free$alignr${fs_free /home}/ ${fs_size /home}\n${fs_bar 3 /home}$color\n\n${color orange}LAN (${addr eth0}) ${hr 2}$color\n${color white}Down:$color  ${downspeed eth0} KB/s${alignr}${color white}Up:$color ${upspeed eth0} KB/s\n${color white}Downloaded:$color ${totaldown eth0} ${alignr}${color white}Uploaded:$color ${totalup eth0}\n${downspeedgraph eth0 25,120 000000 00ff00} ${alignr}${upspeedgraph eth0 25,120 000000 ff0000}$color\n${color orange}WiFi (${addr wlan0}) ${hr 2}$color\n${color white}Down:$color  ${downspeed wlan0} KB/s${alignr}${color white}Up:$color ${upspeed wlan0} KB/s\n${color white}Downloaded:$color ${totaldown wlan0} ${alignr}${color white}Uploaded:$color ${totalup wlan0}\n${downspeedgraph wlan0 25,120 000000 00ff00} ${alignr}${upspeedgraph wlan0 25,120 000000 ff0000}$color\n\n${color orange}CONNECTIONS ${hr 2}$color\n${color white}Inbound: $color${tcp_portmon 1 32767 count}${color white}  ${alignc}Outbound: $color${tcp_portmon 32768 61000 count}${alignr} ${color white}ALL: $color${tcp_portmon 1 65535 count}\n${color white}Inbound Connection ${alignr} Local Service/Port$color\n$color ${tcp_portmon 1 32767 rhost 0} ${alignr} ${tcp_portmon 1 32767 lservice 0}\n$color ${tcp_portmon 1 32767 rhost 1} ${alignr} ${tcp_portmon 1 32767 lservice 1}\n$color ${tcp_portmon 1 32767 rhost 2} ${alignr} ${tcp_portmon 1 32767 lservice 2}\n${color white}Outbound Connection ${alignr} Remote Service/Port$color\n$color ${tcp_portmon 32768 61000 rhost 0} ${alignr} ${tcp_portmon 32768 61000 rservice 0}\n$color ${tcp_portmon 32768 61000 rhost 1} ${alignr} ${tcp_portmon 32768 61000 rservice 1}\n$color ${tcp_portmon 32768 61000 rhost 2} ${alignr} ${tcp_portmon 32768 61000 rservice 2}' > /root/.conkyrc
echo -e '#!/bin/bash\nsleep 20 && conky;' > /root/.conkyscript.sh
chmod +x /root/.conkyscript.sh
mkdir -p /root/.config/autostart/
echo -e '\n[Desktop Entry]\nType=Application\nExec=/root/.conkyscript.sh\nHidden=false\nNoDisplay=false\nX-GNOME-Autostart-enabled=true\nName[en_US]=conky\nName=conky\nComment[en_US]=\nComment=' > /root/.config/autostart/.conkyscript.sh.desktop #system -> Preferences -> Startup Applications -> Add -> Name: conky -> Command: /root/.conkyscript.sh -> Add -> Close

# Install network-manager
apt-get -y install network-manager-gnome
apt-get -y remove wicd-*
if [ ! -e /etc/network/interfaces.bkup ]; then cp -f /etc/network/interfaces{,.bkup}; fi
echo -e auto lo\niface lo inet loopback > /etc/network/interfaces
service network-manager start

# Install geany
apt-get -y install geany
/usr/lib/gnome-panel/gnome-panel-add --launcher=/usr/share/applications/geany.desktop --panel=top_panel_screen0 #Application -> Programming -> Right click: Geany -> Add this laucher to panel
geany &
sleep 5
killall geany
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

# Install filezilla
apt-get -y install filezilla
filezilla &
sleep 5
killall filezilla
sed -i 's/^.*"Default editor".*/\t<Setting name="Default editor" type="string">2\/usr\/bin\/geany<\/Setting>/' /root/.filezilla/filezilla.xml

# Install nessus
apt-get -y install nessus
/opt/nessus/sbin/nessus-adduser #<--- Doesn't automate
firefox http://www.tenable.com/products/nessus/nessus-plugins/register-a-homefeed
nessus-fetch --register <key> #<--- Doesn't automate

# Install tftp
apt-get -y install tftp

# Install lynx
apt-get -y install lynx

# Install Backtrack updater
cd /pentest/misc/
git clone git://github.com/sickn3ss/backtrack_update.git
cd backtrack_update/
chmod +x backtrack_update.py
ln -s /pentest/misc/backtrack_update/backtrack_update.py /pentest/backtrack_update
./backtrack_update.py --update tools #<--- Doesn't automate

# Setup OpenVAS (http://www.backtrack-linux.org/wiki/index.php/OpenVas)
openvas-adduser  #<--- Doesn't automate
openvas-mkcert #<--- Doesn't automate
openvas-mkcert-client -n om -i
openvasmd --rebuild
openvasad -c 'add_user' -n openvasadmin -r root  #<--- Doesn't automate
bash /pentest/misc/openvas/openvas-check-setup

# Setup BeEF
#cd /pentest/web/beef/
bash /usr/local/bin/beef_install.sh

# Setup WPScan
gem install --user-install nokogiri

# Setup firefox and replace bookmarks
/usr/lib/gnome-panel/gnome-panel-add --launcher=/usr/share/applications/backtrack-firefox.desktop --panel=top_panel_screen0 #Application -> Internet -> Right click: Firefox Web Browser -> Add this laucher to panel
if [[ `grep "browser.startup.page" /root/.mozilla/firefox/*.default/prefs.js -q; echo $?` == 1 ]]; then echo 'user_pref("browser.startup.page", 0);' >> /root/.mozilla/firefox/*.default/prefs.js; else sed -i 's/^.*browser.startup.page.*/user_pref("browser.startup.page", 0);' /root/.mozilla/firefox/*.default/prefs.js; fi #Firefox -> Edit -> Preferences -> General -> When firefox starts: Show a blank page
if [[ `grep "privacy.donottrackheader.enabled" /root/.mozilla/firefox/*.default/prefs.js -q; echo $?` == 1 ]]; then echo 'user_pref("privacy.donottrackheader.enabled", true);' >> /root/.mozilla/firefox/*.default/prefs.js; else sed -i 's/^.*privacy.donottrackheader.enabled.*/user_pref("privacy.donottrackheader.enabled", true);' /root/.mozilla/firefox/*.default/prefs.js; fi #Privacy -> Enable: Tell websites I do not want to be tracked
if [[ `grep " browser.showQuitWarning" /root/.mozilla/firefox/*.default/prefs.js -q; echo $?` == 1 ]]; then echo 'user_pref("browser.showQuitWarning", true);' >> /root/.mozilla/firefox/*.default/prefs.js; else sed -i 's/^.*browser.showQuitWarning.*/user_pref("browser.showQuitWarning", true);' /root/.mozilla/firefox/*.default/prefs.js; fi # Stop Ctrl + Q from quitting without warning
mkdir -p /pentest/web/bookmarks/
cd /pentest/web/bookmarks/
wget http://pentest-bookmarks.googlecode.com/files/bookmarksv1.5.html
cd /root/.mozilla/firefox/*.default/
awk '!a[$0]++' /pentest/web/bookmarks/bookmarksv*.html > bookmarks.html
rm -f /root/.mozilla/firefox/*.default/places.sqlite
rm -f /root/.mozilla/firefox/*.default/bookmarkbackups/*
firefox &
sleep 15
killall firefox-bin
cd /root/.mozilla/firefox/*.default/extensions/
wget https://addons.mozilla.org/firefox/downloads/latest/1865/addon-1865-latest.xpi?src=dp-btn-primary -O {d10d0bf8-f5b5-c8b4-a8b2-2b9879e08c5d}.xpi #Adblock Plus
wget https://addons.mozilla.org/firefox/downloads/latest/1843/addon-1843-latest.xpi?src=dp-btn-primary -O firebug@software.joehewitt.com.xpi #Firebug
wget https://addons.mozilla.org/firefox/downloads/file/150692/foxyproxy_basic-2.6.2-fx+tb+sm.xpi?src=search -O FoxyProxyBasic.zip && unzip FoxyProxyBasic.zip -d foxyproxy-basic@eric.h.jung/ && rm FoxyProxyBasic.zip #FoxyProxy Basic
wget https://addons.mozilla.org/firefox/downloads/latest/284030/addon-284030-latest.xpi?src=dp-btn-primary -O {6bdc61ae-7b80-44a3-9476-e1d121ec2238}.xpi #HTTPS Finder
wget https://addons.mozilla.org/firefox/downloads/latest/3829/addon-3829-latest.xpi?src=dp-btn-primary -O {8f8fe09b-0bd3-4470-bc1b-8cad42b8203a}.xpi #Live HTTP Headers
firefox #<--- Doesn't automate

# Setup terminal (Needs to restart xserver)
gconftool-2 --type bool --set /apps/gnome-terminal/profiles/Default/scrollback_unlimited true #Terminal -> Edit -> Profile Preferences -> Scrolling -> Scrollback: Unlimited -> Close

# Setup metasploit (First time run)
echo exit > /tmp/msf.rc
msfconsole -r /tmp/msf.rc
rm /tmp/msf.rc

# Setup file browser (Needs to restart xserver)
mkdir -p /root/.config/gtk-2.0/
if [ -e /root/.config/gtk-2.0/gtkfilechooser.ini ]; then sed -i 's/^.*ShowHidden.*/ShowHidden=true/' /root/.config/gtk-2.0/gtkfilechooser.ini; else echo -e "\n[Filechooser Settings]\nLocationMode=path-bar\nShowHidden=true\nExpandFolders=false\nShowSizeColumn=true\nGeometryX=66\nGeometryY=39\nGeometryWidth=780\nGeometryHeight=618\nSortColumn=name\nSortOrder=ascending\n" > /root/.config/gtk-2.0/gtkfilechooser.ini; fi #Open/save Window -> Right click -> Show Hidden Files: Enabled
gconftool-2 --type bool --set /desktop/gnome/file_views/show_hidden_files true #Places -> Home Folder -> Edit -> Preferences -> Enable: Show hidden and backup file -> Close
if [ ! -e /root/.gtk-bookmarks.bkup ]; then cp -f /root/.gtk-bookmarks{,.bkup}; fi
echo -e 'file:///var/www www\nfile:///pentest pentest\nfile:///tmp tmp\nfile:///usr/local/src/ src' >> /root/.gtk-bookmarks #Places -> Location: {/pentest/,/var/www/,/tmp/, /usr/local/src/} -> Bookmarks -> Add bookmark

# Setup screen
if [ ! -e /root/.screenrc.bkup ] && [ -e /root/.screenrc ]; then cp -f /root/.screenrc{,.bkup}; fi
echo -e "# Don't display the copyright page\nstartup_message off\n\n# tab-completion flash in heading bar\nvbell off\n\n# keep scrollback n lines\ndefscrollback 1000\n\n# hardstatus is a bar of text that is visible in all screens\nhardstatus on\nhardstatus alwayslastline\nhardstatus string '%{gk}%{G}%H %{g}[%{Y}%l%{g}] %= %{wk}%?%-w%?%{=b kR}(%{W}%n %t%?(%u)%?%{=b kR})%{= kw}%?%+w%?%?%= %{g} %{Y} %Y-%m-%d %C%a %{W}'\n\n# title bar\ntermcapinfo xterm ti@:te@\n\n# default windows (syntax: screen -t label order command)\nscreen -t bash1 0\nscreen -t bash2 1\n\n# select the default window\nselect 1" > /root/.screenrc

# Cosmetics (in order of appearance!)
image="/usr/share/wallpapers/backtrack/BT5-R3-wp-grey.png"
#identify $image

# GRUB menu (x86? only)
convert -resize 1024x768! "$image" /usr/share/images/desktop-base/moreblue-orbit-grub.png
update-grub2

# Framebuffer Bootsplash
cd /usr/local/src/
if [ ! -e /usr/local/src/bootsplash-3.1.tar.bz2 ]; then wget ftp://ftp.bootsplash.org/pub/bootsplash/rpm-sources/bootsplash/bootsplash-3.1.tar.bz2; fi
tar xvjf bootsplash-3.1.tar.bz2
cd bootsplash-*/Utilities/
make splash
convert "$image" -resize 1024x768! /tmp/bootsplash.jpg
mogrify -density 72x72 -units PixelsPerInch /opt/bootsplash/bootsplash.jpg
echo -e '# config file version\nversion=3\n\n# should the picture be displayed?\nstate=1\n\n# fgcolor is the text forground color.\n# bgcolor is the text background (i.e. transparent) color.\nfgcolor=7\nbgcolor=0\n\n# (tx, ty) are the (x, y) coordinates of the text window in pixels.\n# tw/th is the width/height of the text window in pixels.\ntx=80\nty=140\ntw=865\nth=560\n\n# name of the picture file (full path recommended)\njpeg=/opt/bootsplash/bootsplash.jpg\nsilentjpeg=/opt/bootsplash/bootsplash.jpg\n\nprogress_enable=0\noverpaintok=1' > /tmp/bootsplash.cfg
if [ ! -e /opt/bootsplash/bootsplash.bkup ]; then cp -f /opt/bootsplash/bootsplash{,.bkup}; fi
./splash -s -f /tmp/bootsplash.cfg > /opt/bootsplash/bootsplash
#fix-splash
rm -rf /tmp/bootsplash.jpg

# Plymouth Bootsplash
if [ ! -e /lib/plymouth/themes/simple/bt5_1024x768.png.bkup ]; then cp -f /lib/plymouth/themes/simple/bt5_1024x768.png{,.bkup}; fi
convert -resize 1024x768! "$image" /lib/plymouth/themes/simple/bt5_1024x768.png
update-alternatives --auto default.plymouth #update-alternatives --config default.plymouth
update-initramfs -u
fix-splash

# Desktop (Needs to restart xserver)
rm -f /root/Desktop/backtrack-install.desktop
gconftool-2 --type string --set /desktop/gnome/background/picture_filename "$image" #Right click -> Change Desktop Background -> Theme: New Wave, Background -> Add: /usr/share/wallpapers/backtrack/*. Select: BT5-R3-wp-grey.png

# Panels (Needs to restart xserver)
# For some reason, the bottom pannel doesn't become centered
gconftool-2 --type string --set /apps/panel/toplevels/top_panel_screen0/orientation right #Right click on top toolbar -> Properties -> General -> Orientation: Right -> Close
gconftool-2 --type bool --set /apps/panel/toplevels/bottom_panel_screen0/expand false #Right click on bottom toolbar -> Properties -> General -> Expand: Disable
gconftool-2 --type int --set /apps/metacity/general/num_workspaces 2 #Right click on bottom toolbar (Workspace) -> Properties -> Number of workspaces: 2

# Randomize the eth0 & wlan0's MAC address on startup
if [[ `grep macchanger /etc/rc.local -q; echo $?` == 1 ]]; then sed -i 's/^exit 0/for int in eth0 wlan0; do\n\tifconfig $int down\n\t\/usr\/local\/bin\/macchanger -r $int \&\& sleep 3\n\tifconfig $int up\ndone\n\n\nexit 0/' /etc/rc.local; fi
#echo -e '#!/bin/bash\nfor int in eth0 wlan0; do\n\techo "Randomizing: $int"\n\tifconfig $int down\n\tmacchanger -r $int\n\tsleep 3\n\tifconfig $int up\n\techo "--------------------"\ndone\nexit 0' > /etc/init.d/macchanger
#echo -e '#!/bin/bash\n[ "$IFACE" == "lo" ] && exit 0\nifconfig $IFACE down\nmacchanger -r $IFACE\nifconfig $IFACE up\nexit 0' > /etc/network/if-pre-up.d/macchanger

# Add extra bash aliases
sed -i 's/#alias/alias/' /root/.bashrc
echo -e '### Directory navigation aliases\nalias ..="cd .."\nalias ...="cd ../.."\nalias ....="cd ../../.."\nalias .....="cd ../../../.."\n\n    \n### Add more aliases\nalias upd="sudo apt-get update"\nalias upg="sudo apt-get upgrade"\nalias ins="sudo apt-get install"\nalias rem="sudo apt-get purge"\nalias fix="sudo apt-get install -f"\n\n\n### Extract file, example. "ex package.tar.bz2"\nex() {\n    if [[ -f $1 ]]; then\n        case $1 in\n            *.tar.bz2)   tar xjf $1  ;;\n            *.tar.gz)    tar xzf $1  ;;\n            *.bz2)       bunzip2 $1  ;;\n            *.rar)       rar x $1    ;;\n            *.gz)        gunzip $1   ;;\n            *.tar)       tar xf $1   ;;\n            *.tbz2)      tar xjf $1  ;;\n            *.tgz)       tar xzf $1  ;;\n            *.zip)       unzip $1    ;;\n            *.Z)         uncompress $1  ;;\n            *.7z)        7z x $1     ;;\n            *)           echo $1 cannot be extracted ;;\n        esac\n    else\n        echo $1 is not a valid file\n    fi\n}\n' >> /root/.bash_aliases
#bash

# Bash completion
sed -i '/# enable bash completion in/,+3{/enable bash completion/!s/^#//}' /etc/bash.bashrc

# Prepare kernel sources (http://www.backtrack-linux.org/wiki/index.php/Preparing_Kernel_Headers)
prepare-kernel-sources; cd /usr/src/linux/; cp -rf include/generated/* include/linux/
fix-splash

# Change location (time & keyboard layout)
dpkg-reconfigure tzdata #<--- Doesn't automate
#dpkg-reconfigure console-setup && fix-splash #<--- Doesn't automate

# At bug (http://redmine.backtrack-linux.org:8080/issues/831)
touch /var/spool/cron/atjobs/.SEQ
chown daemon:daemon /var/spool/cron/atjobs/.SEQ

# Unicornscan bug (http://redmine.backtrack-linux.org:8080/issues/830)
ln -s /usr/share/GeoIP/GeoIP.dat /usr/local/etc/unicornscan/GeoIP.dat
cd /usr/share/GeoIP/
rm -f GeoIP.dat
wget http://geolite.maxmind.com/download/geoip/database/GeoLiteCountry/GeoIP.dat.gz
gunzip GeoIP.dat.gz

# Empty folder (http://redmine.backtrack-linux.org:8080/issues/786)
[ ! "$(ls -A /pentest/web/scanner/ 2>/dev/null)" ] && rm -rf /pentest/web/scanner/

# htshells (http://redmine.backtrack-linux.org:8080/issues/718)
cd /pentest/backdoors/web/
git clone git://github.com/wireghoul/htshells.git

# 10,000 Top/Worst/Common Passwords (http://redmine.backtrack-linux.org:8080/issues/696)
cd /pentest/passwords/wordlists/
wget http://xato.net/files/10k%20most%20common.zip && unzip "10k most common.zip" && rm -f "10k most common.zip"

# Incorrect file permissions (http://redmine.backtrack-linux.org:8080/issues/700)
find /pentest/ -iname readme -perm /u=x,g=x,o=x -exec chmod -x {} \;

# Clean up
apt-get -y clean
apt-get -y autoremove
apt-get -y autoclean
history -C



# Finished!
reboot


# Don't forget to take a snapshot if you're using a VM!





#setup autopsy
#sh -c "cd /pentest/forensics/autopsy/; make; mv /usr/share/applications/backtrack-autopsy.desktop.wait /usr/share/applications/backtrack-autopsy.desktop; rm /usr/share/applications/backtrack-setup-autopsy.desktop;sudo -s" #<--- Doesn't automate

#install truecrypt
#sh -c "/usr/src/truecrypt-7.1a-setup-x*; rm -rf /usr/src/truecrypt-7.1a-setup-*;rm -rf /usr/share/applications/backtrack-truecrypt-install.desktop; mv /usr/share/applications/backtrack-truecrypt.desktop.wait /usr/share/applications/backtrack-truecrypt.desktop"#<--- Doesn't automate

#install atr historical byte applet to jcop
#sh -c "cd /pentest/rfid/RFIDIOt; make install-atr;sudo -s"

#install mifare applet to jcop
#sh -c "cd /pentest/rfid/RFIDIOt; make install-mifare;sudo -s"

#install vonjeek epassport emulator to jcop
#sh -c "cd /pentest/rfid/RFIDIOt; make install-passport;sudo -s"

#install vonjeek epassport emulator to nokia
#sh -c "cd /pentest/rfid/RFIDIOt; make install-passport-nokia;sudo -s"

#freeradius-wpe setup
#sh -c "cd /pentest/wireless/freeradius-wpe/raddb/certs && ./bootstrap && cp -r * /usr/local/etc/raddb/certs;sudo -s"

#unicornscan-pgsql-setup
#sh -c "cd /pentest/scanners/unicornscan; ./setup-unicornscan.sh; sudo -s"

#install ida-pro free
#sh -c "cd /pentest/reverse-engineering/ida-pro-free/; wine idafree50.exe; mv /usr/share/applications/backtrack-ida-pro-free.desktop.wait /usr/share/applications/backtrack-ida-pro-free.desktop; rm /usr/share/applications/backtrack-install-ida-pro-free.desktop" #<--- Doesn't automate