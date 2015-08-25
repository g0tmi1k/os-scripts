#!/bin/bash
#-Metadata----------------------------------------------------#
#  Filename: kali.sh                     (Update: 2015-08-21) #
#-Info--------------------------------------------------------#
#  Personal post-install script for Kali Linux.               #
#-Author(s)---------------------------------------------------#
#  g0tmilk ~ https://blog.g0tmi1k.com/                        #
#-Operating System--------------------------------------------#
#  Designed for: Kali Linux 2.0.0 [x64] (VM - VMware)         #
#     Tested on: Kali Linux 2.0.0 [x64, x84, light, mini, vm] #
#-Licence-----------------------------------------------------#
#  MIT License ~ http://opensource.org/licenses/MIT           #
#-Notes-------------------------------------------------------#
#  Run as root, just after a fresh/clean install of Kali.     #
#                             ---                             #
#  By default it will set the time zone & keyboard to UK/GB.  #
#                             ---                             #
#  Command line arguments:                                    #
#    --burp    = Automates configuring Burp Proxy (Free)      #
#    --dns     = Use Google's DNS and locks permissions       #
#    --hold    = Disable updating certain packages (e.g. msf) #
#    --openvas = Installs & configures OpenVAS vuln scanner   #
#    --osx     = Configures Apple keyboard layout             #
#                                                             #
#    e.g. # bash kali.sh --osx --burp --openvas               #
#                             ---                             #
#  Incomplete/buggy/hidden stuff - search for '***'.          #
#                             ---                             #
#  TODO: External resoureces, check http 200 - else error out - apt/curl/git/wget/axel
#                             ---                             #
#             ** This script is meant for _ME_. **            #
#         ** EDIT this to meet _YOUR_ requirements! **        #
#      ** Wasn't designed with customization in mind. **      #
#-------------------------------------------------------------#


if [ 1 -eq 0 ]; then    # This is never true, thus it acts as block comments ;)
### One liner - Grab the latest version and execute! ###########################
wget -qO /tmp/kali.sh https://raw.github.com/g0tmi1k/os-scripts/master/kali.sh && bash /tmp/kali.sh --osx --dns --burp --openvas --hold
################################################################################
## Shorten URL: >>>   wget -qO- http://bit.do/postkali | bash   <<<
##  Alt Method: curl -s -L -k https://raw.github.com/g0tmi1k/kali-postinstall/master/kali_postinstall.sh > kali.sh | nohup bash
################################################################################
fi


#-Defaults-------------------------------------------------------------#


##### Location information
keyboardApple=false         # Using a Apple/Macintosh keyboard? Change to anything other than 'false' to enable   [ --osx ]
keyboardlayout="gb"         # Great Britain      # curl ifconfig.io/country_code
timezone="Europe/London"    # London, Europe

##### Optional steps
hardenDNS=false             # Set static & lock DNS name server                              [ --dns ]
freezeDEB=false             # Disable updating certain packages (e.g. Metasploit)            [ --hold ]
burpFree=false              # Disable configuring Burp Proxy Free (for Burp Pro users...)    [ --burp ]
openVAS=false               # Install & configure OpenVAS (not everyone wants it...)         [ --openvas ]

##### (Optional) Enable debug mode?
#set -x

##### (Cosmetic) Colour output
RED="\033[01;31m"      # Issues/Errors
GREEN="\033[01;32m"    # Success
YELLOW="\033[01;33m"   # Warnings/Information
BLUE="\033[01;34m"     # Heading
BOLD="\033[01;01m"     # Highlight
RESET="\033[00m"       # Normal


#-Arguments------------------------------------------------------------#


##### Read command line arguments
for x in $( tr '[:upper:]' '[:lower:]' <<< "$@" ); do
  if [ "${x}" == "--osx" ]; then
    keyboardApple=true
  elif [ "${x}" == "--dns" ]; then
    hardenDNS=true
  elif [ "${x}" == "--hold" ]; then
    freezeDEB=true
  elif [ "${x}" == "--burp" ]; then
    burpFree=true
  elif [ "${x}" == "--openvas" ]; then
    openVAS=true
  else
    echo -e ' '${RED}'[!]'${RESET}" Unknown option: ${RED}${x}${RESET}" 1>&2
    exit 1
  fi
done


#-Start----------------------------------------------------------------#


##### Check if we are running as root - else this script will fail (hard!)
if [[ $EUID -ne 0 ]]; then
  echo -e ' '${RED}'[!]'${RESET}" This script must be ${RED}run as root${RESET}. Quitting..." 1>&2
  exit 1
else
  echo -e " $BLUE[*]$RESET Kali Linux post-install script"
fi


##### Display Kali information
kaliVersion=$(lsb_release -a 2>/dev/null | grep Release | awk -F':' '{print $2}' | xargs)
echo -e "\n ${YELLOW}[i]${RESET} Detected: ${YELLOW}Kali Linux ${kaliVersion} ($(uname -m))${RESET}"

if awk "BEGIN {exit $kaliVersion < 2 ? 0 : 1}"; then echo kali is dated;kaliVersion="1"; fi


##### Fixing display output for GUI programs when connecting via SSH
export DISPLAY=:0.0   #[[ -z $SSH_CONNECTION ]] || export DISPLAY=:0.0


if [[ "$kaliVersion" == "1" ]]; then
##### Fixing NetworkManager issues
echo -e "\n ${GREEN}[+]${RESET} Fixing ${GREEN}NetworkManager${RESET} issues"
service network-manager stop
#--- Fix 'device not managed' issue
file=/etc/network/interfaces; [ -e "${file}" ] && cp -n $file{,.bkup}                     # ...or: /etc/NetworkManager/NetworkManager.conf
echo "iface lo inet loopback" > "${file}"   #sed -i '/iface lo inet loopback/q' "${file}"   # ...or: sed -i 's/managed=.*/managed=true/' "${file}"
#service network-manager restart
#--- Fix 'network disabled' issue
rm -f /var/lib/NetworkManager/NetworkManager.state
#--- Wait a little while before trying to connect out again (just to make sure)
sleep 3
service network-manager restart
sleep 10
fi

##### Checking Internet access
echo -e "\n ${GREEN}[+]${RESET} Checking ${GREEN}Internet access${RESET}"
for i in {1..10}; do ping -c 1 -W $i www.google.com &>/dev/null && break; done
if [[ "$?" -ne 0 ]]; then
  echo -e ' '$RED'[!]'$RESET" ${RED}Possible DNS issues${RESET}(?). Trying DHCP 'fix'." 1>&2
  chattr -i /etc/resolv.conf 2>/dev/null
  dhclient
  sleep 15
  _TMP=true
  _CMD="$(ping -c 1 8.8.8.8 &>/dev/null)"
  if [[ "$?" -ne 0 && "$_TMP" == true ]]; then
    _TMP=false
    echo -e ' '${RED}'[!]'${RESET}" ${RED}No Internet access${RESET}. Manually fix the issue & re-run the script." 1>&2
  fi
  _CMD="$(ping -c 1 www.google.com &>/dev/null)"
  if [[ "$?" -ne 0 && "$_TMP" == true ]]; then
    _TMP=false
    echo -e ' '${RED}'[!]'${RESET}" ${RED}Possible DNS issues${RESET}(?). Manually fix the issue & re-run the script." 1>&2
  fi
  if [[ "$_TMP" == false ]]; then
    (dmidecode | grep -iq virtual) && echo -e "${YELLOW}[i]${RESET} VM Detected. ${YELLOW}Try switching network adapter mode${RESET} (NAT/Bridged)."
    echo -e ' '${RED}'[!]'${RESET}" Quitting..." 1>&2
    exit 2
  fi
fi


##### Enabling default network repositories ~ http://docs.kali.org/general-use/kali-linux-sources-list-repositories & Fix 'KEYEXPIRED 1425567400'
echo -e "\n ${GREEN}[+]${RESET} Enabling ${GREEN}default network repositories${RESET} ~ if they were not selected during install"
if [[ "$kaliVersion" == "1" ]]; then
#--- Fixing old keys
#find /var/cache/apt/ -type f -delete
find /var/lib/apt/lists/ -type f -delete                                                                                        # Bug fix: https://forums.kali.org/showthread.php?24687-Problem-with-apt-get-update&p=42558&viewfull=1#post42558
apt-key adv --keyserver hkp://keys.gnupg.net --recv-keys 7D8D0BF6   #gpg --keyserver hkp://keys.gnupg.net --recv-key 7D8D0BF6   # http://docs.kali.org/introduction/download-official-kali-linux-images
fi
#--- Add network repositories
file=/etc/apt/sources.list; [ -e "${file}" ] && cp -n $file{,.bkup}
([[ -e "${file}" && "$(tail -c 1 $file)" != "" ]]) && echo >> "${file}"
grep -q 'kali main non-free contrib' "${file}" 2>/dev/null || echo "deb http://http.kali.org/kali kali main non-free contrib" >> "${file}"
grep -q 'kali/updates main contrib non-free' "${file}" 2>/dev/null || echo "deb http://security.kali.org/kali-security kali/updates main contrib non-free" >> "${file}"
#grep -q 'kali-proposed-updates main contrib non-free' "${file}" 2>/dev/null || echo -e "deb http://repo.kali.org/kali kali-proposed-updates main contrib non-free\ndeb-src http://repo.kali.org/kali kali-proposed-updates main contrib non-free" >> "${file}"
#--- Disable CD repositories
sed -i '/kali/ s/^\( \|\t\|\)deb cdrom/#deb cdrom/g' "${file}"
#--- Update
apt-get -qq update
apt-get -y -qq install kali-archive-keyring || echo -e "${RED}issue with apt${RESET}"   # Fixing old keys


##### Installing kernel headers
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}kernel headers${RESET}"
apt-get -y -qq install gcc make "linux-headers-$(uname -r)"
if [[ $? -ne 0 ]]; then
  echo -e ' '${RED}'[!]'${RESET}" There was an ${RED}issue installing kernel headers${RESET}" 1>&2
  echo -e "${YELLOW}[i]${RESET} Are you using the ${YELLOW}latest kernel?${RESET}"
fi


##### (Optional) Checking to see if Kali is in a VM. If so, install "Virtual Machine Addons/Tools" for a "better" virtual experiment
if [ -e "/etc/vmware-tools" ]; then
  echo -e '\n '$RED'[!]'$RESET' VMware Tools is already installed. Skipping...' 1>&2
elif (dmidecode | grep -iq vmware); then
  ##### Installing virtual machines tools ~ http://docs.kali.org/general-use/install-vmware-tools-kali-guest
  echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}virtual machines tools${RESET}"
  #--- VM -> Install VMware Tools.    Note: you may need to apply a patch: https://github.com/offensive-security/kali-vmware-tools-patches
  mkdir -p /mnt/cdrom/
  umount -f /mnt/cdrom 2>/dev/null
  sleep 2
  mount -o ro /dev/cdrom /mnt/cdrom 2>/dev/null; _mount=$?   # This will only check the first CD drive (if there are multiple bays)
  sleep 2
  file=$(find /mnt/cdrom/ -maxdepth 1 -type f -name 'VMwareTools-*.tar.gz' -print -quit)
  ([[ "$_mount" == 0 && -z "${file}" ]]) && echo -e ' '$RED'[!]'$RESET' Incorrect CD/ISO mounted' 1>&2
  if [[ "$_mount" == 0 && -n "${file}" ]]; then             # If there is a CD in (and its right!), try to install native Guest Additions
    echo -e $YELLOW'[i]'$RESET' Patching & using "native VMware tools"'
    apt-get -y -qq install gcc make "linux-headers-$(uname -r)" git
    git clone git://github.com/rasa/vmware-tools-patches.git /tmp/vmware-tools-patches
    cp -f /mnt/cdrom/VMwareTools-*.tar.gz /tmp/vmware-tools-patches/downloads/
    pushd /tmp/vmware-tools-patches/ >/dev/null
    bash untar-and-patch-and-compile.sh
    popd >/dev/null
    #cp -f /mnt/cdrom/VMwareTools-*.tar.gz /tmp/
    #tar -zxf /tmp/VMwareTools-* -C /tmp/
    #pushd /tmp/vmware-tools-distrib/ >/dev/null
    #echo -e '\n' | timeout 300 perl vmware-install.pl       # Press ENTER for all the default options, wait for 5 minutes to try and install else just quit
    #popd >/dev/null
    umount -f /mnt/cdrom 2>/dev/null
  else                                                       # The fallback is 'open vm tools' ~ http://open-vm-tools.sourceforge.net/about.php
    echo -e ' '$RED'[!]'$RESET' VMware Tools CD/ISO isnt mounted' 1>&2
    echo -e $YELLOW'[i]'$RESET' Skipping "Native VMware Tools", switching to "Open VM Tools" instead'
    apt-get -y -qq install open-vm-toolbox
  fi
  #--- Slow mouse? ~ http://docs.kali.org/general-use/install-vmware-tools-kali-guest
  #apt-get -y -qq install xserver-xorg-input-vmmouse
elif [ -e "/etc/init.d/vboxadd" ]; then
  echo -e '\n '$RED'[!]'$RESET' Virtualbox Guest Additions is already installed. Skipping...' 1>&2
elif (dmidecode | grep -iq virtualbox); then
  ##### (Optional) Installing Virtualbox Guest Additions.   Note: Need VirtualBox 4.2.xx+ (http://docs.kali.org/general-use/kali-linux-virtual-box-guest)
  echo -e "\n ${GREEN}[+]${RESET} (Optional) Installing ${GREEN}Virtualbox Guest Additions${RESET}"
  #--- Devices -> Install Guest Additions CD image...
  mkdir -p /mnt/cdrom/
  umount -f /mnt/cdrom 2>/dev/null
  sleep 1
  mount -o ro /dev/cdrom /mnt/cdrom 2>/dev/null; _mount=$?   # Only checks first CD drive (if multiple)
  if [[ "$_mount" == 0 && ! -e /mnt/cdrom/VBoxLinuxAdditions.run ]]; then
    echo -e ' '$RED'[!]'$RESET' Incorrect CD/ISO mounted. Skipping...' 1>&2
  elif [[ "$_mount" == 0 ]]; then
    apt-get -y -qq install gcc make "linux-headers-$(uname -r)"
    cp -f /mnt/cdrom/VBoxLinuxAdditions.run /tmp/
    chmod -f 0755 /tmp/VBoxLinuxAdditions.run
    /tmp/VBoxLinuxAdditions.run --nox11
    umount -f /mnt/cdrom 2>/dev/null
  fi
fi


###### Checking display resolutions - just for post-install setup ***
#echo -e "\n ${GREEN}[+]${RESET} Checking possible display resolutions"
#export DISPLAY=:0.0   #[[ -z $SSH_CONNECTION ]] || export DISPLAY=:0.0
#current_res=$(xrandr | awk '/\*/ {print $1}')
#if [[ $current_res == "800x600" ]]; then
#  echo -e $YELLOW'[i]'$RESET' Setting display resolution (1152x864) - Only until next reboot!'
#  (xrandr | grep -q 1152x864) && xrandr --size 1152x864
#fi


##### Checking to see if there is a second ethernet card (if so, set an static IP address)
ifconfig eth1 &>/dev/null
if [[ $? == 0 ]]; then
  ##### Setting a static IP address (192.168.155.175/24) on eth1
  echo -e "\n ${GREEN}[+]${RESET} Setting a ${GREEN}static IP address${RESET} (192.168.155.175/24) on eth1"
  ifconfig eth1 192.168.155.175/24
  file=/etc/network/interfaces; [ -e "${file}" ] && cp -n $file{,.bkup}
  grep -q '^iface eth1 inet static' "${file}" 2>/dev/null || cat <<EOF >> "${file}"

auto eth1
iface eth1 inet static
    address 192.168.155.175
    netmask 255.255.255.0
    gateway 192.168.155.1
EOF
fi


##### Setting static & protecting DNS name servers.   Note: May cause issues with forced values (e.g. captive portals etc)
if [ "$hardenDNS" != "false" ]; then
  echo -e "\n ${GREEN}[+]${RESET} Setting static & protecting ${GREEN}DNS name servers${RESEt}"
  file=/etc/resolv.conf; [ -e "${file}" ] && cp -n $file{,.bkup}
  chattr -i "${file}" 2>/dev/null
  #--- Remove duplicate results
  #uniq "${file}" > "$file.new"; mv $file{.new,}
  #--- Use OpenDNS DNS
  #echo -e 'nameserver 208.67.222.222\nnameserver 208.67.220.220' > "${file}"
  #--- Use Google DNS
  echo -e 'nameserver 8.8.8.8\nnameserver 8.8.4.4' > "${file}"
  #--- Add domain
  #echo -e "domain $domainName\n#search $domainName" >> "${file}"
  #--- Protect it
  chattr +i "${file}" 2>/dev/null
else
  echo -e '\n '$RED'[!]'$RESET" ${RED}Skipping DNS${RESET} (missing: '$0 --dns')..." 1>&2
fi


###### Updating hostname (to 'kali') - but not domain name ***
#echo -e "\n ${GREEN}[+]${RESET} Updating ${GREEN}hostname${RESET} (to 'kali')"
#hostname="kali"
##--- Change it now
#hostname "$hostname"
##--- Make sure it sticks after reboot
#file=/etc/hostname; [ -e "${file}" ] && cp -n $file{,.bkup}
#echo "$(hostname)" > "${file}"
##--- Set host file
#file=/etc/hosts; [ -e "${file}" ] && cp -n $file{,.bkup}
#sed -i 's/127.0.1.1.*/127.0.1.1  '$hostname'/' "${file}"    #echo -e "127.0.0.1  localhost.localdomain localhost\n127.0.0.1  $hostname.$domainname $hostname" > "${file}"    #$(hostname) $domainname
##--- Check
##hostname; hostname -f


##### Updating location information - set either value to "" to skip.
echo -e "\n ${GREEN}[+]${RESET} Updating ${GREEN}location information${RESET} ~ keyboard layout & time zone ($keyboardlayout & $timezone)"
[ "$keyboardApple" != "false" ]  && echo -e "\n ${GREEN}[+]${RESET} Applying ${GREEN}Apple hardware${RESET} profile"
#keyboardlayout="gb"          # Great Britain
#timezone="Europe/London"     # London, Europe
#--- Configure keyboard layout
if [ ! -z "$keyboardlayout" ]; then
  file=/etc/default/keyboard; #[ -e "${file}" ] && cp -n $file{,.bkup}
  sed -i 's/XKBLAYOUT=".*"/XKBLAYOUT="'$keyboardlayout'"/' "${file}"
  [ "$keyboardApple" != "false" ] && sed -i 's/XKBVARIANT=".*"/XKBVARIANT="mac"/' "${file}"   # Enable if you are using Apple based products.
  #dpkg-reconfigure -f noninteractive keyboard-configuration   #dpkg-reconfigure console-setup   #dpkg-reconfigure keyboard-configuration -u    # Need to restart xserver for effect
fi
#--- Changing time zone
[ -z "$timezone" ] && timezone=Etc/UTC     #Etc/GMT vs Etc/UTC vs UTC
echo "$timezone" > /etc/timezone           #Etc/GMT vs Etc/UTC vs UTC vs Europe/London
ln -sf "/usr/share/zoneinfo/$(cat /etc/timezone)" /etc/localtime
#dpkg-reconfigure -f noninteractive tzdata
#--- Setting locale
#sed -i 's/^# en_/en_/' /etc/locale.gen   #en_GB en_US
#locale-gen
##echo -e 'LC_ALL=en_US.UTF-8\nLANG=en_US.UTF-8\nLANGUAGE=en_US:en' > /etc/default/locale
#dpkg-reconfigure -f noninteractive tzdata
##locale -a    # Check
#--- Installing ntp
apt-get -qq update
apt-get -y -qq install ntp ntpdate
#--- Configuring ntp
#file=/etc/default/ntp; [ -e "${file}" ] && cp -n $file{,.bkup}
#grep -q "interface=127.0.0.1" "${file}" || sed -i "s/NTPD_OPTS='/NTPD_OPTS='--interface=127.0.0.1 /" "${file}"
#--- Update time
ntpdate -b -s -u pool.ntp.org
#--- Start service
service ntp restart
#--- Remove from start up
update-rc.d ntp remove 2>/dev/null
#--- Check
#date
#--- Only used for stats at the end
start_time=$(date +%s)


if [ "$freezeDEB" != "false" ]; then
  ##### Don't ever update these packages
  echo -e "\n ${GREEN}[+]${RESET} ${GREEN}Don't update${RESET} these packages:"
  for x in metasploit-framework; do
    echo -e " $YELLOW[i]$RESET   + ${x}"
    echo "$x hold" | dpkg --set-selections   # To update: echo "$x install" | dpkg --set-selections
  done
fi


##### Updating OS from repositories
echo -e "\n ${GREEN}[+]${RESET} ${GREEN}Updating OS${RESET} from repositories (this may take a while depending on your Internet connection & Kali version/age)"
for FILE in clean autoremove; do apt-get -y -qq "${FILE}"; done         # Clean up      clean remove autoremove autoclean
export DEBIAN_FRONTEND=noninteractive
apt-get -qq update && apt-get -y -qq dist-upgrade --fix-missing
#--- Enable bleeding edge ~ http://www.kali.org/kali-monday/bleeding-edge-kali-repositories/
#file=/etc/apt/sources.list; [ -e "${file}" ] && cp -n $file{,.bkup}
#grep -q 'kali-bleeding-edge' "${file}" 2>/dev/null || echo -e "\n\n## Bleeding edge\ndeb http://repo.kali.org/kali kali-bleeding-edge main" >> "${file}"
#apt-get -qq update && apt-get -y -qq upgrade
#--- Check kernel stuff
_TMP=$(dpkg -l | grep linux-image- | grep -vc meta)
if [[ "$_TMP" -gt 1 ]]; then
  echo -e "\n $YELLOW[i]$RESET Detected multiple kernels installed"
  #echo -e " $YELLOW[i]$RESET   Clean up: apt-get remove --purge $(dpkg -l 'linux-image-*' | sed '/^ii/!d;/'"$(uname -r | sed "s/\(.*\)-\([^0-9]\+\)/\1/")"'/d;s/^[^ ]* [^ ]* \([^ ]*\).*/\1/;/[0-9]/!d')"   # DO NOT RUN IF NOT USING THE LASTEST KERNEL!
  TMP=$(dpkg -l | grep linux-image | grep -v meta | sort -t '.' -k 2 -g | tail -n 1 | grep "$(uname -r)")
  [[ -z "$_TMP" ]] && echo -e ' '$RED'[!]'$RESET' You are not using the latest kernel' 1>&2 && echo -e " $YELLOW[i]$RESET You have it downloaded & installed, just not using it. You need to **reboot**"
fi
#--- Kali's default tools ~ https://www.kali.org/news/kali-linux-metapackages/
apt-get -y -qq install kali-linux-full


###### Settings services to listen to listen to loopback interface ***
#echo -e "\n ${GREEN}[+]${RESET} Settings services to listen to listen to ${GREEN}loopback interface${RESET}"
#--- Configuring ntp
#file=/etc/default/ntp; [ -e "${file}" ] && cp -n $file{,.bkup}
#grep -q "interface=127.0.0.1" "${file}" || sed -i "s/^NTPD_OPTS='/NTPD_OPTS='--interface=127.0.0.1 /" "${file}"
#service ntp restart
#--- Configuring rpcbind
#file=/etc/default/rpcbind; [ -e "${file}" ] && cp -n $file{,.bkup}
#if [ -e "${file}" ]; then grep -q "127.0.0.1" "${file}" || sed -i 's/OPTIONS="/OPTIONS="-h 127.0.0.1 /' "${file}"; else echo 'OPTIONS="-w -h 127.0.0.1"' > "${file}"; fi
#service ntp rpcbind
#--- Configuring nfs
#file=/etc/default/rpcbind; [ -e "${file}" ] && cp -n $file{,.bkup}
#grep -q "--name 127.0.0.1" "${file}" || sed -i 's/^STATDOPTS=/STATDOPTS="--name 127.0.0.1"/' "${file}"
#service nfs-common restart


##### Fixing audio issues
echo -e "\n ${GREEN}[+]${RESET} Fixing ${GREEN}audio${RESET} issues"
#--- PulseAudio warnings
#file=/etc/default/pulseaudio; [ -e "${file}" ] && cp -n $file{,.bkup}
#sed -i 's/^PULSEAUDIO_SYSTEM_START=.*/PULSEAUDIO_SYSTEM_START=1/' "${file}"
#--- Unmute on startup
apt-get -y -qq install alsa-utils
#--- Set volume now
amixer set Master unmute >/dev/null
amixer set Master 50% >/dev/null


##### Configuring GRUB
echo -e "\n ${GREEN}[+]${RESET} Configuring ${GREEN}GRUB${RESET} ~ boot manager"
(dmidecode | grep -iq virtual) && grubTimeout=1 || grubTimeout=5
file=/etc/default/grub; [ -e "${file}" ] && cp -n $file{,.bkup}
sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT='$grubTimeout'/' "${file}"                   # Time out (lower if in a virtual machine, else possible dual booting)
sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT=""/' "${file}"   # TTY resolution    #GRUB_CMDLINE_LINUX_DEFAULT="vga=0x0318 quiet"   (crashes VM/vmwgfx)
update-grub


###### Disabling login manager (console login - non GUI) ***
#echo -e "\n ${GREEN}[+]${RESET} ${GREEN}Disabling GUI${RESET} login screen"
#--- Disable GUI login screen
#apt-get -y -qq install chkconfig
#chkconfig gdm3 off                                 # ...or: mv -f /etc/rc2.d/S19gdm3 /etc/rc2.d/K17gdm           #file=/etc/X11/default-display-manager; [ -e "${file}" ] && cp -n $file{,.bkup}   #echo /bin/true > "${file}"
#--- Enable auto (gui) login
#file=/etc/gdm3/daemon.conf; [ -e "${file}" ] && cp -n $file{,.bkup}
#sed -i 's/^.*AutomaticLoginEnable = .*/AutomaticLoginEnable = true/' "${file}"
#sed -i 's/^.*AutomaticLogin = .*/AutomaticLogin = root/' "${file}"
#--- Shortcut for when you want to start GUI
#ln -sf /usr/sbin/gdm3 /usr/bin/startx


###### Configuring startup   ***
#echo -e "\n ${GREEN}[+]${RESET} Configuring ${GREEN}startup${RESET} ~ randomize the hostname, eth0 & wlan0s MAC address"
#--- Start up
#file=/etc/rc.local; [ -e "${file}" ] && cp -n $file{,.bkup}
#grep -q "macchanger" "${file}" 2>/dev/null || sed -i 's#^exit 0#for INT in eth0 wlan0; do\n  ifconfig $INT down\n  '$(whereis macchanger)' -r $INT \&\& sleep 3\n  ifconfig $INT up\ndone\n\n\nexit 0#' "${file}"
#grep -q "hostname" "${file}" 2>/dev/null || sed -i 's#^exit 0#'$(whereis hostname)' $(cat /dev/urandom | tr -dc "A-Za-z" | head -c8)\nexit 0#' "${file}"
#--- On demand (*** kinda broken)
##file=/etc/init.d/macchanger; [ -e "${file}" ] && cp -n $file{,.bkup}
##echo -e '#!/bin/bash\nfor INT in eth0 wlan0; do\n  echo "Randomizing: $INT"\n  ifconfig $INT down\n  macchanger -r $INT\n  sleep 3\n  ifconfig $INT up\n  echo "--------------------"\ndone\nexit 0' > "${file}"
##chmod -f 0500 "${file}"
#--- Auto on interface change state (untested)
##file=/etc/network/if-pre-up.d/macchanger; [ -e "${file}" ] && cp -n $file{,.bkup}
##echo -e '#!/bin/bash\n[ "$IFACE" == "lo" ] && exit 0\nifconfig $IFACE down\nmacchanger -r $IFACE\nifconfig $IFACE up\nexit 0' > "${file}"
##chmod -f 0500 "${file}"


##### Configuring GNOME 3
echo -e "\n ${GREEN}[+]${RESET} Configuring ${GREEN}GNOME 3${RESET} ~ desktop environment"
#--- Move bottom panel to top panel
gsettings set org.gnome.gnome-panel.layout toplevel-id-list "['top-panel']"  # ***kali2
dconf write /org/gnome/settings-daemon/plugins/updates/active false   # ***kali2
dconf write /org/gnome/gnome-panel/layout/objects/workspace-switcher/toplevel-id "'top-panel'"
dconf write /org/gnome/gnome-panel/layout/objects/window-list/toplevel-id "'top-panel'"
#--- Panel position
dconf write /org/gnome/gnome-panel/layout/toplevels/top-panel/orientation "'top'"    #"'right'"   # Issue with window-list
#--- Panel ordering
dconf write /org/gnome/gnome-panel/layout/objects/menu-bar/pack-type "'start'"
dconf write /org/gnome/gnome-panel/layout/objects/menu-bar/pack-index 0
dconf write /org/gnome/gnome-panel/layout/objects/window-list/pack-type "'start'"    # "'center'"
dconf write /org/gnome/gnome-panel/layout/objects/window-list/pack-index 5           #0
dconf write /org/gnome/gnome-panel/layout/objects/workspace-switcher/pack-type "'end'"
dconf write /org/gnome/gnome-panel/layout/objects/clock/pack-type "'end'"
dconf write /org/gnome/gnome-panel/layout/objects/user-menu/pack-type "'end'"
dconf write /org/gnome/gnome-panel/layout/objects/notification-area/pack-type "'end'"
dconf write /org/gnome/gnome-panel/layout/objects/workspace-switcher/pack-index 1
dconf write /org/gnome/gnome-panel/layout/objects/clock/pack-index 2
dconf write /org/gnome/gnome-panel/layout/objects/user-menu/pack-index 3
dconf write /org/gnome/gnome-panel/layout/objects/notification-area/pack-index 4
#--- Disable tracker service
gsettings set org.freedesktop.Tracker.Miner.Files crawling-interval -2
gsettings set org.freedesktop.Tracker.Miner.Files enable-monitors false
tracker-control -r
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
file=/etc/gdm3/Init/Default; [ -e "${file}" ] && cp -n $file{,.bkup}     #/etc/rc.local
grep -q '^/usr/bin/numlockx' "${file}" 2>/dev/null || sed -i 's#exit 0#if [ -x /usr/bin/numlockx ]; then\n /usr/bin/numlockx on\nfi\nexit 0#' "${file}"   # GNOME
#--- Change wallpaper & login (happens later)
#wget -q "http://www.kali.org/images/wallpapers-01/kali-wp-june-2014_1920x1080_A.png" -P /usr/share/wallpapers/
#gsettings set org.gnome.desktop.background picture-uri 'file:///usr/share/wallpapers/kali-wp-june-2014_1920x1080_A.png'
#cp -f /usr/share/wallpapers/kali-wp-june-2014_1920x1080_A.png /usr/share/images/desktop-base/login-background.png
#--- Restart GNOME panel to apply/take effect (need to restart xserver for effect)
#timeout 30 killall -q -w gnome-panel >/dev/null && gnome-panel&   # Still need to logoff!


##### Installing & configuring XFCE 4
echo -e "\n ${GREEN}[+]${RESET} Installing & configuring ${GREEN}XFCE 4${RESET}${RESET} ~ desktop environment"
apt-get -y -qq install curl
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
curl --progress -k -L -f "http://xfce-look.org/CONTENT/content-files/142110-Shiki-Colors-Light-Menus.tar.gz" > /tmp/Shiki-Colors-Light-Menus.tar.gz   #***!!! hardcoded path!
tar zxf /tmp/Shiki-Colors-Light-Menus.tar.gz -C /root/.themes/
xfconf-query -c xsettings -p /Net/ThemeName -s "Shiki-Colors-Light-Menus"
xfconf-query -c xsettings -p /Net/IconThemeName -s "gnome-brave"
#--- Enable compositing
xfconf-query -c xfwm4 -p /general/use_compositing -s true
#--- Fix gnome keyring issue
file=/etc/xdg/autostart/gnome-keyring-pkcs11.desktop;   #[ -e "${file}" ] && cp -n $file{,.bkup}
grep -q "XFCE" "${file}" || sed -i 's/^OnlyShowIn=*/OnlyShowIn=XFCE;/' "${file}"
#--- Disable user folders
apt-get -y -qq install xdg-user-dirs
xdg-user-dirs-update
file=/etc/xdg/user-dirs.conf; [ -e "${file}" ] && cp -n $file{,.bkup}
sed -i 's/^enable=.*/enable=False/' "${file}"   #sed -i 's/^XDG_/#XDG_/; s/^#XDG_DESKTOP/XDG_DESKTOP/;' /root/.config/user-dirs.dirs
rm -rf /root/{Documents,Music,Pictures,Public,Templates,Videos}/
xdg-user-dirs-update
#--- Get new desktop wallpaper
mkdir -p /usr/share/wallpapers/
curl --progress -k -L -f "http://www.kali.org/images/wallpapers-01/kali-wp-june-2014_1920x1080_A.png" > /usr/share/wallpapers/kali_blue_3d_a.png    #***!!! hardcoded paths!
curl --progress -k -L -f "http://www.kali.org/images/wallpapers-01/kali-wp-june-2014_1920x1080_B.png" > /usr/share/wallpapers/kali_blue_3d_b.png
curl --progress -k -L -f "http://www.kali.org/images/wallpapers-01/kali-wp-june-2014_1920x1080_G.png" >  /usr/share/wallpapers/kali_black_honeycomb.png
curl --progress -k -L -f "http://imageshack.us/a/img17/4646/vzex.png" >  /usr/share/wallpapers/kali_blue_splat.png
curl --progress -k -L -f "http://em3rgency.com/wp-content/uploads/2012/12/Kali-Linux-faded-no-Dragon-small-text.png" > /usr/share/wallpapers/kali_black_clean.png
curl --progress -k -L -f "http://www.hdwallpapers.im/download/kali_linux-wallpaper.jpg" > /usr/share/wallpapers/kali_black_stripes.jpg
curl --progress -k -L -f "http://fc01.deviantart.net/fs71/f/2011/118/e/3/bt___edb_wallpaper_by_xxdigipxx-d3f4nxv.png" > /usr/share/wallpapers/kali_bt_edb.jpg
_TMP="$(find /usr/share/wallpapers/ -maxdepth 1 -type f \( -name 'kali_*' -o -empty \) | xargs -n1 file | grep -i 'HTML\|empty' | cut -d ':' -f1)"
for FILE in $(echo ${_TMP}); do rm -f "${FILE}"; done
[[ -e "/usr/share/wallpapers/kali_default-1440x900.jpg" ]] && ln -sf /usr/share/wallpapers/kali/contents/images/1440x900.png /usr/share/wallpapers/kali_default-1440x900.jpg
#--- Change desktop wallpaper (single random pick - on each install).   Note: For now...
wallpaper=$(shuf -n1 -e /usr/share/wallpapers/kali_*)   #wallpaper=/usr/share/wallpapers/kali_blue_splat.png
xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/image-show -s true
xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/image-path -s "$wallpaper"
#--- Change login wallpaper
cp -f "$wallpaper" /usr/share/images/desktop-base/login-background.png
#--- Reload XFCE
#/usr/bin/xfdesktop --reload
#--- New wallpaper - add to startup (random each login)
file=/usr/local/bin/wallpaper.sh; [ -e "${file}" ] && cp -n $file{,.bkup}
cat <<EOF > "${file}"
#!/bin/bash

wallpaper="\$(shuf -n1 -e \$(find /usr/share/wallpapers/ -maxdepth 1 -type f -name 'kali_*'))"
xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/image-path -s \$wallpaper
cp -f \$wallpaper /usr/share/images/desktop-base/login-background.png
/usr/bin/xfdesktop --reload
EOF
chmod -f 0500 "${file}"
mkdir -p /root/.config/autostart/
file=/root/.config/autostart/wallpaper.desktop; [ -e "${file}" ] && cp -n $file{,.bkup}
cat <<EOF > "${file}"
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
file=/root/.config/Thunar/thunarrc; [ -e "${file}" ] && cp -n $file{,.bkup}
([[ -e "${file}" && "$(tail -c 1 $file)" != "" ]]) && echo >> "${file}"
sed -i 's/LastShowHidden=.*/LastShowHidden=TRUE/' "${file}" 2>/dev/null || echo -e "[Configuration]\nLastShowHidden=TRUE" > /root/.config/Thunar/thunarrc;
#--- Enable num lock at start up (might not be smart if you're using a smaller keyboard (laptop?)) ~ https://wiki.xfce.org/faq
#xfconf-query -c keyboards -p /Default/Numlock -s true
apt-get -y -qq install numlockx
file=/etc/xdg/xfce4/xinitrc; [ -e "${file}" ] && cp -n $file{,.bkup}     #/etc/rc.local
([[ -e "${file}" && "$(tail -c 1 $file)" != "" ]]) && echo >> "${file}"
grep -q '^/usr/bin/numlockx' "${file}" 2>/dev/null || echo "/usr/bin/numlockx on" >> "${file}"
#--- XFCE fixes for default applications
mkdir -p /root/.local/share/applications/
file=/root/.local/share/applications/mimeapps.list; [ -e "${file}" ] && cp -n $file{,.bkup}
[ ! -e "${file}" ] && echo '[Added Associations]' > "${file}"
([[ -e "${file}" && "$(tail -c 1 $file)" != "" ]]) && echo >> "${file}"
for VALUE in file trash; do
  sed -i 's#x-scheme-handler/'${VALUE}'=.*#x-scheme-handler/'${VALUE}'=exo-file-manager.desktop#' "${file}"
  grep -q '^x-scheme-handler/'${VALUE}'=' "${file}" 2>/dev/null || echo -e 'x-scheme-handler/'${VALUE}'=exo-file-manager.desktop' >> "${file}"
done
for VALUE in http https; do
  sed -i 's#^x-scheme-handler/'${VALUE}'=.*#x-scheme-handler/'${VALUE}'=exo-web-browser.desktop#' "${file}"
  grep -q '^x-scheme-handler/'${VALUE}'=' "${file}" 2>/dev/null || echo -e 'x-scheme-handler/'${VALUE}'=exo-web-browser.desktop' >> "${file}"
done
[[ $(tail -n 1 "${file}") != "" ]] && echo >> "${file}"
file=/root/.config/xfce4/helpers.rc; [ -e "${file}" ] && cp -n $file{,.bkup}    #exo-preferred-applications   #xdg-mime default
sed -i 's#^FileManager=.*#FileManager=Thunar#' "${file}" 2>/dev/null
grep -q '^FileManager=Thunar' "${file}" 2>/dev/null || echo -e 'FileManager=Thunar' >> "${file}"
#--- Remove any old sessions
rm -f /root/.cache/sessions/*
#--- XFCE fixes for GNOME Terminator (We do this later)
#mkdir -p /root/.local/share/xfce4/helpers/
#file=/root/.local/share/xfce4/helpers/custom-TerminalEmulator.desktop; [ -e "${file}" ] && cp -n $file{,.bkup}
#sed -i 's#^X-XFCE-CommandsWithParameter=.*#X-XFCE-CommandsWithParameter=/usr/bin/terminator --command="%s"#' "${file}" 2>/dev/null || echo -e '[Desktop Entry]\nNoDisplay=true\nVersion=1.0\nEncoding=UTF-8\nType=X-XFCE-Helper\nX-XFCE-Category=TerminalEmulator\nX-XFCE-CommandsWithParameter=/usr/bin/terminator --command="%s"\nIcon=terminator\nName=terminator\nX-XFCE-Commands=/usr/bin/terminator' > "${file}"
#file=/root/.config/xfce4/helpers.rc; [ -e "${file}" ] && cp -n $file{,.bkup}    #exo-preferred-applications   #xdg-mime default
#sed -i 's#^TerminalEmulator=.*#TerminalEmulator=custom-TerminalEmulator#' "${file}"
#grep -q '^TerminalEmulator=custom-TerminalEmulator' "${file}" 2>/dev/null || echo -e 'TerminalEmulator=custom-TerminalEmulator' >> "${file}"
#--- Set XFCE as default desktop manager
file=/root/.xsession; [ -e "${file}" ] && cp -n $file{,.bkup}       #~/.xsession
echo xfce4-session > "${file}"
#--- Add keyboard shortcut (CTRL+SPACE) to open Application Finder
file=/root/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml   #; [ -e "${file}" ] && cp -n $file{,.bkup}
grep -q '<property name="&lt;Primary&gt;space" type="string" value="xfce4-appfinder"/>' "${file}" || sed -i 's#<property name="\&lt;Alt\&gt;F2" type="string" value="xfrun4"/>#<property name="\&lt;Alt\&gt;F2" type="string" value="xfrun4"/>\n      <property name="\&lt;Primary\&gt;space" type="string" value="xfce4-appfinder"/>#' "${file}"
#--- Add keyboard shortcut (CTRL+ALT+t) to start a terminal window
file=/root/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml   #; [ -e "${file}" ] && cp -n $file{,.bkup}
grep -q '<property name="&lt;Primary&gt;&lt;Alt&gt;t" type="string" value="/usr/bin/exo-open --launch TerminalEmulator"/>' "${file}" || sed -i 's#<property name="\&lt;Alt\&gt;F2" type="string" value="xfrun4"/>#<property name="\&lt;Alt\&gt;F2" type="string" value="xfrun4"/>\n      <property name="\&lt;Primary\&gt;\&lt;Alt\&gt;t" type="string" value="/usr/bin/exo-open --launch TerminalEmulator"/>#' "${file}"
#--- Create Conky refresh script (conky gets installed later)
file=/usr/local/bin/conky_refresh.sh; [ -e "${file}" ] && cp -n $file{,.bkup}
echo -e '#!/bin/bash\n\n/usr/bin/timeout 5 /usr/bin/killall -9 -q -w conky\n/usr/bin/conky &' > "${file}"
chmod -f 0500 "${file}"
#--- Add keyboard shortcut (CTRL+r) to run the conky refresh script
file=/root/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml   #; [ -e "${file}" ] && cp -n $file{,.bkup}
grep -q '<property name="&lt;Primary&gt;r" type="string" value="/usr/local/bin/conky_refresh.sh"/>' "${file}" || sed -i 's#<property name="\&lt;Alt\&gt;F2" type="string" value="xfrun4"/>#<property name="\&lt;Alt\&gt;F2" type="string" value="xfrun4"/>\n      <property name="\&lt;Primary\&gt;r" type="string" value="/usr/local/bin/conky_refresh.sh"/>#' "${file}"
#--- Remove old temp files
rm -f /tmp/Shiki-Colors-Light-Menus.tar*


##### Configuring file   Note: need to restart xserver for effect
echo -e "\n ${GREEN}[+]${RESET} Configuring ${GREEN}file${RESET} ~ GUI file system navigation"
mkdir -p /root/.config/gtk-2.0/
file=/root/.config/gtk-2.0/gtkfilechooser.ini; [ -e "${file}" ] && cp -n $file{,.bkup}
([[ -e "${file}" && "$(tail -c 1 $file)" != "" ]]) && echo >> "${file}"
sed -i 's/^.*ShowHidden.*/ShowHidden=true/' "${file}" 2>/dev/null || echo -e "\n[Filechooser Settings]\nLocationMode=path-bar\nShowHidden=true\nExpandFolders=false\nShowSizeColumn=true\nGeometryX=66\nGeometryY=39\nGeometryWidth=780\nGeometryHeight=618\nSortColumn=name\nSortOrder=ascending" > "${file}"    #Open/save Window -> Right click -> Show Hidden Files: Enabled
dconf write /org/gnome/nautilus/preferences/show-hidden-files true
file=/root/.gtk-bookmarks; [ -e "${file}" ] && cp -n $file{,.bkup}
([[ -e "${file}" && "$(tail -c 1 $file)" != "" ]]) && echo >> "${file}"
grep -q '^file:///root/Downloads ' "${file}" 2>/dev/null || echo 'file:///root/Downloads Downloads' >> "${file}"
(dmidecode | grep -iq vmware) && (mkdir -p /mnt/hgfs/; grep -q '^file:///mnt/hgfs ' "${file}" 2>/dev/null || echo 'file:///mnt/hgfs VMShare' >> "${file}")
grep -q '^file:///tmp ' "${file}" 2>/dev/null || echo 'file:///tmp TMP' >> "${file}"
grep -q '^file:///usr/local/src ' "${file}" 2>/dev/null || echo 'file:///usr/local/src SRC' >> "${file}"
grep -q '^file:///usr/share ' "${file}" 2>/dev/null || echo 'file:///usr/share Kali Tools' >> "${file}"
grep -q '^file:///var/ftp ' "${file}" 2>/dev/null || echo 'file:///var/ftp FTP' >> "${file}"
grep -q '^file:///var/samba ' "${file}" 2>/dev/null || echo 'file:///var/samba Samba' >> "${file}"
grep -q '^file:///var/tftp ' "${file}" 2>/dev/null || echo 'file:///var/tftp TFTP' >> "${file}"
grep -q '^file:///var/www ' "${file}" 2>/dev/null || echo 'file:///var/www WWW' >> "${file}"


##### Configuring terminal   Note: need to restart xserver for effect
echo -e "\n ${GREEN}[+]${RESET} Configuring GNOME ${GREEN}terminal${RESET} ~ CLI interface"
gconftool-2 --type bool --set /apps/gnome-terminal/profiles/Default/scrollback_unlimited true                   # Terminal -> Edit -> Profile Preferences -> Scrolling -> Scrollback: Unlimited -> Close
gconftool-2 --type string --set /apps/gnome-terminal/profiles/Default/background_darkness 0.85611499999999996   # Not working 100%!
gconftool-2 --type string --set /apps/gnome-terminal/profiles/Default/background_type transparent


##### Configuring bash - all users
echo -e "\n ${GREEN}[+]${RESET} Configuring ${GREEN}bash${RESEt} ~ CLI shell"
file=/etc/bash.bashrc; [ -e "${file}" ] && cp -n $file{,.bkup}    #/root/.bashrc
grep -q "cdspell" "${file}" || echo "shopt -sq cdspell" >> "${file}"             # Spell check 'cd' commands
grep -q "checkwinsize" "${file}" || echo "shopt -sq checkwinsize" >> "${file}"   # Wrap lines correctly after resizing
grep -q "nocaseglob" "${file}" || echo "shopt -sq nocaseglob" >> "${file}"       # Case insensitive pathname expansion
grep -q "HISTSIZE" "${file}" || echo "HISTSIZE=10000" >> "${file}"               # Bash history (memory scroll back)
grep -q "HISTFILESIZE" "${file}" || echo "HISTFILESIZE=10000" >> "${file}"       # Bash history (file .bash_history)
#--- Apply new configs
if [[ "$SHELL" == "/bin/zsh" ]]; then source ~/.zshrc else source "${file}"; fi


##### Installing bash colour - all users
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}bash colour${RESET} ~ colours shell output"
file=/etc/bash.bashrc; [ -e "${file}" ] && cp -n $file{,.bkup}   #/root/.bashrc
([[ -e "${file}" && "$(tail -c 1 $file)" != "" ]]) && echo >> "${file}"
sed -i 's/.*force_color_prompt=.*/force_color_prompt=yes/' "${file}"
grep -q '^force_color_prompt' "${file}" 2>/dev/null || echo 'force_color_prompt=yes' >> "${file}"
sed -i 's#PS1='"'"'.*'"'"'#PS1='"'"'${debian_chroot:+($debian_chroot)}\\[\\033\[01;31m\\]\\u@\\h\\\[\\033\[00m\\]:\\[\\033\[01;34m\\]\\w\\[\\033\[00m\\]\\$ '"'"'#' "${file}"
grep -q "^export LS_OPTIONS='--color=auto'" "${file}" 2>/dev/null || echo "export LS_OPTIONS='--color=auto'" >> "${file}"
grep -q '^eval "$(dircolors)"' "${file}" 2>/dev/null || echo 'eval "$(dircolors)"' >> "${file}"
grep -q "^alias ls='ls $LS_OPTIONS'" "${file}" 2>/dev/null || echo "alias ls='ls $LS_OPTIONS'" >> "${file}"
grep -q "^alias ll='ls $LS_OPTIONS -l'" "${file}" 2>/dev/null || echo "alias ll='ls $LS_OPTIONS -l'" >> "${file}"
grep -q "^alias l='ls $LS_OPTIONS -lA'" "${file}" 2>/dev/null || echo "alias l='ls $LS_OPTIONS -lA'" >> "${file}"
#--- All other users that are made afterwards
file=/etc/skel/.bashrc   #; [ -e "${file}" ] && cp -n $file{,.bkup}
sed -i 's/.*force_color_prompt=.*/force_color_prompt=yes/' "${file}"
#--- Apply new colours
if [[ "$SHELL" == "/bin/zsh" ]]; then source ~/.zshrc else source "${file}"; fi


##### Installing bash completion - all users
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}bash completion${RESET} ~ tab complete CLI commands"
apt-get -y -qq install bash-completion
file=/etc/bash.bashrc; [ -e "${file}" ] && cp -n $file{,.bkup}    #/root/.bashrc
sed -i '/# enable bash completion in/,+7{/enable bash completion/!s/^#//}' "${file}"
#--- Apply new function
if [[ "$SHELL" == "/bin/zsh" ]]; then source ~/.zshrc else source "${file}"; fi


##### Configuring aliases - root user
echo -e "\n ${GREEN}[+]${RESET} Configuring ${GREEN}aliases${RESET} ~ CLI shortcuts"
#--- Enable defaults - root user
for FILE in /etc/bash.bashrc /root/.bashrc /root/.bash_aliases; do    #/etc/profile /etc/bashrc /etc/bash_aliases /etc/bash.bash_aliases
  [[ ! -f "${FILE}" ]] && continue
  cp -n $FILE{,.bkup}
  sed -i 's/#alias/alias/g' "${FILE}"
done
#--- General system ones
file=/root/.bash_aliases; [ -e "${file}" ] && cp -n $file{,.bkup}   #/etc/bash.bash_aliases
([[ -e "${file}" && "$(tail -c 1 $file)" != "" ]]) && echo >> "${file}"
grep -q '^## grep aliases' "${file}" 2>/dev/null || echo -e '## grep aliases\nalias grep="grep --color=always"\nalias ngrep="grep -n"\n' >> "${file}"
grep -q '^alias egrep=' "${file}" 2>/dev/null || echo -e 'alias egrep="egrep --color=auto"\n' >> "${file}"
grep -q '^alias fgrep=' "${file}" 2>/dev/null || echo -e 'alias fgrep="fgrep --color=auto"\n' >> "${file}"
#--- Add in ours (OS programs)
grep -q '^alias tmux' "${file}" 2>/dev/null || echo -e '## tmux\nalias tmux="tmux attach || tmux new"\n' >> "${file}"    #alias tmux="tmux attach -t $HOST || tmux new -s $HOST"
grep -q '^alias axel' "${file}" 2>/dev/null || echo -e '## axel\nalias axel="axel -a"\n' >> "${file}"
grep -q '^alias screen' "${file}" 2>/dev/null || echo -e '## screen\nalias screen="screen -xRR"\n' >> "${file}"
#--- Add in ours (shortcuts)
grep -q '^## Checksums' "${file}" 2>/dev/null || echo -e '## Checksums\nalias sha1="openssl sha1"\nalias md5="openssl md5"\n' >> "${file}"
grep -q '^## Force create folders' "${file}" 2>/dev/null || echo -e '## Force create folders\nalias mkdir="/bin/mkdir -pv"\n' >> "${file}"
#grep -q '^## Mount' "${file}" 2>/dev/null || echo -e '## Mount\nalias mount="mount | column -t"\n' >> "${file}"
grep -q '^## List open ports' "${file}" 2>/dev/null || echo -e '## List open ports\nalias ports="netstat -tulanp"\n' >> "${file}"
grep -q '^## Get header' "${file}" 2>/dev/null || echo -e '## Get header\nalias header="curl -I"\n' >> "${file}"
grep -q '^## Get external IP address' "${file}" 2>/dev/null || echo -e '## Get external IP address\nalias ipx="curl -s http://ipinfo.io/ip"\n' >> "${file}"
grep -q '^## Directory navigation aliases' "${file}" 2>/dev/null || echo -e '## Directory navigation aliases\nalias ..="cd .."\nalias ...="cd ../.."\nalias ....="cd ../../.."\nalias .....="cd ../../../.."\n' >> "${file}"
grep -q '^## Add more aliases' "${file}" 2>/dev/null || echo -e '## Add more aliases\nalias upd="sudo apt-get update"\nalias upg="sudo apt-get upgrade"\nalias ins="sudo apt-get install"\nalias rem="sudo apt-get purge"\nalias fix="sudo apt-get install -f"\n' >> "${file}"
grep -q '^## Extract file' "${file}" 2>/dev/null || echo -e '## Extract file, example. "ex package.tar.bz2"\nex() {\n    if [[ -f $1 ]]; then\n        case $1 in\n            *.tar.bz2)   tar xjf $1  ;;\n            *.tar.gz)    tar xzf $1  ;;\n            *.bz2)       bunzip2 $1  ;;\n            *.rar)       rar x $1    ;;\n            *.gz)        gunzip $1   ;;\n            *.tar)       tar xf $1   ;;\n            *.tbz2)      tar xjf $1  ;;\n            *.tgz)       tar xzf $1  ;;\n            *.zip)       unzip $1    ;;\n            *.Z)         uncompress $1  ;;\n            *.7z)        7z x $1     ;;\n            *)           echo $1 cannot be extracted ;;\n        esac\n    else\n        echo $1 is not a valid file\n    fi\n}\n' >> "${file}"
grep -q '^## strings' "${file}" 2>/dev/null || echo -e '## strings\nalias strings="strings -a"\n' >> "${file}"
grep -q '^## history' "${file}" 2>/dev/null || echo -e '## history\nalias hg="history | grep"\n' >> "${file}"
grep -q '^## DNS - External IP #1' "${file}" 2>/dev/null || echo -e '## DNS - External IP #1\nalias dns1="dig +short @resolver1.opendns.com myip.opendns.com"\n' >> "${file}"
grep -q '^## DNS - External IP #2' "${file}" 2>/dev/null || echo -e '## DNS - External IP #2\nalias dns2="dig +short @208.67.222.222 myip.opendns.com"\n' >> "${file}"
grep -q '^## DNS - Check' "${file}" 2>/dev/null || echo -e '### DNS - Check ("#.abc" is Okay)\nalias dns3="dig +short @208.67.220.220 which.opendns.com txt"\n' >> "${file}"
#alias ll="ls -l --block-size=\'1 --color=auto"
#--- Add in tools
grep -q '^## nmap' "${file}" 2>/dev/null || echo -e '## nmap\nalias nmap="nmap --reason --open"\n' >> "${file}"
grep -q '^## aircrack-ng' "${file}" 2>/dev/null || echo -e '## aircrack-ng\nalias aircrack-ng="aircrack-ng -z"\n' >> "${file}"
grep -q '^## airodump-ng' "${file}" 2>/dev/null || echo -e '## airodump-ng \nalias airodump-ng="airodump-ng --manufacturer --wps --uptime"\n' >> "${file}"    # aircrack-ng 1.2 rc2
grep -q '^## metasploit' "${file}" 2>/dev/null || echo -e '## metasploit\nalias msfc="service postgresql start; service metasploit start; msfconsole -q \"$@\""\n' >> "${file}"
[ "$openVAS" != "false" ] && grep -q '^## openvas' "${file}" 2>/dev/null || echo -e '## openvas\nalias openvas="service openvas-manager restart; service openvas-scanner restart; service greenbone-security-assistant restart; xdg-open https://127.0.0.1:9392/"\n' >> "${file}"
#airmon-vz --verbose
#--- Add in folders
grep -q '^## www' "${file}" 2>/dev/null || echo -e '## www\nalias wwwroot="cd /var/www/"\n' >> "${file}"                                            # service apache2 start
grep -q '^## ftp' "${file}" 2>/dev/null || echo -e '## ftp\nalias ftproot="cd /var/ftp/"\n' >> "${file}"                                            # service pure-ftpd start
grep -q '^## tftp' "${file}" 2>/dev/null || echo -e '## tftp\nalias tftproot="cd /var/tftp/"\n' >> "${file}"                                        # service atftpd start
grep -q '^## smb' "${file}" 2>/dev/null || echo -e '## smb\nalias sambaroot="cd /var/samba/"\n#alias smbroot="cd /var/samba/"\n' >> "${file}"       # service samba start
(dmidecode | grep -iq vmware) && (grep -q '^## vmware' "${file}" 2>/dev/null || echo -e '## vmware\nalias vmroot="cd /mnt/hgfs/"' >> "${file}")
grep -q '^## edb' "${file}" 2>/dev/null || echo -e '## edb\nalias edbroot="cd /opt/exploitdb/"' >> "${file}"
#--- Apply new aliases
if [[ "$SHELL" == "/bin/zsh" ]]; then source ~/.zshrc else source "${file}"; fi
#--- Check
#alias


##### Installing GNOME Terminator
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}GNOME Terminator${RESET} ~ multiple terminals in a single window"
apt-get -y -qq install terminator
#--- Configure terminator
mkdir -p /root/.config/terminator/
file=/root/.config/terminator/config; [ -e "${file}" ] && cp -n $file{,.bkup}
cat <<EOF > "${file}"
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
#--- XFCE fix for terminator
mkdir -p /root/.local/share/xfce4/helpers/
file=/root/.local/share/xfce4/helpers/custom-TerminalEmulator.desktop; [ -e "${file}" ] && cp -n $file{,.bkup}
sed -i 's#^X-XFCE-CommandsWithParameter=.*#X-XFCE-CommandsWithParameter=/usr/bin/terminator --command="%s"#' "${file}" 2>/dev/null || cat <<EOF > "${file}"
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
file=/root/.config/xfce4/helpers.rc; [ -e "${file}" ] && cp -n $file{,.bkup}    #exo-preferred-applications   #xdg-mime default
([[ -e "${file}" && "$(tail -c 1 $file)" != "" ]]) && echo >> "${file}"
sed -i 's#^TerminalEmulator=.*#TerminalEmulator=custom-TerminalEmulator#' "${file}"
grep -q '^TerminalEmulator=custom-TerminalEmulator' "${file}" 2>/dev/null || echo -e 'TerminalEmulator=custom-TerminalEmulator' >> "${file}"


##### Installing ZSH & Oh-My-ZSH - root user.   Note: If you use thurar, 'Open terminal here', will not work.
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}ZSH & Oh-My-ZSH${RESET} ~ unix shell"
#group="sudo"
apt-get -y -qq install zsh git curl
#--- Setup oh-my-zsh
curl --progress -k -L -f "https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh" | zsh    #curl -s -L "https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh"
#--- Configure zsh
file=/root/.zshrc; [ -e "${file}" ] && cp -n $file{,.bkup}   #/etc/zsh/zshrc
([[ -e "${file}" && "$(tail -c 1 $file)" != "" ]]) && echo >> "${file}"
grep -q 'interactivecomments' "${file}" 2>/dev/null || echo 'setopt interactivecomments' >> "${file}"
grep -q 'ignoreeof' "${file}" 2>/dev/null || echo 'setopt ignoreeof' >> "${file}"
grep -q 'correctall' "${file}" 2>/dev/null || echo 'setopt correctall' >> "${file}"
grep -q 'globdots' "${file}" 2>/dev/null || echo 'setopt globdots' >> "${file}"
grep -q '.bash_aliases' "${file}" 2>/dev/null || echo 'source $HOME/.bash_aliases' >> "${file}"
grep -q '/usr/bin/tmux' "${file}" 2>/dev/null || echo '#if ([[ -z "$TMUX" && -n "$SSH_CONNECTION" ]]); then /usr/bin/tmux attach || /usr/bin/tmux new; fi' >> "${file}"   # If not already in tmux and via SSH
#--- Configure zsh (themes) ~ https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
sed -i 's/ZSH_THEME=.*/ZSH_THEME="alanpeabody"/' "${file}"   # Other themes: alanpeabody, jreese,   mh,   candy,   terminalparty, kardan,   nicoulaj, sunaku
#--- Configure oh-my-zsh
sed -i 's/.*DISABLE_AUTO_UPDATE="true"/DISABLE_AUTO_UPDATE="true"/' "${file}"
sed -i 's/plugins=(.*)/plugins=(git tmux last-working-dir)/' "${file}"
#--- Set zsh as default shell (current user)
chsh -s "$(which zsh)"
#--- Use it ~ Not much point to it being a post-install script
#/usr/bin/env zsh      # Use it
#source "${file}"          # Make sure to reload our config
#--- Copy it to other user(s)
#if [ -e "/home/$username/" ]; then   # Will do this later on again, if there isn't already a user
#  cp -f /{root,home/$username}/.zshrc
#  cp -rf /{root,home/$username}/.oh-my-zsh/
#  chown -R $username\:$group /home/$username/.zshrc /home/$username/.oh-my-zsh/
#  chsh "$username" -s "$(which zsh)"
#  sed -i 's#^export ZSH=/.*/.oh-my-zsh#export ZSH=/home/'$username'/.oh-my-zsh#' /home/$username/.zshrc
#fi


##### Installing tmux - all users
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}tmux${RESET} ~ multiplex virtual consoles"
#group="sudo"
#apt-get -y -qq remove screen   # Optional: If we're going to have/use tmux, why have screen?
apt-get -y -qq install tmux
#--- Configure tmux
file=/root/.tmux.conf; [ -e "${file}" ] && cp -n $file{,.bkup}   #/etc/tmux.conf
cat <<EOF > "${file}"
#-Settings---------------------------------------------------------------------
## Make it like screen (use CTRL+a)
unbind C-b
set -g prefix C-a

## Pane switching (SHIFT+ARROWS)
bind-key -n S-Left select-pane -L
bind-key -n S-Right select-pane -R
bind-key -n S-Up select-pane -U
bind-key -n S-Down select-pane -D

## Windows switching (ALT+ARROWS)
bind-key -n M-Left  previous-window
bind-key -n M-Right next-window

## Windows re-ording (SHIFT+ALT+ARROWS)
bind-key -n M-S-Left swap-window -t -1
bind-key -n M-S-Right swap-window -t +1

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
[ -e /bin/zsh ] && echo -e '## Use ZSH as default shell\nset-option -g default-shell /bin/zsh\n' >> "${file}"      # Need to have ZSH installed before running this command/line
cat <<EOF >> "${file}"
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
file=/root/.bash_aliases; [ -e "${file}" ] && cp -n $file{,.bkup}   #/etc/bash.bash_aliases
([[ -e "${file}" && "$(tail -c 1 $file)" != "" ]]) && echo >> "${file}"
grep -q '^alias tmux' "${file}" 2>/dev/null || echo -e '## tmux\nalias tmux="tmux attach || tmux new"\n' >> "${file}"    #alias tmux="tmux attach -t $HOST || tmux new -s $HOST"
#--- Apply new aliases
if [[ "$SHELL" == "/bin/zsh" ]]; then source ~/.zshrc else source "${file}"; fi
#--- Copy it to other user(s) ~
#if [ -e /home/$username/ ]; then   # Will do this later on again, if there isn't already a user
#  cp -f /{etc/,home/$username/.}tmux.conf    #cp -f /{root,home/$username}/.tmux.conf
#  chown $username\:$group /home/$username/.tmux.conf
#  file=/home/$username/.bash_aliases; [ -e "${file}" ] && cp -n $file{,.bkup}
#  grep -q '^alias tmux' "${file}" 2>/dev/null || echo -e '## tmux\nalias tmux="tmux attach || tmux new"\n' >> "${file}"    #alias tmux="tmux attach -t $HOST || tmux new -s $HOST"
#fi
#--- Use it ~ bit pointless if used in a post-install script
#tmux


##### Configuring screen ~ if possible, use tmux instead!
echo -e "\n ${GREEN}[+]${RESET} Configuring ${GREEN}screen${RESET} ~ multiplex virtual consoles"
#apt-get -y -qq install screen
#--- Configure screen
file=/root/.screenrc; [ -e "${file}" ] && cp -n $file{,.bkup}
cat <<EOF > "${file}"
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


##### Installing vim - all users
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}vim${RESET} ~ CLI text editor"
apt-get -y -qq install vim
#--- Configure vim
file=/etc/vim/vimrc; [ -e "${file}" ] && cp -n $file{,.bkup}   #/root/.vimrc
([[ -e "${file}" && "$(tail -c 1 $file)" != "" ]]) && echo >> "${file}"
sed -i 's/.*syntax on/syntax on/' "${file}"
sed -i 's/.*set background=dark/set background=dark/' "${file}"
sed -i 's/.*set showcmd/set showcmd/' "${file}"
sed -i 's/.*set showmatch/set showmatch/' "${file}"
sed -i 's/.*set ignorecase/set ignorecase/' "${file}"
sed -i 's/.*set smartcase/set smartcase/' "${file}"
sed -i 's/.*set incsearch/set incsearch/' "${file}"
sed -i 's/.*set autowrite/set autowrite/' "${file}"
sed -i 's/.*set hidden/set hidden/' "${file}"
sed -i 's/.*set mouse=.*/"set mouse=a/' "${file}"
grep -q '^set number' "${file}" 2>/dev/null || echo 'set number' >> "${file}"                                                                        # Add line numbers
grep -q '^set autoindent' "${file}" 2>/dev/null || echo 'set autoindent' >> "${file}"                                                                # Set auto indent
grep -q '^set expandtab' "${file}" 2>/dev/null || echo -e 'set expandtab\nset smarttab' >> "${file}"                                                 # Set use spaces instead of tabs
grep -q '^set softtabstop' "${file}" 2>/dev/null || echo -e 'set softtabstop=4\nset shiftwidth=4' >> "${file}"                                       # Set 4 spaces as a 'tab'
grep -q '^set foldmethod=marker' "${file}" 2>/dev/null || echo 'set foldmethod=marker' >> "${file}"                                                  # Folding
grep -q '^nnoremap <space> za' "${file}" 2>/dev/null || echo 'nnoremap <space> za' >> "${file}"                                                      # Space toggle folds
grep -q '^set hlsearch' "${file}" 2>/dev/null || echo 'set hlsearch' >> "${file}"                                                                    # Highlight search results
grep -q '^set laststatus' "${file}" 2>/dev/null || echo -e 'set laststatus=2\nset statusline=%F%m%r%h%w\ (%{&ff}){%Y}\ [%l,%v][%p%%]' >> "${file}"   # Status bar
grep -q '^filetype on' "${file}" 2>/dev/null || echo -e 'filetype on\nfiletype plugin on\nsyntax enable\nset grepprg=grep\ -nH\ $*' >> "${file}"     # Syntax highlighting
grep -q '^set wildmenu' "${file}" 2>/dev/null || echo -e 'set wildmenu\nset wildmode=list:longest,full' >> "${file}"                                 # Tab completion
grep -q '^set invnumber' "${file}" 2>/dev/null || echo -e ':nmap <F8> :set invnumber<CR>' >> "${file}"                                               # Toggle line numbers
grep -q '^set pastetoggle=<F9>' "${file}" 2>/dev/null || echo -e 'set pastetoggle=<F9>' >> "${file}"                                                 # Hotkey - turning off auto indent when pasting
grep -q '^:command Q q' "${file}" 2>/dev/null || echo -e ':command Q q' >> "${file}"                                                                 # Fix stupid typo I always make
#--- Set as default editor
export EDITOR="vim"   #update-alternatives --config editor
file=/etc/bash.bashrc; [ -e "${file}" ] && cp -n $file{,.bkup}
([[ -e "${file}" && "$(tail -c 1 $file)" != "" ]]) && echo >> "${file}"
grep -q '^EDITOR' "${file}" 2>/dev/null || echo 'EDITOR="vim"' >> "${file}"
git config --global core.editor "vim"
#--- Set as default mergetool
git config --global merge.tool vimdiff
git config --global merge.conflictstyle diff3
git config --global mergetool.prompt false


##### Setting up iceweasel
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}iceweasel${RESET} ~ GUI web browser"
apt-get install -y -qq unzip curl iceweasel
#--- Configure iceweasel
export DISPLAY=:0.0   #[[ -z $SSH_CONNECTION ]] || export DISPLAY=:0.0
timeout 15 iceweasel   #iceweasel & sleep 15; killall -q -w iceweasel >/dev/null   # Start and kill. Files needed for first time run
timeout 5 killall -9 -q -w iceweasel >/dev/null
file=$(find /root/.mozilla/firefox/*.default*/ -maxdepth 1 -type f -name 'prefs.js' -print -quit) && [ -e "${file}" ] && cp -n $file{,.bkup}   #/etc/iceweasel/pref/*.js
([[ -e "${file}" && "$(tail -c 1 $file)" != "" ]]) && echo >> "${file}"
#sed -i 's/^.network.proxy.socks_remote_dns.*/user_pref("network.proxy.socks_remote_dns", true);' "${file}" 2>/dev/null || echo 'user_pref("network.proxy.socks_remote_dns", true);' >> "${file}"
sed -i 's/^.browser.safebrowsing.enabled.*/user_pref("browser.safebrowsing.enabled", false);' "${file}" 2>/dev/null || echo 'user_pref("browser.safebrowsing.enabled", false);' >> "${file}"                             # Iceweasel -> Edit -> Preferences -> Security -> Block reported web forgeries
sed -i 's/^.browser.safebrowsing.malware.enabled.*/user_pref("browser.safebrowsing.malware.enabled", false);' "${file}" 2>/dev/null || echo 'user_pref("browser.safebrowsing.malware.enabled", false);' >> "${file}"     # Iceweasel -> Edit -> Preferences -> Security -> Block reported attack sites
sed -i 's/^.browser.safebrowsing.remoteLookups.enabled.*/user_pref("browser.safebrowsing.remoteLookups.enabled", false);' "${file}" 2>/dev/null || echo 'user_pref("browser.safebrowsing.remoteLookups.enabled", false);' >> "${file}"
sed -i 's/^.*browser.startup.page.*/user_pref("browser.startup.page", 0);' "${file}" 2>/dev/null || echo 'user_pref("browser.startup.page", 0);' >> "${file}"                                              # Iceweasel -> Edit -> Preferences -> General -> When firefox starts: Show a blank page
sed -i 's/^.*privacy.donottrackheader.enabled.*/user_pref("privacy.donottrackheader.enabled", true);' "${file}" 2>/dev/null || echo 'user_pref("privacy.donottrackheader.enabled", true);' >> "${file}"    # Privacy -> Enable: Tell websites I do not want to be tracked
sed -i 's/^.*browser.showQuitWarning.*/user_pref("browser.showQuitWarning", true);' "${file}" 2>/dev/null || echo 'user_pref("browser.showQuitWarning", true);' >> "${file}"                               # Stop Ctrl+Q from quitting without warning
sed -i 's/^.*extensions.https_everywhere._observatory.popup_shown.*/user_pref("extensions.https_everywhere._observatory.popup_shown", true);' "${file}" 2>/dev/null || echo 'user_pref("extensions.https_everywhere._observatory.popup_shown", true);' >> "${file}"
sed -i 's/^.network.security.ports.banned.override/user_pref("network.security.ports.banned.override", "1-65455");' "${file}" 2>/dev/null || echo 'user_pref("network.security.ports.banned.override", "1-65455");' >> "${file}"    # Remove "This address is restricted"
#--- Replace bookmarks (base: http://pentest-bookmarks.googlecode.com)
file=$(find /root/.mozilla/firefox/*.default*/ -maxdepth 1 -type f -name 'bookmarks.html' -print -quit) && [ -e "${file}" ] && cp -n $file{,.bkup}   #/etc/iceweasel/profile/bookmarks.html
curl --progress -k -L -f "http://pentest-bookmarks.googlecode.com/files/bookmarksv1.5.html" > /tmp/bookmarks_new.html     #***!!! hardcoded version! Need to manually check for updates
#--- Configure bookmarks
awk '!a[$0]++' /tmp/bookmarks_new.html | \egrep -v ">(Latest Headlines|Getting Started|Recently Bookmarked|Recent Tags|Mozilla Firefox|Help and Tutorials|Customize Firefox|Get Involved|About Us|Hacker Media|Bookmarks Toolbar|Most Visited)</" | \egrep -v "^    </DL><p>" | \egrep -v "^<DD>Add" > "${file}"
sed -i 's#^</DL><p>#        </DL><p>\n    </DL><p>\n</DL><p>#' "${file}"                                                          # Fix import issues from pentest-bookmarks...
sed -i 's#^    <DL><p>#    <DL><p>\n    <DT><A HREF="http://127.0.0.1/">localhost</A>#' "${file}"                                 # Add localhost to bookmark toolbar (before hackery folder)
sed -i 's#^</DL><p>#    <DT><A HREF="https://127.0.0.1:8834/">Nessus</A>\n</DL><p>#' "${file}"                                    # Add Nessus UI bookmark toolbar
[ "$openVAS" != "false" ] && sed -i 's#^</DL><p>#    <DT><A HREF="https://127.0.0.1:9392/">OpenVAS</A>\n</DL><p>#' "${file}"      # Add OpenVAS UI to bookmark toolbar
#sed -i 's#^</DL><p>#    <DT><A HREF="https://127.0.0.1:3780/">Nexpose</A>\n</DL><p>#' "${file}"                                  # Add Nexpose UI to bookmark toolbar
sed -i 's#^</DL><p>#    <DT><A HREF="https://127.0.0.1:3790/">MSF</A>\n</DL><p>#' "${file}"                                       # Add Metasploit UI to bookmark toolbar
sed -i 's#^</DL><p>#    <DT><A HREF="http://127.0.0.1:3000/ui/panel">BeEF</A>\n</DL><p>#' "${file}"                               # Add BeEF UI to bookmark toolbar
sed -i 's#^</DL><p>#    <DT><A HREF="http://127.0.0.1/rips/">RIPS</A>\n</DL><p>#' "${file}"                                       # Add RIPs to bookmark toolbar
sed -i 's#^</DL><p>#    <DT><A HREF="https://paulschou.com/tools/xlate/">XLATE</A>\n</DL><p>#' "${file}"                          # Add XLATE to bookmark toolbar
sed -i 's#^</DL><p>#    <DT><A HREF="https://hackvertor.co.uk/public">HackVertor</A>\n</DL><p>#' "${file}"                        # Add HackVertor to bookmark toolbar
sed -i 's#^</DL><p>#    <DT><A HREF="http://www.irongeek.com/skiddypad.php">SkiddyPad</A>\n</DL><p>#' "${file}"                   # Add Skiddypad to bookmark toolbar
sed -i 's#^</DL><p>#    <DT><A HREF="https://www.exploit-db.com/search/">Exploit-DB</A>\n</DL><p>#' "${file}"                     # Add Exploit-DB to bookmark toolbar
sed -i 's#^</DL><p>#    <DT><A HREF="http://offset-db.com/">Offset-DB</A>\n</DL><p>#' "${file}"                                   # Add offset-db to bookmark toolbar
#sed -i 's#^</DL><p>#    <DT><A HREF="http://shell-storm.org/shellcode/">Shelcodes</A>\n</DL><p>#' "${file}"                      # Add shellcode to bookmark toolbar
#sed -i 's#^</DL><p>#    <DT><A HREF="http://ropshell.com/">ROP Shell</A>\n</DL><p>#' "${file}"                                   # Add ROP Shell to bookmark toolbar
sed -i 's#^</DL><p>#    <DT><A HREF="https://ifconfig.io/">ifconfig</A>\n</DL><p>#' "${file}"                                     # Add ifconfig.io to bookmark toolbar
sed -i 's#<HR>#<DT><H3 ADD_DATE="1303667175" LAST_MODIFIED="1303667175" PERSONAL_TOOLBAR_FOLDER="true">Bookmarks Toolbar</H3>\n<DD>Add bookmarks to this folder to see them displayed on the Bookmarks Toolbar#' "${file}"
#--- Clear bookmark cache
find /root/.mozilla/firefox/*.default*/ -maxdepth 1 -mindepth 1 -type f -name places.sqlite -delete
find /root/.mozilla/firefox/*.default*/bookmarkbackups/ -type f -delete
#--- Download extensions
ffpath="$(find /root/.mozilla/firefox/*.default*/ -maxdepth 0 -mindepth 0 -type d -name '*.default*' -print -quit)/extensions"
[ "$ffpath" == "/extensions" ] && echo -e ' '$RED'[!]'$RESET" Couldn't find Firefox/Iceweasel folder" 1>&2
mkdir -p "$ffpath/"
#curl --progress -k -L -f "https://github.com/mozmark/ringleader/blob/master/fx_pnh.xpi?raw=true"                                                                                             # plug-n-hack
#curl --progress -k -L -f "https://addons.mozilla.org/firefox/downloads/latest/284030/addon-284030-latest.xpi?src=dp-btn-primary" -o "$ffpath/{6bdc61ae-7b80-44a3-9476-e1d121ec2238}.xpi"     # HTTPS Finder
curl --progress -k -L -f "https://addons.mozilla.org/firefox/downloads/latest/5817/addon-5817-latest.xpi?src=dp-btn-primary" -o "$ffpath/SQLiteManager@mrinalkant.blogspot.com.xpi"           # SQLite Manager
curl --progress -k -L -f "https://addons.mozilla.org/firefox/downloads/latest/1865/addon-1865-latest.xpi?src=dp-btn-primary" -o "$ffpath/{d10d0bf8-f5b5-c8b4-a8b2-2b9879e08c5d}.xpi"          # Adblock Plus
curl --progress -k -L -f "https://addons.mozilla.org/firefox/downloads/latest/92079/addon-92079-latest.xpi?src=dp-btn-primary" -o "$ffpath/{bb6bc1bb-f824-4702-90cd-35e2fb24f25d}.xpi"        # Cookies Manager+
curl --progress -k -L -f "https://addons.mozilla.org/firefox/downloads/latest/1843/addon-1843-latest.xpi?src=dp-btn-primary" -o "$ffpath/firebug@software.joehewitt.com.xpi"                  # Firebug
curl --progress -k -L -f "https://addons.mozilla.org/firefox/downloads/latest/15023/addon-15023-latest.xpi?src=dp-btn-primary" -o "$ffpath/foxyproxy-basic@eric.h.jung.xpi"                   # FoxyProxy Basic
curl --progress -k -L -f "https://addons.mozilla.org/firefox/downloads/latest/429678/addon-429678-latest.xpi?src=dp-btn-primary" -o "$ffpath/useragentoverrider@qixinglu.com.xpi"             # User Agent Overrider
curl --progress -k -L -f "https://www.eff.org/files/https-everywhere-latest.xpi" -o "$ffpath/https-everywhere@eff.org.xpi"                                                                    # HTTPS Everywhere
curl --progress -k -L -f "https://addons.mozilla.org/firefox/downloads/latest/3829/addon-3829-latest.xpi?src=dp-btn-primary" -o "$ffpath/{8f8fe09b-0bd3-4470-bc1b-8cad42b8203a}.xpi"          # Live HTTP Headers
curl --progress -k -L -f "https://addons.mozilla.org/firefox/downloads/latest/966/addon-966-latest.xpi?src=dp-btn-primary" -o "$ffpath/{9c51bd27-6ed8-4000-a2bf-36cb95c0c947}.xpi"            # Tamper Data
curl --progress -k -L -f "https://addons.mozilla.org/firefox/downloads/latest/300254/addon-300254-latest.xpi?src=dp-btn-primary" -o "$ffpath/check-compatibility@dactyl.googlecode.com.xpi"   # Disable Add-on Compatibility Checks
#--- Installing extensions
for FILE in $(find "${ffpath}" -maxdepth 1 -type f -name '*.xpi'); do
  d="$(basename "${FILE}" .xpi)"
  mkdir -p "${ffpath}/${d}/"
  unzip -q -o -d "${ffpath}/${d}/" "${FILE}"
  rm -f "${FILE}"
done
#--- Enable Iceweasel's addons/plugins/extensions
timeout 15 iceweasel   #iceweasel & sleep 15; killall -q -w iceweasel >/dev/null
sleep 3
file=$(find /root/.mozilla/firefox/*.default*/ -maxdepth 1 -type f -name 'extensions.sqlite' -print -quit)   #&& [ -e "${file}" ] && cp -n $file{,.bkup}
if [ ! -e "${file}" ] || [ -z "${file}" ]; then
  #echo -e ' '$RED'[!]'$RESET" Something went wrong enabling Iceweasel's extensions via method #1. Trying method #2..." 1>&2
  false
else
  echo -e " ${YELLOW}[i]${RESET} Enabled ${YELLOW}Iceweasel's extensions${RESET} (via method #1!)"
  apt-get install -y -qq sqlite3
  rm -f /tmp/iceweasel.sql; touch /tmp/iceweasel.sql
  echo "UPDATE 'main'.'addon' SET 'active' = 1, 'userDisabled' = 0;" > /tmp/iceweasel.sql    # Force them all!
  sqlite3 "${file}" < /tmp/iceweasel.sql      #fuser extensions.sqlite
fi
file=$(find /root/.mozilla/firefox/*.default*/ -maxdepth 1 -type f -name 'extensions.json' -print -quit)   #&& [ -e "${file}" ] && cp -n $file{,.bkup}
if [ ! -e "${file}" ] || [ -z "${file}" ]; then
  #echo -e ' '$RED'[!]'$RESET" Something went wrong enabling Iceweasel's extensions via method #2. Did method #1 also fail?" 1>&2
  false
else
  echo -e " ${YELLOW}[i]${RESET} Enabled ${YELLOW}Iceweasel's extensions${RESET} (via method #2!)"
  sed -i 's/"active":false,/"active":true,/g' "${file}"                # Force them all!
  sed -i 's/"userDisabled":true,/"userDisabled":false,/g' "${file}"    # Force them all!
fi
file=$(find /root/.mozilla/firefox/*.default*/ -maxdepth 1 -type f -name 'prefs.js' -print -quit)   #&& [ -e "${file}" ] && cp -n $file{,.bkup}
[ ! -z "${file}" ] && sed -i '/extensions.installCache/d' "${file}"
timeout 15 iceweasel >/dev/null   # For extensions that just work without restarting
sleep 3
timeout 15 iceweasel >/dev/null   # ...for (most) extensions, as they need iceweasel to restart
sleep 3
#--- Configure foxyproxy
file=$(find /root/.mozilla/firefox/*.default*/ -maxdepth 1 -type f -name 'foxyproxy.xml' -print -quit)   #&& [ -e "${file}" ] && cp -n $file{,.bkup}
if [ -z "${file}" ]; then
  echo -e ' '$RED'[!]'$RESET' Something went wrong with the foxyproxy iceweasel extension (did any extensions install?). Skipping...' 1>&2
elif [ -e "${file}" ]; then
  grep -q 'localhost:8080' "${file}" 2>/dev/null || sed -i 's#<proxy name="Default"#<proxy name="localhost:8080" id="1145138293" notes="e.g. Burp, w3af" fromSubscription="false" enabled="true" mode="manual" selectedTabIndex="0" lastresort="false" animatedIcons="true" includeInCycle="false" color="\#07753E" proxyDNS="true" noInternalIPs="false" autoconfMode="pac" clearCacheBeforeUse="true" disableCache="true" clearCookiesBeforeUse="false" rejectCookies="false"><matches/><autoconf url="" loadNotification="true" errorNotification="true" autoReload="false" reloadFreqMins="60" disableOnBadPAC="true"/><autoconf url="http://wpad/wpad.dat" loadNotification="true" errorNotification="true" autoReload="false" reloadFreqMins="60" disableOnBadPAC="true"/><manualconf host="127.0.0.1" port="8080" socksversion="5" isSocks="false" username="" password="" domain=""/></proxy><proxy name="Default"#' "${file}"          # localhost:8080
  grep -q 'localhost:8081' "${file}" 2>/dev/null || sed -i 's#<proxy name="Default"#<proxy name="localhost:8081 (socket5)" id="212586674" notes="e.g. SSH" fromSubscription="false" enabled="true" mode="manual" selectedTabIndex="0" lastresort="false" animatedIcons="true" includeInCycle="false" color="\#917504" proxyDNS="true" noInternalIPs="false" autoconfMode="pac" clearCacheBeforeUse="true" disableCache="true" clearCookiesBeforeUse="false" rejectCookies="false"><matches/><autoconf url="" loadNotification="true" errorNotification="true" autoReload="false" reloadFreqMins="60" disableOnBadPAC="true"/><autoconf url="http://wpad/wpad.dat" loadNotification="true" errorNotification="true" autoReload="false" reloadFreqMins="60" disableOnBadPAC="true"/><manualconf host="127.0.0.1" port="8081" socksversion="5" isSocks="true" username="" password="" domain=""/></proxy><proxy name="Default"#' "${file}"         # localhost:8081 (socket5)
  grep -q '"No Caching"' "${file}" 2>/dev/null   || sed -i 's#<proxy name="Default"#<proxy name="No Caching" id="3884644610" notes="" fromSubscription="false" enabled="true" mode="system" selectedTabIndex="0" lastresort="false" animatedIcons="true" includeInCycle="false" color="\#990DA6" proxyDNS="true" noInternalIPs="false" autoconfMode="pac" clearCacheBeforeUse="true" disableCache="true" clearCookiesBeforeUse="false" rejectCookies="false"><matches/><autoconf url="" loadNotification="true" errorNotification="true" autoReload="false" reloadFreqMins="60" disableOnBadPAC="true"/><autoconf url="http://wpad/wpad.dat" loadNotification="true" errorNotification="true" autoReload="false" reloadFreqMins="60" disableOnBadPAC="true"/><manualconf host="" port="" socksversion="5" isSocks="false" username="" password="" domain=""/></proxy><proxy name="Default"#' "${file}"                                          # No caching
else
  echo -ne '<?xml version="1.0" encoding="UTF-8"?>\n<foxyproxy mode="disabled" selectedTabIndex="0" toolbaricon="true" toolsMenu="true" contextMenu="true" advancedMenus="false" previousMode="disabled" resetIconColors="true" useStatusBarPrefix="true" excludePatternsFromCycling="false" excludeDisabledFromCycling="false" ignoreProxyScheme="false" apiDisabled="false" proxyForVersionCheck=""><random includeDirect="false" includeDisabled="false"/><statusbar icon="true" text="false" left="options" middle="cycle" right="contextmenu" width="0"/><toolbar left="options" middle="cycle" right="contextmenu"/><logg enabled="false" maxSize="500" noURLs="false" header="&lt;?xml version=&quot;1.0&quot; encoding=&quot;UTF-8&quot;?&gt;\n&lt;!DOCTYPE html PUBLIC &quot;-//W3C//DTD XHTML 1.0 Strict//EN&quot; &quot;http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd&quot;&gt;\n&lt;html xmlns=&quot;http://www.w3.org/1999/xhtml&quot;&gt;&lt;head&gt;&lt;title&gt;&lt;/title&gt;&lt;link rel=&quot;icon&quot; href=&quot;http://getfoxyproxy.org/favicon.ico&quot;/&gt;&lt;link rel=&quot;shortcut icon&quot; href=&quot;http://getfoxyproxy.org/favicon.ico&quot;/&gt;&lt;link rel=&quot;stylesheet&quot; href=&quot;http://getfoxyproxy.org/styles/log.css&quot; type=&quot;text/css&quot;/&gt;&lt;/head&gt;&lt;body&gt;&lt;table class=&quot;log-table&quot;&gt;&lt;thead&gt;&lt;tr&gt;&lt;td class=&quot;heading&quot;&gt;${timestamp-heading}&lt;/td&gt;&lt;td class=&quot;heading&quot;&gt;${url-heading}&lt;/td&gt;&lt;td class=&quot;heading&quot;&gt;${proxy-name-heading}&lt;/td&gt;&lt;td class=&quot;heading&quot;&gt;${proxy-notes-heading}&lt;/td&gt;&lt;td class=&quot;heading&quot;&gt;${pattern-name-heading}&lt;/td&gt;&lt;td class=&quot;heading&quot;&gt;${pattern-heading}&lt;/td&gt;&lt;td class=&quot;heading&quot;&gt;${pattern-case-heading}&lt;/td&gt;&lt;td class=&quot;heading&quot;&gt;${pattern-type-heading}&lt;/td&gt;&lt;td class=&quot;heading&quot;&gt;${pattern-color-heading}&lt;/td&gt;&lt;td class=&quot;heading&quot;&gt;${pac-result-heading}&lt;/td&gt;&lt;td class=&quot;heading&quot;&gt;${error-msg-heading}&lt;/td&gt;&lt;/tr&gt;&lt;/thead&gt;&lt;tfoot&gt;&lt;tr&gt;&lt;td/&gt;&lt;/tr&gt;&lt;/tfoot&gt;&lt;tbody&gt;" row="&lt;tr&gt;&lt;td class=&quot;timestamp&quot;&gt;${timestamp}&lt;/td&gt;&lt;td class=&quot;url&quot;&gt;&lt;a href=&quot;${url}&quot;&gt;${url}&lt;/a&gt;&lt;/td&gt;&lt;td class=&quot;proxy-name&quot;&gt;${proxy-name}&lt;/td&gt;&lt;td class=&quot;proxy-notes&quot;&gt;${proxy-notes}&lt;/td&gt;&lt;td class=&quot;pattern-name&quot;&gt;${pattern-name}&lt;/td&gt;&lt;td class=&quot;pattern&quot;&gt;${pattern}&lt;/td&gt;&lt;td class=&quot;pattern-case&quot;&gt;${pattern-case}&lt;/td&gt;&lt;td class=&quot;pattern-type&quot;&gt;${pattern-type}&lt;/td&gt;&lt;td class=&quot;pattern-color&quot;&gt;${pattern-color}&lt;/td&gt;&lt;td class=&quot;pac-result&quot;&gt;${pac-result}&lt;/td&gt;&lt;td class=&quot;error-msg&quot;&gt;${error-msg}&lt;/td&gt;&lt;/tr&gt;" footer="&lt;/tbody&gt;&lt;/table&gt;&lt;/body&gt;&lt;/html&gt;"/><warnings/><autoadd enabled="false" temp="false" reload="true" notify="true" notifyWhenCanceled="true" prompt="true"><match enabled="true" name="Dynamic AutoAdd Pattern" pattern="*://${3}${6}/*" isRegEx="false" isBlackList="false" isMultiLine="false" caseSensitive="false" fromSubscription="false"/><match enabled="true" name="" pattern="*You are not authorized to view this page*" isRegEx="false" isBlackList="false" isMultiLine="true" caseSensitive="false" fromSubscription="false"/></autoadd><quickadd enabled="false" temp="false" reload="true" notify="true" notifyWhenCanceled="true" prompt="true"><match enabled="true" name="Dynamic QuickAdd Pattern" pattern="*://${3}${6}/*" isRegEx="false" isBlackList="false" isMultiLine="false" caseSensitive="false" fromSubscription="false"/></quickadd><defaultPrefs origPrefetch="null"/><proxies>' > "${file}"
  echo -ne '<proxy name="localhost:8080" id="1145138293" notes="e.g. Burp, w3af" fromSubscription="false" enabled="true" mode="manual" selectedTabIndex="0" lastresort="false" animatedIcons="true" includeInCycle="false" color="#07753E" proxyDNS="true" noInternalIPs="false" autoconfMode="pac" clearCacheBeforeUse="true" disableCache="true" clearCookiesBeforeUse="false" rejectCookies="false"><matches/><autoconf url="" loadNotification="true" errorNotification="true" autoReload="false" reloadFreqMins="60" disableOnBadPAC="true"/><autoconf url="http://wpad/wpad.dat" loadNotification="true" errorNotification="true" autoReload="false" reloadFreqMins="60" disableOnBadPAC="true"/><manualconf host="127.0.0.1" port="8080" socksversion="5" isSocks="false" username="" password="" domain=""/></proxy>' >> "${file}"
  echo -ne '<proxy name="localhost:8081 (socket5)" id="212586674" notes="e.g. SSH" fromSubscription="false" enabled="true" mode="manual" selectedTabIndex="0" lastresort="false" animatedIcons="true" includeInCycle="false" color="#917504" proxyDNS="true" noInternalIPs="false" autoconfMode="pac" clearCacheBeforeUse="true" disableCache="true" clearCookiesBeforeUse="false" rejectCookies="false"><matches/><autoconf url="" loadNotification="true" errorNotification="true" autoReload="false" reloadFreqMins="60" disableOnBadPAC="true"/><autoconf url="http://wpad/wpad.dat" loadNotification="true" errorNotification="true" autoReload="false" reloadFreqMins="60" disableOnBadPAC="true"/><manualconf host="127.0.0.1" port="8081" socksversion="5" isSocks="true" username="" password="" domain=""/></proxy>' >> "${file}"
  echo -ne '<proxy name="No Caching" id="3884644610" notes="" fromSubscription="false" enabled="true" mode="system" selectedTabIndex="0" lastresort="false" animatedIcons="true" includeInCycle="false" color="#990DA6" proxyDNS="true" noInternalIPs="false" autoconfMode="pac" clearCacheBeforeUse="true" disableCache="true" clearCookiesBeforeUse="false" rejectCookies="false"><matches/><autoconf url="" loadNotification="true" errorNotification="true" autoReload="false" reloadFreqMins="60" disableOnBadPAC="true"/><autoconf url="http://wpad/wpad.dat" loadNotification="true" errorNotification="true" autoReload="false" reloadFreqMins="60" disableOnBadPAC="true"/><manualconf host="" port="" socksversion="5" isSocks="false" username="" password="" domain=""/></proxy>' >> "${file}"
  echo -ne '<proxy name="Default" id="3377581719" notes="" fromSubscription="false" enabled="true" mode="direct" selectedTabIndex="0" lastresort="true" animatedIcons="false" includeInCycle="true" color="#0055E5" proxyDNS="true" noInternalIPs="false" autoconfMode="pac" clearCacheBeforeUse="false" disableCache="false" clearCookiesBeforeUse="false" rejectCookies="false"><matches><match enabled="true" name="All" pattern="*" isRegEx="false" isBlackList="false" isMultiLine="false" caseSensitive="false" fromSubscription="false"/></matches><autoconf url="" loadNotification="true" errorNotification="true" autoReload="false" reloadFreqMins="60" disableOnBadPAC="true"/><autoconf url="http://wpad/wpad.dat" loadNotification="true" errorNotification="true" autoReload="false" reloadFreqMins="60" disableOnBadPAC="true"/><manualconf host="" port="" socksversion="5" isSocks="false" username="" password=""/></proxy>' >> "${file}"
  echo -e '</proxies></foxyproxy>' >> "${file}"
fi
#--- Wipe session (due to force close)
find /root/.mozilla/firefox/*.default*/ -maxdepth 1 -type f -name 'sessionstore.*' -delete
#--- Remove old temp files
rm -f /tmp/iceweasel.sql
rm -f /tmp/bookmarks_new.html


##### Installing conky
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}conky${RESET} ~ GUI desktop monitor"
apt-get -y -qq install conky
#--- Configure conky
file=/root/.conkyrc; [ -e "${file}" ] && cp -n $file{,.bkup}
cat <<EOF > "${file}"
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
\${color white}RAM\$color  \$alignr\$memperc%  \${membar 6,170}\$color
\${color white}Swap\$color  \$alignr\$swapperc%  \${swapbar 6,170}\$color

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
ifconfig eth1 &>/devnull && cat <<EOF >> "${file}"
\${color dodgerblue3}LAN eth1 (\${addr eth1}) \${hr 2}\$color
\${color white}Down\$color:  \${downspeed eth1} KB/s\${alignr}\${color white}Up\$color: \${upspeed eth1} KB/s
\${color white}Downloaded\$color: \${totaldown eth1} \${alignr}\${color white}Uploaded\$color: \${totalup eth1}
\${downspeedgraph eth1 25,120 000000 00ff00} \${alignr}\${upspeedgraph eth1 25,120 000000 ff0000}\$color
EOF
cat <<EOF >> "${file}"
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
file=/usr/local/bin/conky.sh; [ -e "${file}" ] && cp -n $file{,.bkup}
echo -e '#!/bin/bash\n\ntimeout 10 killall -q conky\nsleep 15\nconky &' > "${file}"
chmod -f 0500 "${file}"
mkdir -p /root/.config/autostart/
file=/root/.config/autostart/conkyscript.desktop; [ -e "${file}" ] && cp -n $file{,.bkup}
cat <<EOF > "${file}"
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


##### Installing metasploit ~ http://docs.kali.org/general-use/starting-metasploit-framework-in-kali
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}metasploit${RESET} ~ exploit framework"
apt-get -y -qq install metasploit 2>/dev/null || echo -e "${RED}issue with apt${RESET}"   #metasploit = msf pro, metasploit-framework = free stuff
#--- ASCII art
export GOCOW=1   # Always a cow logo ;)   Others: THISISHALLOWEEN (Halloween), APRILFOOLSPONIES (My Little Pony)
file=/root/.bashrc; [ -e "${file}" ] && cp -n $file{,.bkup}
([[ -e "${file}" && "$(tail -c 1 $file)" != "" ]]) && echo >> "${file}"
grep -q '^GOCOW' "${file}" 2>/dev/null || echo 'GOCOW=1' >> "${file}"
#--- Start services
service postgresql start   #service postgresql restart
service metasploit start   #service metasploit restart ***kali2
msfdb start && msfdb init  #***kali2 reinit if goes wrong
sleep 10
#--- Metasploit 4.10.x+ database fix #1 ~ https://community.rapid7.com/community/metasploit/blog/2014/08/25/not-reinventing-the-wheel
#mkdir -p /root/.msf4/
#ln -sf /opt/metasploit/apps/pro/ui/config/database.yml /root/.msf4/database.yml   #cp -f   #find / -name database.yml -type f | grep metasploit | grep -v gems   # /usr/share/metasploit-framework/config/database.yml
#--- Metasploit 4.10.x+ database fix #2 ~ Using method #1, so this isn't needed
file=/root/.bash_aliases; [ -e "${file}" ] && cp -n $file{,.bkup}   #/etc/bash.bash_aliasesa
#grep -q '^alias msfconsole' "${file}" 2>/dev/null || echo -e '## Metasploit Framework\nalias msfconsole="msfconsole db_connect -y /opt/metasploit/apps/pro/ui/config/database.yml"\n' >> "${file}"
grep -q '^## metasploit' "${file}" 2>/dev/null || echo -e '## metasploit\nalias msfc="service postgresql start; service metasploit start; msfconsole -q \"$@\""\n' >> "${file}"
#--- Apply new alias
if [[ "$SHELL" == "/bin/zsh" ]]; then source ~/.zshrc else source "${file}"; fi
#--- Autorun Metasploit commands each startup
mkdir -p /root/.msf4/
mkdir -p /root/.msf4/modules/
file=/root/.msf4/msf_autorunscript.rc; [ -e "${file}" ] && cp -n $file{,.bkup}
cat <<EOF > "${file}"
#run post/windows/escalate/getsystem

#run migrate -f -k
#run migrate -n "explorer.exe" -k    # Can trigger AV alerts by touching explorer.exe...

#run post/windows/manage/smart_migrate
#run post/windows/gather/smart_hashdump
EOF
file=/root/.msf4/msfconsole.rc; [ -e "${file}" ] && cp -n $file{,.bkup}
#load sounds verbose=true
#load auto_add_route
#load alias
#alias dir/ls    del/rm  auto handler   https://github.com/rapid7/metasploit-framework/tree/master/plugins // https://github.com/rapid7/metasploit-framework/issues/5107
cat <<EOF > "${file}"
setg TimestampOutput true
setg VERBOSE true

use exploit/multi/handler
set AutoRunScript 'multi_console_command -rc "/root/.msf4/msf_autorunscript.rc"'
set ExitOnSession false
set EnableStageEncoding true
set PAYLOAD windows/meterpreter/reverse_https
set LHOST 0.0.0.0
set LPORT 443
EOF
#--- First time run (Seams to break go_pro...)
#echo -e 'sleep 10\ndb_status\n#db_rebuild_cache\n#sleep 310\nexit' > /tmp/msf.rc   #echo -e 'go_pro' >> /tmp/msf.rc
#msfconsole -r /tmp/msf.rc
#--- Check
#service postgresql status
#service metasploit status
#--- Add to start up
#update-rc.d postgresql enable
#update-rc.d metasploit enable
#--- Setup Web UI
#bash /opt/metasploit/scripts/launchui.sh    #*** Doesn't automate. Takes a little while to kick in...
#xdg-open https://127.0.0.1:3790/
#--- Wipe database and start fresh
#service metasploit stop
#sudo -u postgres dropdb msf3
#sudo -u postgres createdb -O msf3 msf3
#service metasploit restart
#msfconsole -q -x 'db_rebuild_cache;sleep 300;exit'
#--- Oracle - Due to licensing issues, Kali/Metasploit can't ship certain Oracle's library files. (https://github.com/rapid7/metasploit-framework/wiki/How-to-get-Oracle-Support-working-with-Kali-Linux)     #*** Doesn't automate
## Download: "http://www.oracle.com/technetwork/database/features/instant-client/index-097480.html"
#URL="http://www.oracle.com/technetwork/topics/linuxsoft-082809.html"                                            # x86
#[[ "$(uname -m)" == 'x86_64' ]] && URL="http://www.oracle.com/technetwork/topics/linuxx86-64soft-092277.html"   # x64
#xdg-open "$URL"
#mkdir -p /opt/oracle/
#for FILE in $(find /root/Downloads/ -maxdepth 1 -type f -name 'instantclient*.zip'); do
#  unzip -q -o -d /opt/oracle/ "${FILE}"
#done
#pushd /opt/oracle/instantclient_12_1/ >/dev/null
#ln -sf /opt/oracle/instantclient_12_1/libclntsh.so.12.1 /opt/oracle/instantclient_12_1/libclntsh.so
#file=/root/.bash_profile; [ -e "${file}" ] && cp -n $file{,.bkup}
#grep -q '/opt/oracle/instantclient' $file 2>/dev/null
#if [ $? -ne 0 ]; then
#  file=/root/.bash_profile; [ -e "${file}" ] && cp -n $file{,.bkup}
#  echo 'export PATH=$PATH:/opt/oracle/instantclient_12_1' >> "${file}"
#  echo "export SQLPATH=/opt/oracle/instantclient_12_1" >> "${file}"
#  echo "export TNS_ADMIN=/opt/oracle/instantclient_12_1" >> "${file}"
#  echo "export LD_LIBRARY_PATH=/opt/oracle/instantclient_12_1" >> "${file}"
#  echo "export ORACLE_HOME=/opt/oracle/instantclient_12_1" >> "${file}"
#fi
##if [[ "$SHELL" == "/bin/zsh" ]]; then source ~/.zshrc else source "${file}"; fi
#apt-get -y -qq install ruby-dev libgmp-dev
#wget -q -O ruby-oci8.zip https://codeload.github.com/kubo/ruby-oci8/zip/ruby-oci8-2.1.8 && unzip -q -o -d /opt/oracle/ ruby-oci8.zip && rm -f ruby-oci8.zip
#pushd /opt/oracle/ruby-oci8-ruby-oci8-*/ >/dev/null
#if [[ "$SHELL" == "/bin/zsh" ]]; then source ~/.zshrc else source "${file}"; fi    # Lose values due to pushd
#export PATH=/opt/metasploit/ruby/bin:$PATH                                       # Lose values due source $file
#make -s clean; make -s && make -s install
#popd >/dev/null   # ruby-oci8-ruby-oci8
#popd >/dev/null   # instantclient_12_1
#--- Check
#msfconsole -q 'use auxiliary/admin/oracle/oracle_login, set RHOST 127.0.0.1, run, exit'
#--- Remove old temp files
rm -f /tmp/msf.rc


###### Installing armitage
#echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}armitage${RESET} ~ GUI Metasploit UI"
#export MSF_DATABASE_CONFIG=/opt/metasploit/apps/pro/ui/config/database.yml
#file=/root/.bash_aliases; [ -e "${file}" ] && cp -n $file{,.bkup}   #/etc/bash.bash_aliases
#([[ -e "${file}" && "$(tail -c 1 $file)" != "" ]]) && echo >> "${file}"
#grep -q 'MSF_DATABASE_CONFIG' "${file}" 2>/dev/null || echo -e 'MSF_DATABASE_CONFIG=/opt/metasploit/apps/pro/ui/config/database.yml\n' >> "${file}"
#chmod 0644 /opt/metasploit/apps/pro/ui/config/database.yml
#msfrpcd -U msf -P test -f -S -a 127.0.0.1


##### Installing MPC
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}MPC${RESET} ~ Msfvenom Payload Creator"
curl --progress -k -L -f "https://raw.githubusercontent.com/g0tmi1k/mpc/master/mpc.sh" > /usr/bin/mpc
chmod +x /usr/bin/mpc


##### Installing avb
#echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}abc${RESET} ~ simple anti-virus bypass"
#curl --progress -k -L -f "https://raw.githubusercontent.com/g0tmi1k/avb/master/avb.sh" > /usr/bin/avb
#chmod +x /usr/bin/avb


##### Installing ifile
#echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}ifile${RESET} ~ more informations about files"
#curl --progress -k -L -f "https://raw.githubusercontent.com/g0tmi1k/ifile/master/ifile.sh" > /usr/bin/ifile
#chmod +x /usr/bin/ifile


##### Installing Geany
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}Geany${RESET} ~ GUI text editor"
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
file=/root/.config/geany/geany.conf; [ -e "${file}" ] && cp -n $file{,.bkup}  #***kali2
touch "${file}"
sed -i 's/^.*indent_type.*/indent_type=0/' "${file}"     # Spaces over tabs
sed -i 's/^.*pref_editor_newline_strip.*/pref_editor_newline_strip=true/' "${file}"
sed -i 's/^.*pref_editor_replace_tabs.*/pref_editor_replace_tabs=true/' "${file}"
sed -i 's/^.*pref_editor_trail_space.*/pref_editor_trail_space=true/' "${file}"
sed -i 's/^check_detect_indent=.*/check_detect_indent=true/' "${file}"
sed -i 's/^pref_editor_ensure_convert_line_endings=.*/pref_editor_ensure_convert_line_endings=true/' "${file}"
sed -i 's/^pref_toolbar_show=.*/pref_toolbar_show=false/' "${file}"
sed -i 's/^sidebar_visible=.*/sidebar_visible=false/' "${file}"
sed -i 's/^msgwindow_visible=.*/msgwindow_visible=false/' "${file}"
grep -q '^custom_commands=sort;' "${file}" || sed -i 's/\[geany\]/[geany]\ncustom_commands=sort;/' "${file}"
# Geany -> Tools -> Plugin Manger -> Save Actions -> HTML Characters: Enabled. Split Windows: Enabled. Save Actions: Enabled. -> Preferences -> Backup Copy -> Enable -> Directory to save backup files in: /root/backups/geany/. Directory levels to include in the backup destination: 5 -> Apply -> Ok -> Ok
sed -i 's#^.*active_plugins.*#active_plugins=/usr/lib/geany/htmlchars.so;/usr/lib/geany/saveactions.so;/usr/lib/geany/splitwindow.so;#' "${file}"
mkdir -p /root/backups/geany/
mkdir -p /root/.config/geany/plugins/saveactions/
file=/root/.config/geany/plugins/saveactions/saveactions.conf; [ -e "${file}" ] && cp -n $file{,.bkup}
cat <<EOF > "${file}"
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

###### Installing PyCharm (Community Edition)
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}PyCharm (Community Edition)${RESET} ~ Python IDE"
curl --progress -k -L -f "https://download.jetbrains.com/python/pycharm-community-4.5.2.tar.gz" > /tmp/pycharms-community.tar.gz      #***!!! hardcoded version!
tar -xf /tmp/pycharms-community.tar.gz -C /tmp/
mv /tmp/pycharm-community-*/ /usr/share/pycharms
ln -sf /usr/share/pycharms/bin/pycharm.sh /usr/bin/pycharms


###### Fix gedit
echo -e "\n ${GREEN}[+]${RESET} Fixes ${GREEN}gedit${RESET} ~ GUI text editor"
apt-get -y -qq install gtk3-engines-unico


##### Installing Meld
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}Meld${RESET} ~ GUI text compare"
apt-get -y -qq install meld
#--- Configure meld
gconftool-2 --type bool --set /apps/meld/show_line_numbers true
gconftool-2 --type bool --set /apps/meld/show_whitespace true
gconftool-2 --type bool --set /apps/meld/use_syntax_highlighting true
gconftool-2 --type int --set /apps/meld/edit_wrap_lines 2


###### Installing nessus    #*** Doesn't automate
#echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}nessus${RESET} ~ vulnerability scanner"
#--- Get download link
#xdg-open http://www.tenable.com/products/nessus/select-your-operating-system    *** #wget -q "http://downloads.nessus.org/<file>" -O /usr/local/src/nessus.deb   #***!!! Hardcoded version value
#dpkg -i /usr/local/src/Nessus-*-debian6_*.deb
#service nessusd start
#xdg-open http://www.tenable.com/products/nessus-home
#/opt/nessus/sbin/nessus-adduser   #*** Doesn't automate
##rm -f /usr/local/src/Nessus-*-debian6_*.deb
#--- Check email
#/opt/nessus/sbin/nessuscli fetch --register <key>   #*** Doesn't automate
#/opt/nessus/sbin/nessusd -R
#/opt/nessus/sbin/nessus-service -D
#xdg-open https://127.0.0.1:8834/
#--- Remove from start up
#update-rc.d -f nessusd remove


###### Installing Nexpose    #*** Doesn't automate
#/opt/rapid7/nexpose/nsc/nsc.sh
#--- Remove from start up
#update-rc.d -f nexposeconsole.rc remove


##### Installing OpenVAS
if [ "$openVAS" != "false" ]; then
  echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}OpenVAS${RESET} ~ vulnerability scanner"
  apt-get -y -qq install openvas
  openvas-setup
  #--- Bug fix (target credentials creation)
  mkdir -p /var/lib/openvas/gnupg/
  #--- Bug fix (keys)
  curl --progress -k -L -f "http://www.openvas.org/OpenVAS_TI.asc" | gpg --import -
  #--- Bug fix (Timeout - https://bugs.kali.org/view.php?id=2340)
  file=/etc/init.d/openvas-manager;   #[ -e "${file}" ] && cp -n $file{,.bkup}
  sed -i 's/^DODTIME=.*/DODTIME=25/' $file
  #--- Make sure all services are correct
  #openvas-start   #service openvas-manager restart; service openvas-scanner restart; service greenbone-security-assistant restart
  #--- User control
  username="root"
  password="toor"
  (openvasmd --get-users | grep -q ^admin$) && echo -n 'admin user: ' && openvasmd --delete-user=admin
  (openvasmd --get-users | grep -q "^${username}$") || (echo -n "$username user: "; openvasmd --create-user="$username"; openvasmd --user="$username" --new-password="$password" >/dev/null)   # You will want to alter it to something (much) more secure!
  echo -e " $YELLOW[i]$RESET OpenVAS username: $username"
  echo -e " $YELLOW[i]$RESET OpenVAS password: $password   *** ${BOLD}CHANGE THIS ASAP${RESET}.   Run: # openvasmd --user=root --new-password='<NEW_PASSWORD>'"
  #--- Check
  openvas-check-setup
  #--- Remove from start up
  update-rc.d -f openvas-manager remove
  update-rc.d -f openvas-scanner remove
  update-rc.d -f greenbone-security-assistant remove
  #--- Setup alias
  file=/root/.bash_aliases; [ -e "${file}" ] && cp -n $file{,.bkup}   #/etc/bash.bash_aliases
  grep -q '^## openvas' "${file}" 2>/dev/null || echo -e '## openvas\nalias openvas="service openvas-manager restart; service openvas-scanner restart; service greenbone-security-assistant restart; xdg-open https://127.0.0.1:9392/"\n' >> "${file}"
else
  echo -e '\n '$RED'[!]'$RESET" ${RED}Skipping OpenVAS${RESET} (missing: '$0 --openvas')..." 1>&2
fi


###### Installing vFeed
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}vFeed${RESET} ~ vulnerability database"
apt-get -y -qq install vfeed


##### Installing Burp Proxy
if [ "$burpFree" != "false" ]; then
  echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}Burp Proxy${RESET} ~ web application proxy"
  apt-get -y -qq install burpsuite curl
  mkdir -p /root/.java/.userPrefs/burp/
  file=/root/.java/.userPrefs/burp/prefs.xml;   #[ -e "${file}" ] && cp -n $file{,.bkup}
  [ -e "${file}" ] || cat <<EOF > "${file}"
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
  timeout 120 burpsuite &
  PID=$!
  sleep 15
  #echo "-----BEGIN CERTIFICATE-----" > /tmp/PortSwiggerCA && awk -F '"' '/caCert/ {print $4}' /root/.java/.userPrefs/burp/prefs.xml | fold -w 64 >> /tmp/PortSwiggerCA && echo "-----END CERTIFICATE-----" >> /tmp/PortSwiggerCA
  export http_proxy="http://127.0.0.1:8080"
  rm -f /tmp/burp.crt
  while test -d /proc/$PID; do
    sleep 1
    curl --progress -k -L -f "http://burp/cert" -o /tmp/burp.crt 2>/dev/null
    [ -f /tmp/burp.crt ] && break
  done
  timeout 5 kill $PID 2>/dev/null
  unset http_proxy
  #--- Installing CA
  if [ -f /tmp/burp.crt ]; then
    apt-get -y -qq install libnss3-tools
    folder=$(find /root/.mozilla/firefox/ -maxdepth 1 -type d -name '*.default' -print -quit)
    certutil -A -n Burp -t "CT,c,c" -d "$folder" -i /tmp/burp.crt
    timeout 15 iceweasel
    #mkdir -p /usr/share/ca-certificates/burp/
    #cp -f /tmp/burp.crt /usr/share/ca-certificates/burp/
    #dpkg-reconfigure ca-certificates
    #cp -f /tmp/burp.crt /root/Desktop/burp.crt
  else
    echo -e ' '$RED'[!]'$RESET' Didnt extract burp suite Certificate Authority (CA). Skipping...' 1>&2
  fi
  #--- Remove old temp files
  sleep 1
  find /tmp/ -maxdepth 1 -name 'burp*.tmp' -delete
  find /root/.mozilla/firefox/*.default*/ -maxdepth 1 -type f -name 'sessionstore.*' -delete
  rm -f /tmp/burp.crt
  unset http_proxy
else
  echo -e '\n '$RED'[!]'$RESET" ${RED}Skipping Burp${RESET} (missing: '$0 --burp')..." 1>&2
fi


##### Installing sparta: https://bugs.kali.org/view.php?id=2021
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}sparta${RESET} ~ GUI automatic wrapper"
apt-get -y -qq install git
git clone git://github.com/secforce/sparta.git /opt/sparta-git/ || echo -e "${RED}issue with git clone${RESET}"
pushd /usr/share/sparta-git/ >/dev/null
git pull
popd >/dev/null
#--- Add to path
file=/usr/local/bin/sparta-git
cat <<EOF > "${file}"
#!/bin/bash

cd /opt/sparta-git/ && python sparta.py "\$@"
EOF
chmod +x "${file}"


##### Installing wireshark
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}wireshark${RESET} ~ GUI network protocol analyzer"
#--- Hide running as root warning
mkdir -p /root/.wireshark/
file=/root/.wireshark/recent_common;   #[ -e "${file}" ] && cp -n $file{,.bkup}
[ -e "${file}" ] || echo "privs.warn_if_elevated: FALSE" > "${file}"
#--- Hide 'Lua: Error during loading' warning
file=/usr/share/wireshark/init.lua; [ -e "${file}" ] && cp -n $file{,.bkup}
sed -i 's/^disable_lua = .*/disable_lua = true/' "${file}"


##### Installing silver searcher
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}silver searcher${RESET} ~ code searching"
apt-get -y -qq install git automake pkg-config libpcre3-dev zlib1g-dev liblzma-dev --force-yes
git clone git://github.com/ggreer/the_silver_searcher.git /usr/local/src/the_silver_searcher || echo -e "${RED}issue with git clone${RESET}"
pushd /usr/local/src/the_silver_searcher/ >/dev/null
git pull
bash ./build.sh
make -s install
popd >/dev/null
#ag <name>


##### Installing rips
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}rips${RESET} ~ source code scanner"
apt-get -y -qq install apache2 php5 git
git clone git://github.com/ripsscanner/rips.git /opt/rips-git/ || echo -e "${RED}issue with git clone${RESET}"
pushd /usr/share/rips-git/ >/dev/null
git pull
popd >/dev/null
#--- Add to path
file=/etc/apache2/conf.d/rips.conf
file=/etc/apache2/conf-available/rips.conf #***kali2
cat <<EOF > "${file}"
Alias /rips /usr/share/rips-git

<Directory /usr/share/rips-git/ >
  Options FollowSymLinks
  AllowOverride None
  Order deny,allow
  Deny from all
  Allow from 127.0.0.0/255.0.0.0 ::1/128
</Directory>
EOF
ln -sf /etc/apache2/conf-available/rips.conf /etc/apache2/conf-enabled/rips.conf #***kali2
service apache2 restart


##### Installing libreoffice
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}libreoffice${RESET} ~ GUI office suite"
apt-get -y -qq install libreoffice


###### Installing cherrytree
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}cherrytree${RESET} ~ GUI note taking"
apt-get -y -qq install cherrytree


###### Installing ipcalc & sipcalc
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}ipcalc & sipcalc${RESET} ~ CLI subnet calculators"
apt-get -y -qq install ipcalc sipcalc


##### Installing recordmydesktop
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}recordmydesktop${RESET} ~ GUI video screen capture"
apt-get -y -qq install recordmydesktop
#--- Installing GUI front end
apt-get -y -qq install gtk-recordmydesktop


###### Installing asciinema
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}asciinema${RESET} ~ CLI terminal recorder"
curl -s -L https://asciinema.org/install | sh


###### Installing gimp
#echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}gimp${RESET} ~ GUI image editing"
#apt-get -y -qq install gimp


##### Installing shutter
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}shutter${RESET} ~ GUI static screen capture"
apt-get -y -qq install shutter


###### Installing gdebi
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}gdebi${RESET} ~ GUI package installer"
apt-get -y -qq install gdebi


##### Installing psmisc ~ allows for 'killall command' to be used
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}psmisc${RESET} ~ suite to help with running processes"
apt-get -y -qq install psmisc


###### Setting up pipe viewer
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}pipe viewer${RESET} ~ CLI progress bar"
apt-get install -y -qq pv


###### Setting up pwgen
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}pwgen${RESET} ~ password generator"
apt-get install -y -qq pwgen


###### Installing midnight commander
#echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}midnight commander${RESET} ~ CLI file manager"
#apt-get -y -qq install mc


##### Installing htop
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}htop${RESET} ~ CLI process viewer"
apt-get -y -qq install htop


##### Installing iotop
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}iotop${RESET} ~ CLI I/O usage"
apt-get -y -qq install iotop


###### Installing glance
#echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}glance${RESET} ~ CLI process viewer"
#apt-get -y -qq install glance


##### Installing ca-certificates
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}ca-certificates${RESET} ~ HTTPS/SSL/TLS"
apt-get -y -qq install ca-certificates


##### Installing axel
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}axel${RESET} ~ CLI download manager"
apt-get -y -qq install axel
#--- Setup alias
file=/root/.bash_aliases; [ -e "${file}" ] && cp -n $file{,.bkup}   #/etc/bash.bash_aliases
([[ -e "${file}" && "$(tail -c 1 $file)" != "" ]]) && echo >> "${file}"
grep -q '^alias axel' "${file}" 2>/dev/null || echo -e '## axel\nalias axel="axel -a"\n' >> "${file}"
#--- Apply new aliases
if [[ "$SHELL" == "/bin/zsh" ]]; then source ~/.zshrc else source "${file}"; fi


##### Installing gparted
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}gparted${RESET} ~ GUI partition manager"
apt-get -y -qq install gparted


##### Installing daemonfs
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}daemonfs${RESET} ~ GUI file monitor"
apt-get -y -qq install daemonfs


##### Installing filezilla
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}filezilla${RESET} ~ GUI file transfer"
apt-get -y -qq install filezilla
#--- Configure filezilla
export DISPLAY=:0.0   #[[ -z $SSH_CONNECTION ]] || export DISPLAY=:0.0
timeout 15 filezilla   #filezilla & sleep 5; killall -q -w filezilla >/dev/null     # Start and kill. Files needed for first time run
file=/root/.filezilla/filezilla.xml; [ -e "${file}" ] && cp -n $file{,.bkup} #***kali2
touch "${file}"
sed -i 's#^.*"Default editor".*#\t<Setting name="Default editor" type="string">2/usr/bin/geany</Setting>#' "${file}"


###### Installing remmina
#echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}remmina${RESET} ~ GUI remote desktop"
#apt-get -y -qq install remmina remmina-plugin-xdmcp remmina-plugin-rdp remmina-plugin-vnc


###### Installing xrdp
#echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}xrdp${RESET} ~ GUI remote desktop"
#apt-get -y -qq install xrdp


###### Installing x2go client
#echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}x2go client${RESET} ~ GUI remote desktop"
#apt-get -y -qq install x2goclient


##### Installing lynx
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}lynx${RESET} ~ CLI web browser"
apt-get -y -qq install lynx


##### Installing p7zip
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}p7zip${RESET} ~ CLI file extractor"
apt-get -y -qq install p7zip-full


##### Installing zip & unzip
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}zip & unzip${RESET} ~ CLI file extractors"
apt-get -y -qq install zip || echo -e "${RED}issue with apt${RESET}"     # Compress
apt-get -y -qq install unzip || echo -e "${RED}issue with apt${RESET}"   # Decompress


##### Installing file roller
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}file roller${RESET} ~ GUI file extractor"
apt-get -y -qq install file-roller || echo -e "${RED}issue with apt${RESET}"                                            # GUI program
apt-get -y -qq install unace unrar rar unzip zip p7zip p7zip-full p7zip-rar || echo -e "${RED}issue with apt${RESET}"   # Supported file compressions types


##### Installing PPTP VPN support
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}PPTP VPN${RESET} support"
apt-get -y -qq install network-manager-pptp-gnome network-manager-pptp
#apt-get -y -qq install network-manager-openvpn network-manager-openvpn-gnome network-manager-pptp network-manager-pptp-gnome network-manager-strongswan network-manager-vpnc network-manager-vpnc-gnome network-manager-openconnect network-manager-openconnect-gnome network-manager-iodine network-manager-iodine-gnome


##### Installing flash
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}flash${RESET} ~ multimedia web plugin"
apt-get -y -qq install flashplugin-nonfree
update-flashplugin-nonfree --install


###### Installing java
#echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}java${RESET} ~ web plugin"
#*** Insert bash fu here for either open jdk vs oracle jdk
#update-java-alternatives --jre -s java-1.7.0-openjdk-amd64


##### Installing hashid
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}hashid${RESET} ~ identify hash types"
apt-get -y -qq install hashid


##### Installing hash identifier (TEMP - until hashid works: https://bugs.kali.org/view.php?id=2299)
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}hash-identifier${RESET} ~ identify hash types"
apt-get -y -qq install hash-identifier


##### Installing httprint
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}httprint${RESET} ~ GUI web server fingerprint"
apt-get -y -qq install httprint


##### Installing lbd
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}lbd${RESET} ~ load balancing detector"
apt-get -y -qq install lbd


##### Installing wafw00f
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}wafw00f${RESET} ~ WAF detector"
apt-get -y -qq install git python python-pip
git clone git://github.com/sandrogauci/wafw00f.git /opt/wafw00f-git/ || echo -e "${RED}issue with git clone${RESET}"
pushd /usr/share/wafw00f-git/ >/dev/null
git pull
python setup.py install
popd >/dev/null


###### Installing waffit
#echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}waffit${RESET} ~ WAF detector"
#apt-get -y -qq install waffit


##### Installing aircrack-ng
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}aircrack-ng${RESET} ~ Wi-Fi cracking suite"
apt-get -y -qq install aircrack-ng curl
#--- Setup hardware database
mkdir -p /etc/aircrack-ng/
airodump-ng-oui-update 2>/dev/null #|| curl --progress -k -L -f "http://standards.ieee.org/develop/regauth/oui/oui.txt" > /etc/aircrack-ng/oui.txt          #***!!! hardcoded path!
[ -e /etc/aircrack-ng/oui.txt ] && (\grep "(hex)" /etc/aircrack-ng/oui.txt | sed 's/^[ \t]*//g;s/[ \t]*$//g' > /etc/aircrack-ng/airodump-ng-oui.txt)
#--- Setup alias
file=/root/.bash_aliases; [ -e "${file}" ] && cp -n $file{,.bkup}   #/etc/bash.bash_aliases
([[ -e "${file}" && "$(tail -c 1 $file)" != "" ]]) && echo >> "${file}"
grep -q '^## aircrack-ng' "${file}" 2>/dev/null || echo -e '## aircrack-ng\nalias aircrack-ng="aircrack-ng -z"\n' >> "${file}"
grep -q '^## airodump-ng' "${file}" 2>/dev/null || echo -e '## airodump-ng \nalias airodump-ng="airodump-ng --manufacturer --wps --uptime"\n' >> "${file}"    # aircrack-ng 1.2 rc2


##### Installing reaver (Community Fork)
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}reaver (Community Fork)${RESET} ~ WPS pin brute force + Pixie Attack"
apt-get -y -qq install reaver pixiewps


##### Installing bully
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}bully${RESET} ~ WPS pin brute force"
apt-get -y -qq install bully


##### Installing wifite
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}wifite${RESET} ~ automated Wi-Fi tool"
apt-get -y -qq install wifite


##### Installing vulscan script for nmap
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}vulscan script for nmap${RESET} ~ vulnerability scanner add-on"
apt-get -y -qq install nmap curl
mkdir -p /usr/share/nmap/scripts/vulscan/
curl --progress -k -L -f "http://www.computec.ch/projekte/vulscan/download/nmap_nse_vulscan-2.0.tar.gz" > /tmp/nmap_nse_vulscan.tar.gz    #***!!! hardcoded version! Need to manually check for updates
gunzip /tmp/nmap_nse_vulscan.tar.gz
tar -xf /tmp/nmap_nse_vulscan.tar -C /usr/share/nmap/scripts/
#--- Fix permissions (by default its 0777)
chmod -R 0755 /usr/share/nmap/scripts/; find /usr/share/nmap/scripts/ -type f -exec chmod 0644 {} \;
#--- Remove old temp files
rm -f /tmp/nmap_nse_vulscan.tar*


##### Installing unicornscan
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}unicornscan${RESET} ~ fast port scanner"
apt-get -y -qq install unicornscan


##### Installing onetwopunch
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}onetwopunch${RESET} ~ unicornscan & nmap wrapper"
apt-get -y -qq install git nmap unicornscan
git clone git://github.com/superkojiman/onetwopunch.git /opt/onetwopunch-git/ || echo -e "${RED}issue with git clone${RESET}"
pushd /usr/share/onetwopunch-git/ >/dev/null
git pull
popd >/dev/null
#--- Add to path
file=/usr/local/bin/onetwopunch-git
cat <<EOF > "${file}"
#!/bin/bash

cd /opt/onetwopunch-git/ && bash onetwopunch.sh "\$@"
EOF
chmod +x "${file}"


##### Installing udp-proto-scanner
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}udp-proto-scanner${RESET} ~ common UDP port scanner"
apt-get -y -qq install curl
#mkdir -p /usr/share/udp-proto-scanner/
curl --progress -k -L -f "https://labs.portcullis.co.uk/download/udp-proto-scanner-1.1.tar.gz" -o /tmp/udp-proto-scanner.tar.gz
gunzip /tmp/udp-proto-scanner.tar.gz
tar -xf /tmp/udp-proto-scanner.tar -C /usr/share/
mv -f /usr/share/udp-proto-scanner{-1.1,}
file=/usr/local/bin/udp-proto-scanner
cat <<EOF > "${file}"
#!/bin/bash

cd /opt/udp-proto-scanner/ && perl udp-proto-scanner.pl "\$@"
EOF
chmod +x "${file}"
#--- Remove old temp files
rm -f /tmp/udp-proto-scanner.tar*


##### Installing clusterd
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}clusterd${RESET} ~ clustered attack toolkit (jboss, coldfusion, weblogic, tomcat etc)"
apt-get -y -qq install clusterd


##### Installing webhandler
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}webhandler${RESET} ~ shell TTY handler"
apt-get -y -qq install webhandler


##### Installing azazel
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}azazel${RESET} ~ linux userland rootkit"
apt-get -y -qq install git
git clone git://github.com/chokepoint/azazel.git /opt/azazel-git/ || echo -e "${RED}issue with git clone${RESET}"
pushd /usr/share/azazel-git/ >/dev/null
git pull
popd >/dev/null


##### Installing b374k (https://bugs.kali.org/view.php?id=1097)
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}b374k${RESET} ~ (PHP) web shell"
apt-get -y -qq install git php5-cli
git clone git://github.com/b374k/b374k.git /opt/b374k-git/ || echo -e "${RED}issue with git clone${RESET}"
pushd /usr/share/b374k-git/ >/dev/null
git pull
php index.php -o b374k.php -s
popd >/dev/null
#--- Link to others
apt-get -y -qq install webshells
ln -sf /usr/share/b374k-git /usr/share/webshells/php/b374k


###### Installing DAws
#echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}DAws${RESET} ~ (PHP) web shell"
#apt-get -y -qq install git
#git clone git://github.com/dotcppfile/DAws.git /opt/daws-git/
#pushd /usr/share/daws-git/ >/dev/null
#git pull
#popd >/dev/null
#--- Link to others
#apt-get -y -qq install webshells
#ln -sf /usr/share/daws-git /usr/share/webshells/php/daws
#--- Bug
#PHP Fatal error:  Call to undefined function rglob() in /var/www/DAws.php on line 241
#--- Bug Fix
#  11 <address>".$_SERVER["SERVER_SOFTWARE"]." Server at ".$_SERVER['SERVER_NAME']." Port 80</address>
#--- Use
#curl http://localhost/DAws.php --data 'pass=DAws'
#echo '<form method="POST" action="localhost/DAws.php"><input type="text" name="pass" value="DAws"><input type="submit" value="Submit"></forum>'


##### Installing cmdsql
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}cmdsql${RESET} ~ (ASPX) web shell"
apt-get -y -qq install git
git clone git://github.com/NetSPI/cmdsql.git /opt/cmdsql-git/ || echo -e "${RED}issue with git clone${RESET}"
pushd /usr/share/b374k-git/ >/dev/null
git pull
popd >/dev/null
#--- Link to others
apt-get -y -qq install webshells
ln -sf /usr/share/cmdsql-git /usr/share/webshells/aspx/cmdsql


##### Installing JSP file browser
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}jsp file browser${RESET} ~ (JSP) web shell"
apt-get -y -qq install curl
mkdir -p /usr/share/jsp-filebrowser/
curl --progress -k -L -f "http://www.vonloesch.de/files/browser.zip" > /tmp/jsp.zip && unzip -q -o -d /usr/share/jsp-filebrowser/ /tmp/jsp.zip        #***!!! hardcoded path!
#--- Link to others
apt-get -y -qq install webshells
ln -sf /usr/share/jsp-filebrowser /usr/share/webshells/jsp/jsp-filebrowser
#--- Remove old temp files
rm -f /tmp/jsp.zip


##### Installing htshells
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}htshells${RESET} ~ (htdocs/apache) web shells"
apt-get -y -qq install htshells
#--- Link to others
apt-get -y -qq install webshells
ln -sf /usr/share/htshells /usr/share/webshells/htshells


###### Installing python-pty-shells
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}python-pty-shells${RESET} ~ PTY shells"
apt-get -y -qq install git
git clone git://github.com/infodox/python-pty-shells.git /opt/python-pty-shells-git/ || echo -e "${RED}issue with git clone${RESET}"
pushd /usr/share/python-pty-shells-git/ >/dev/null
git pull
popd >/dev/null


##### Installing bridge-utils
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}bridge-utils${RESET} ~ bridge network interfaces"
apt-get -y -qq install bridge-utils


##### Installing FruityWifi
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}FruityWifi${RESET} ~ wireless network auditing tool"
apt-get -o Dpkg::Options::="--force-confnew" -y -qq install fruitywifi
# URL: https://localhost:8443


##### Installing WPA2-HalfHandshake-Crack
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}WPA2-HalfHandshake-Crack${RESET} ~ rogue AP todo WPA2 handshakes without AP"
apt-get -y -qq install git
git clone git://github.com/dxa4481/WPA2-HalfHandshake-Crack.git /opt/wpa2-halfhandshake-crack-git/ || echo -e "${RED}issue with git clone${RESET}"
pushd /usr/share/wpa2-halfhandshake-crack-git/ >/dev/null
git pull
popd >/dev/null


##### Installing mana toolkit
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}mana toolkit${RESET} ~ rogue AP todo MITM Wi-Fi"
apt-get -o Dpkg::Options::="--force-confnew" -y -qq install mana-toolkit
#--- BUG FIX: https://bugs.kali.org/view.php?id=1839
mkdir -p /usr/share/mana-toolkit/www/facebook/


##### Installing wifiphisher
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}wifiphisher${RESET} ~ automated Wi-Fi phishing"
apt-get -y -qq install git
git clone git://github.com/sophron/wifiphisher.git /opt/wifiphisher-git/ || echo -e "${RED}issue with git clone${RESET}"
pushd /usr/share/wifiphisher-git/ >/dev/null
git pull
popd >/dev/null
#--- Add to path
file=/usr/local/bin/wifiphisher-git
cat <<EOF > "${file}"
#!/bin/bash

cd /opt/wifiphisher-git/ && python wifiphisher.py "\$@"
EOF
chmod +x "${file}"


##### Installing hostapd-wpe-extended
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}hostapd-wpe-extended${RESET} ~ rogue AP for WPA-Enterprise"
apt-get -y -qq install git
git clone git://github.com/NerdyProjects/hostapd-wpe-extended.git /opt/hostapd-wpe-extended-git/ || echo -e "${RED}issue with git clone${RESET}"
pushd /usr/share/hostapd-wpe-extended-git/ >/dev/null
git pull
popd >/dev/null


##### Installing proxychains-ng (https://bugs.kali.org/view.php?id=2037)
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}proxychains-ng${RESET} ~ proxifier to connect through a proxy"
apt-get -y -qq install git gcc
git clone git://github.com/rofl0r/proxychains-ng.git /opt/proxychains-ng-git/ || echo -e "${RED}issue with git clone${RESET}"
pushd /usr/share/proxychains-ng-git/ >/dev/null
git pull
./configure --prefix=/usr --sysconfdir=/etc
make
make install
popd >/dev/null
#--- Add to path (with a 'better' name)
ln -sf /usr/bin/proxychains4 /usr/bin/proxychains-ng


##### Installing httptunnel
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}httptunnel${RESET} ~ tunnels data streams in HTTP requests"
apt-get -y -qq install http-tunnel


##### Installing sshuttle
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}sshuttle${RESET} ~ VPN over SSH"
apt-get -y -qq install sshuttle
#--- Example
#sshuttle --dns --remote root@123.9.9.9 0/0 -vv


##### Installing iodine
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}iodine${RESET} ~ DNS tunneling (IP over DNS)"
apt-get -y -qq install iodine
#--- Example
#iodined -f -P password1 10.0.0.1 dns.mydomain.com
#iodine -f -P password1 123.9.9.9 dns.mydomain.com; ssh -C -D 8081 root@10.0.0.1


##### Installing dns2tcp
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}dns2tcp${RESET} ~ DNS tunneling (TCP over DNS)"
apt-get -y -qq install dns2tcp
#file=/etc/dns2tcpd.conf; [ -e "${file}" ] && cp -n $file{,.bkup}; echo -e "listen = 0.0.0.0\nport = 53\nuser = nobody\nchroot = /tmp\ndomain = dnstunnel.mydomain.com\nkey = password1\nressources = ssh:127.0.0.1:22" > "${file}"; dns2tcpd -F -d 1 -f /etc/dns2tcpd.conf
#file=/etc/dns2tcpc.conf; [ -e "${file}" ] && cp -n $file{,.bkup}; echo -e "domain = dnstunnel.mydomain.com\nkey = password1\nresources = ssh\nlocal_port = 8000\ndebug_level=1" > "${file}"; dns2tcpc -f /etc/dns2tcpc.conf 178.62.206.227; ssh -C -D 8081 -p 8000 root@127.0.0.1


##### Installing ptunnel
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}ptunnel${RESET} ~ IMCP tunneling"
apt-get -y -qq install ptunnel
#--- Example
#ptunnel -x password1
#ptunnel -x password1 -p 123.9.9.9 -lp 8000 -da 127.0.0.1 -dp 22; ssh -C -D 8081 -p 8000 root@127.0.0.1


##### Installing stunnel
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}stunnel${RESET} ~ SSL wrapper"
apt-get -y -qq install stunnel
#--- Remove from start up
update-rc.d -f stunnel4 remove


##### Installing zerofree
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}zerofree${RESET} ~ CLI nulls free blocks on a HDD"
apt-get -y -qq install zerofree
#--- Example
#fdisk -l
#zerofree -v /dev/sda1   #for i in $(mount | grep sda | grep ext | cut -b 9); do  mount -o remount,ro /dev/sda$i && zerofree -v /dev/sda$i && mount -o remount,rw /dev/sda$i; done


##### Installing gcc & multilib
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}gcc & multilibc${RESET} ~ compiling libraries"
#*** I know its messy...
for FILE in cc gcc g++ gcc-multilib make automake libc6 libc6-dev libc6-amd64 libc6-dev-amd64 libc6-i386 libc6-dev-i386 libc6-i686 libc6-dev-i686 build-essential dpkg-dev; do
  apt-get -y -qq install "${FILE}" 2>/dev/null
done


##### Installing MinGW ~ cross compiling suite
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}mingw${RESET} ~ cross compiling suite"
apt-get -y -qq install mingw-w64 binutils-mingw-w64 gcc-mingw-w64 cmake
apt-get -y -qq install mingw-w64-dev mingw-w64-tools
apt-get -y -qq install gcc-mingw-w64-i686 gcc-mingw-w64-x86-64
apt-get -y -qq install mingw32


##### Installing WINE  ***kali2
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}WINE${RESET} ~ run Windows programs on *nix"
apt-get -y -qq install wine winetricks
#--- Using x64?
if [[ "$(uname -m)" == 'x86_64' ]]; then
  echo -e " ${GREEN}[+]${RESET} Configuring ${GREEN}WINE for x64${RESET}"
  dpkg --add-architecture i386
  apt-get -qq update
  apt-get -y -qq install wine-bin:i386
  #apt-get -y -qq remove wine64     #kali2
  apt-get -y -qq install wine32    #kali2
fi
#--- Mono
curl --progress -k -L -f "http://winezeug.googlecode.com/svn/trunk/install-addons.sh" | bash -    # kali2
apt-get -y -qq install mono-vbnc  #mono-complete || echo -e "${RED}issue with apt${RESET}"   # kali2
#--- Run WINE for the first time
[ -e /usr/share/windows-binaries/whoami.exe ] && wine /usr/share/windows-binaries/whoami.exe &>/dev/null
#--- Winetricks: Disable 'axel' support - BUG too many redirects.
file=/usr/bin/winetricks; #[ -e "${file}" ] && cp -n $file{,.bkup}
sed -i 's/which axel /which axel_disabled /' "${file}"
#--- Setup default file association for .exe
file=/root/.local/share/applications/mimeapps.list; [ -e "${file}" ] && cp -n $file{,.bkup}
([[ -e "${file}" && "$(tail -c 1 $file)" != "" ]]) && echo >> "${file}"
echo -e 'application/x-ms-dos-executable=wine.desktop' >> "${file}"


##### Installing MinGW (Windows) ~ cross compiling suite
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}mingw (Windows)${RESET} ~ cross compiling suite"
#curl --progress -k -L -f "http://sourceforge.net/projects/mingw/files/Installer/mingw-get-setup.exe/download" > /tmp/mingw-get-setup.exe                                                                     #***!!! hardcoded path!
curl --progress -k -L -f "http://sourceforge.net/projects/mingw/files/Installer/mingw-get/mingw-get-0.6.2-beta-20131004-1/mingw-get-0.6.2-mingw32-beta-20131004-1-bin.zip/download" > /tmp/mingw-get.zip      #***!!! hardcoded path!
mkdir -p ~/.wine/drive_c/MinGW/bin/
unzip -q -o -d ~/.wine/drive_c/MinGW/ /tmp/mingw-get.zip
pushd ~/.wine/drive_c/MinGW/ >/dev/null
for FILE in mingw32-base mingw32-gcc-g++ mingw32-gcc-objc; do   #msys-base
  wine ./bin/mingw-get.exe install "${FILE}"
done
popd >/dev/null
grep '^"PATH"=.*C:\\\\MinGW\\\\bin' /root/.wine/system.reg || sed -i '/^"PATH"=/ s_"$_;C:\\\\MinGW\\\\bin"_' /root/.wine/system.reg    #***kali2
#wine cmd /c "set path=\"%path%;C:\MinGW\bin\" && reg ADD \"HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment\" /v Path /t REG_EXPAND_SZ /d %path% /f"


##### Downloading AccessChk.exe
echo -e "\n ${GREEN}[+]${RESET} Downloading ${GREEN}AccessChk.exe${RESET} ~ Windows environment tester"
apt-get -y -qq install curl
curl --progress -k -L -f "https://download.sysinternals.com/files/AccessChk.zip" > /usr/share/windows-binaries/AccessChk.zip         #***!!! hardcoded path!
unzip -q -o -d /usr/share/windows-binaries/ /usr/share/windows-binaries/AccessChk.zip
rm -f /usr/share/windows-binaries/{AccessChk.zip,Eula.txt}


###### Installing Python (Windows via WINE) *** WINE is too dated =(  (try again with debian 8 / kali 2.0)
#echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}Python${RESET} ~ python on Windows"
#curl --progress -k -L -f "https://www.python.org/ftp/python/2.3/Python-2.3.exe" > /tmp/python.exe                                                         #***!!! hardcoded path!
#wine /tmp/python.exe /s
#curl --progress -k -L -f "http://sourceforge.net/projects/pywin32/files/pywin32/Build%20218/pywin32-218.win32-py2.3.exe/download" > /tmp/pywin32.exe      #***!!! hardcoded path!
#wine /tmp/pywin32.exe
#
#winetricks python26
#
#curl --progress -k -L -f "https://www.python.org/ftp/python/2.7.9/python-2.7.9.msi" > /tmp/python.msi                                                     #***!!! hardcoded path!
#wine msiexec /i /tmp/python.msi /qb
#curl --progress -k -L -f "http://sourceforge.net/projects/pywin32/files/pywin32/Build%20219/pywin32-219.win32-py2.7.exe/download" > /tmp/pywin32.exe      #***!!! hardcoded path!
#wine /tmp/pywin32.exe /s


##### Installing veil framework ****kali2
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}veil framework${RESET} ~ bypasses anti-virus"
apt-get -y -qq install veil
pip install symmetricjsonrpc
touch /etc/veil/settings.py
#/usr/share/veil-evasion/setup --silent ~ https://bugs.kali.org/view.php?id=2365
#sed -i 's/TERMINAL_CLEAR=".*"/TERMINAL_CLEAR="false"/' /etc/veil/settings.py


##### Installing OP packers
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}OP packers${RESET} ~ bypasses anti-virus"
apt-get -y -qq install upx-ucl curl || echo -e "${RED}issue with apt${RESET}"   #wget -q "http://upx.sourceforge.net/download/upx309w.zip" -P /usr/share/packers/ && unzip -q -o -d /usr/share/packers/ /usr/share/packers/upx309w.zip; rm -f /usr/share/packers/upx309w.zip
mkdir -p /usr/share/packers/
curl --progress -k -L -f "http://www.eskimo.com/~scottlu/win/cexe.exe" > /usr/share/packers/cexe.exe                                                                                                      #***!!! hardcoded path!                                                                                                             #***!!! hardcoded version! Need to manually check for updates
curl --progress -k -L -f "http://www.farbrausch.de/~fg/kkrunchy/kkrunchy_023a2.zip" > /usr/share/packers/kkrunchy.zip && unzip -q -o -d /usr/share/packers/ /usr/share/packers/kkrunchy.zip               #***!!! hardcoded version! Need to manually check for updates
curl --progress -k -L -f "https://pescrambler.googlecode.com/files/PEScrambler_v0_1.zip" > /usr/share/packers/PEScrambler.zip && unzip -q -o -d /usr/share/packers/ /usr/share/packers/PEScrambler.zip    #***!!! hardcoded version! Need to manually check for updates
#*** Need to make a bash script like hyperion...
#--- Remove old temp files
rm -f /usr/share/packers/kkrunchy*.zip
rm -f /usr/share/packers/PEScrambler*.zip


##### Installing hyperion
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}hyperion${RESET} ~ bypasses anti-virus"
unzip -q -o -d /usr/share/windows-binaries/ /usr/share/windows-binaries/Hyperion-1.0.zip                                                                                                    #***!!! hardcoded path!
#rm -f /usr/share/windows-binaries/Hyperion-1.0.zip
i686-w64-mingw32-g++ -static-libgcc -static-libstdc++ /usr/share/windows-binaries/Hyperion-1.0/Src/Crypter/*.cpp -o /usr/share/windows-binaries/Hyperion-1.0/Src/Crypter/bin/crypter.exe    #***!!! hardcoded path!   #wine /root/.wine/drive_c/MinGW/bin/g++.exe ./Src/Crypter/*.cpp -o crypter.exe #i586-mingw32msvc-g++ ./Src/Crypter/*.cpp -o crypter-w00t1.exe
ln -sf /usr/share/windows-binaries/Hyperion-1.0/Src/Crypter/bin/crypter.exe /usr/share/windows-binaries/Hyperion-1.0/crypter.exe                                                            #***!!! hardcoded path!
file=/usr/local/bin/hyperion
cat <<EOF > "${file}"
#!/bin/bash

## Note: This is far from perfect...

CWD=\$(pwd)/
BWD="?"

## Using full path?
[ -e "/\${1}" ] && BWD=""

## Using relative path?
[ -e "./\${1}" ] && BWD="\${CWD}"

## Can't find input file!
[[ "\${BWD}" == "?" ]] && echo -e ' '$RED'[!]'$RESET' Cant find \$1. Quitting...' && exit

## The magic!
cd /opt/windows-binaries/Hyperion-1.0/
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
chmod +x "${file}"


###### Installing shellter
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}shellter${RESET} ~ dynamic shellcode injector"
apt-get -y -qq install shellter


###### Installing the backdoor factory
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}backdoor factory${RESET} ~ bypasses anti-virus"
apt-get -y -qq install backdoor-factory


###### Installing the Backdoor Factory Proxy (BDFProxy)
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}backdoor factory (BDFProxy)${RESET} ~ patches binaries files during a MITM"
apt-get -y -qq install git
git clone git://github.com/secretsquirrel/BDFProxy.git /opt/bdfproxy-git/ || echo -e "${RED}issue with git clone${RESET}"
pushd /usr/share/bdfproxy-git/ >/dev/null
git pull
popd >/dev/null


###### Installing the BetterCap
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}BetterCap${RESET} ~ MITM framework"
apt-get -y -qq install git ruby-dev libpcap-dev
git clone git://github.com/evilsocket/bettercap.git /opt/bettercap-git/ || echo -e "${RED}issue with git clone${RESET}"
pushd /usr/share/bettercap-git/ >/dev/null
git pull
gem build bettercap.gemspec
gem install bettercap*.gem
popd >/dev/null


####### Installing the MITMf (GIT)
#echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}MITMf${RESET} (GIT) ~ framework for MITM attacks"
##apt-get -y -qq install mitmf    # repo version. stable, but dated
#apt-get -y -qq install git       #  git version. bleeding edge
#git clone git://github.com/byt3bl33d3r/MITMf.git /opt/mitmf-git/
#pushd /usr/share/mitmf-git/ >/dev/null
#git pull
#bash kali_setup.sh
#popd >/dev/null


##### Installing FuzzDB
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}FuzzDB${RESET} ~ multiple types of (word)lists (and similar things)"
svn -q checkout "http://fuzzdb.googlecode.com/svn/trunk/" /usr/share/fuzzdb-svn/


##### Installing seclist
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}seclist${RESET} ~ multiple types of (word)lists (and similar things)"
apt-get -y -qq install seclists


##### Updating wordlists
echo -e "\n ${GREEN}[+]${RESET} Updating wordlists ~ collection of wordlists"
apt-get -y -qq install curl
#--- Extract rockyou wordlist
[ -e /usr/share/wordlists/rockyou.txt.gz ] && gzip -dc < /usr/share/wordlists/rockyou.txt.gz > /usr/share/wordlists/rockyou.txt   #gunzip rockyou.txt.gz
#rm -f /usr/share/wordlists/rockyou.txt.gz
#--- Extract sqlmap wordlist
#unzip -o -d /usr/share/sqlmap/txt/ /usr/share/sqlmap/txt/wordlist.zip
#--- Add 10,000 Top/Worst/Common Passwords
mkdir -p /usr/share/wordlists/
(curl --progress -k -L -f "http://xato.net/files/10k most common.zip" > /tmp/10kcommon.zip && unzip -q -o -d /usr/share/wordlists/ /tmp/10kcommon.zip 2>/dev/null) || (curl --progress -k -L -f "http://download.g0tmi1k.com/wordlists/common-10k_most_common.zip" > /tmp/10kcommon.zip && unzip -q -o -d /usr/share/wordlists/ /tmp/10kcommon.zip)   #***!!! hardcoded version! Need to manually check for updates
mv -f /usr/share/wordlists/10k{\ most\ ,_most_}common.txt
#--- Linking to more - folders
[ -e /usr/share/dirb/wordlists ] && ln -sf /usr/share/dirb/wordlists /usr/share/wordlists/dirb
#--- Linking to more - files
#ln -sf /usr/share/sqlmap/txt/wordlist.txt /usr/share/wordlists/sqlmap.txt
##--- Not enough? Want more? Check below!
##apt-cache search wordlist
##find / \( -iname '*wordlist*' -or -iname '*passwords*' \) #-exec ls -l {} \;
#--- Remove old temp files
rm -f /tmp/10kcommon.zip


##### Installing apt-file
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}apt-file${RESET} ~ which package includes a specific file"
apt-get -y -qq install apt-file
apt-file update


##### Installing apt-show-versions
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}apt-show-versions${RESET} ~ which package version in repo"
apt-get -y -qq install apt-show-versions


###### Installing Debian weak SSH keys
#echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}Debian weak SSH keys${RESET} ~ OpenSSL predictable PRNG"
#dpkg --remove --force-depends openssh-blacklist
#grep -q '^PermitBlacklistedKeys yes' /etc/ssh/sshd_config || echo PermitBlacklistedKeys yes >> /etc/ssh/sshd_config
#apt-get -y -qq install git
#git clone git://github.com/g0tmi1k/debian-ssh.git /opt/exploit-debianssh-git/
#pushd /usr/share/exploit-debianssh/ >/dev/null
#git pull
#popd >/dev/null


###### Installing Exploit-DB binaries
#echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}Installing Exploit-DB binaries${RESET} ~ pre-compiled exploits"
#apt-get -y -qq install git
#git clone git://github.com/offensive-security/exploit-database-bin-sploits.git /opt/exploitdb-bin-git/
#pushd /usr/share/exploitdb-bin/ >/dev/null
#git pull
#popd >/dev/null


###### Installing Babel scripts
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}Babel scripts${RESET} ~ post exploitation scripts"
apt-get -y -qq install git
git clone git://github.com/attackdebris/babel-sf.git /opt/babel-sf-git/ || echo -e "${RED}issue with git clone${RESET}"
pushd /usr/share/babel-sf-git/ >/dev/null
git pull
popd >/dev/null


###### Installing pwntools (https://bugs.kali.org/view.php?id=1236)
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}pwntools${RESET} ~ handy CTF tools"
apt-get -y -qq install git
git clone git://github.com/Gallopsled/pwntools.git /opt/pwntools-git/ || echo -e "${RED}issue with git clone${RESET}"
pushd /usr/share/pwntools-git/ >/dev/null
git pull
popd >/dev/null


###### Installing nullsecurity tool suite
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}nullsecurity tool suite${RESET} ~ collection of tools"
apt-get -y -qq install git
git clone git://github.com/nullsecuritynet/tools.git /opt/nullsecuritynet-git/ || echo -e "${RED}issue with git clone${RESET}"
pushd /usr/share/nullsecuritynet-git/ >/dev/null
git pull
popd >/dev/null


###### Installing gdb-peda (https://bugs.kali.org/view.php?id=2327)
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}gdb-peda${RESET} ~ GDB exploit development assistance"
apt-get -y -qq install git gdb
git clone git://github.com/longld/peda.git /opt/gdb-peda-git/ || echo -e "${RED}issue with git clone${RESET}"
pushd /usr/share/gdb-peda-git/ >/dev/null
git pull
popd >/dev/null
echo "source ~/peda/peda.py" >> ~/.gdbinit


###### Installing radare2 (https://bugs.kali.org/view.php?id=2169)
#echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}radare2${RESET} ~ reverse engineering framework"
#apt-get -y -qq install git gdb
#git clone git://github.com/radare/radare2.git /opt/radare2-git/
#pushd /usr/share/radare2-git/ >/dev/null
#git pull
#bash sys/install.sh
#popd >/dev/null


###### Installing ropeme (https://bugs.kali.org/view.php?id=2328)
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}ropeme${RESET} ~ generate ROP gadgets and payload"
apt-get -y -qq install git python-distorm3 libdistorm64-1 libdistorm64-dev binutils
git clone git://github.com/packz/ropeme.git /opt/ropeme-git/ || echo -e "${RED}issue with git clone${RESET}"
pushd /usr/share/ropeme-git/ >/dev/null
git reset --hard HEAD
git pull
sed -i 's/distorm/distorm3/g' ropeme/gadgets.py
popd >/dev/null
#--- Add to path
file=/usr/local/bin/ropeme-git
cat <<EOF > "${file}"
#!/bin/bash

cd /opt/ropeme-git/ && python ropeme/ropshell.py "\$@"
EOF
chmod +x "${file}"


###### Installing ropper (https://bugs.kali.org/view.php?id=2329)
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}ropper${RESET} ~ generate ROP gadgets and payload"
apt-get -y -qq install git python-capstone
git clone git://github.com/sashs/Ropper.git /opt/ropper-git/ || echo -e "${RED}issue with git clone${RESET}"
pushd /usr/share/ropper-git/ >/dev/null
git pull
python setup.py install
popd >/dev/null


###### Installing dissy
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}dissy${RESET} ~ GUI objdump"
apt-get -y -qq install dissy binutils


###### Installing shellnoob
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}shellnoob${RESET} ~ shellcode writing toolkit"
apt-get -y -qq install shellnoob


##### Installing checksec
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}checksec${RESET} ~ check *nix OS for security features"
apt-get -y -qq install curl
mkdir -p /usr/share/checksec/
file=/usr/share/checksec/checksec.sh
curl --progress -k -L -f "http://www.trapkit.de/tools/checksec.sh" > "${file}"     #***!!! hardcoded patch
chmod +x "${file}"


##### Installing shellconv
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}shellconv${RESET} ~ shellcode disassembler"
apt-get -y -qq install git
git clone git://github.com/hasherezade/shellconv.git /opt/shellconv-git/ || echo -e "${RED}issue with git clone${RESET}"
pushd /usr/share/shellconv-git/ >/dev/null
git pull
popd >/dev/null
#--- Add to path
file=/usr/local/bin/shellconv-git
cat <<EOF > "${file}"
#!/bin/bash

cd /opt/shellconv-git/ && python shellconv.py "\$@"
EOF
chmod +x "${file}"


##### Installing bless
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}bless${RESET} ~ GUI hex editor"
apt-get -y -qq install bless


##### Installing dhex
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}dhex${RESET} ~ CLI hex compare"
apt-get -y -qq install dhex


##### Installing firmware-mod-kit
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}firmware-mod-kit${RESET} ~ customize firmware"
apt-get -y -qq install firmware-mod-kit


if [[ "$(uname -m)" == "x86_64" ]]; then
  ##### Installing lnav
  echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}lnav (x64)${RESET} ~ CLI log veiwer"
# apt-get -y -qq install git ncurses-dev libsqlite3-dev libgpm-dev
# git clone git://github.com/tstack/lnav.git /usr/local/src/tstack-git/
# pushd /usr/local/src/tstack >/dev/null
# git pull
# ./configure
# make
# make install
# popd >/dev/null
  curl --progress -k -L -f "https://github.com/tstack/lnav/releases/download/v0.7.3/lnav-0.7.3-linux-64bit.zip" > /tmp/lnav.zip   #***!!! hardcoded version! Need to manually check for updates
  unzip -q -o -d /tmp/ /tmp/lnav.zip
  #--- Add to path
  mv -f /tmp/lnav-*/lnav /usr/bin/
fi


##### Installing sqlmap (GIT)
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}sqlmap${RESET} (GIT) ~ automatic SQL injection"
apt-get -y -qq install git
git clone git://github.com/sqlmapproject/sqlmap.git /opt/sqlmap-git/ || echo -e "${RED}issue with git clone${RESET}"
pushd /usr/share/sqlmap-git/ >/dev/null
git pull
popd >/dev/null
#--- Add to path
file=/usr/local/bin/sqlmap-git
cat <<EOF > "${file}"
#!/bin/bash

cd /opt/sqlmap-git/ && python sqlmap.py "\$@"
EOF
chmod +x "${file}"


##### Installing commix (https://bugs.kali.org/view.php?id=2201)
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}commix${RESET} ~ automatic command injection"
apt-get -y -qq install git
git clone git://github.com/stasinopoulos/commix.git /opt/commix-git/ || echo -e "${RED}issue with git clone${RESET}"
pushd /usr/share/commix-git/ >/dev/null
git pull
popd >/dev/null
#--- Add to path
file=/usr/local/bin/commix-git
cat <<EOF > "${file}"
#!/bin/bash

cd /opt/commix-git/ && python commix.py "\$@"
EOF
chmod +x "${file}"


##### Installing fimap
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}fimap${RESET} ~ automatic LFI/RFI tool"
apt-get -y -qq install fimap


##### Installing smbmap
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}smbmap${RESET} ~ SMB enumeration tool"
apt-get -y -qq install smbmap


##### Installing wig (https://bugs.kali.org/view.php?id=1932)
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}wig${RESET} ~ web application detection"
apt-get -y -qq install git
git clone git://github.com/jekyc/wig.git /opt/wig-git/ || echo -e "${RED}issue with git clone${RESET}"
pushd /usr/share/wig-git/ >/dev/null
git pull
popd >/dev/null
#--- Add to path
file=/usr/local/bin/wig-git
cat <<EOF > "${file}"
#!/bin/bash

cd /opt/wig-git/ && python wig.py "\$@"
EOF
chmod +x "${file}"


##### Installing CMSmap
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}CMSmap${RESET} ~ CMS detection"
apt-get -y -qq install git
git clone git://github.com/Dionach/CMSmap.git /opt/cmsmap-git/ || echo -e "${RED}issue with git clone${RESET}"
pushd /usr/share/cmsmap-git/ >/dev/null
git pull
popd >/dev/null
#--- Add to path
file=/usr/local/bin/cmsmap-git
cat <<EOF > "${file}"
#!/bin/bash

cd /opt/cmsmap-git/ && python cmsmap.py "\$@"
EOF
chmod +x "${file}"


###### Installing CMSScanner
#echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}CMSScanner${RESET} ~ CMS detection"
#apt-get -y -qq install git
#git clone git://github.com/wpscanteam/CMSScanner.git /opt/cmsscanner-git/
#pushd /usr/share/cmsscanner-git/ >/dev/null
#git pull
#bundle install
#popd >/dev/null


##### Installing droopescan
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}droopescan${RESET} ~ Drupal vulnerability scanner"
apt-get -y -qq install git
git clone git://github.com/droope/droopescan.git /opt/droopescan-git/ || echo -e "${RED}issue with git clone${RESET}"
pushd /usr/share/droopescan-git/ >/dev/null
git pull
popd >/dev/null
#--- Add to path
file=/usr/local/bin/droopescan-git
cat <<EOF > "${file}"
#!/bin/bash

cd /opt/droopescan-git/ && python droopescan "\$@"
EOF
chmod +x "${file}"


##### Installing wpscan (GIT)
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}wpscan${RESET} (GIT) ~ WordPress vulnerability scanner"
apt-get -y -qq install git
git clone git://github.com/wpscanteam/wpscan.git /opt/wpscan-git/ || echo -e "${RED}issue with git clone${RESET}"
pushd /usr/share/wpscan-git/ >/dev/null
git pull
popd >/dev/null
#--- Add to path
file=/usr/local/bin/wpscan-git
cat <<EOF > "${file}"
#!/bin/bash

cd /opt/wpscan-git/ && ruby wpscan.rb "\$@"
EOF
chmod +x "${file}"


##### Installing BeEF XSS
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}BeEF XSS${RESET} ~ XSS framework"
apt-get -y -qq install beef-xss
#--- Configure beef
file=/usr/share/beef-xss/config.yaml; [ -e "${file}" ] && cp -n $file{,.bkup}
username="root"
password="toor"
sed -i 's/user:.*".*"/user:   "'${username}'"/' "${file}"
sed -i 's/passwd:.*".*"/passwd:  "'${password}'"/'  "${file}"
echo -e " $YELLOW[i]$RESET BeEF username: ${username}"
echo -e " $YELLOW[i]$RESET BeEF password: ${password}   *** ${BOLD}CHANGE THIS ASAP${RESET}.   Edit: /usr/share/beef-xss/config.yaml"
#--- Example hook
#<script src="http://192.168.155.175:3000/hook.js" type="text/javascript"></script>


##### Installing patator (GIT)
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}patator${RESET} (GIT) ~ brute force"
apt-get -y -qq install git
git clone git://github.com/lanjelot/patator.git /opt/patator-git/ || echo -e "${RED}issue with git clone${RESET}"
pushd /usr/share/patator-git/ >/dev/null
git pull
popd >/dev/null
#--- Add to path
file=/usr/local/bin/patator-git
cat <<EOF > "${file}"
#!/bin/bash

cd /opt/patator-git/ && python patator.py "\$@"
EOF
chmod +x "${file}"


##### Installing crowbar
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}crowbar${RESET} ~ brute force"
apt-get -y -qq install git
git clone git://github.com/galkan/crowbar.git /opt/crowbar-git/ || echo -e "${RED}issue with git clone${RESET}"
pushd /usr/share/crowbar-git/ >/dev/null
git pull
popd >/dev/null
#--- Add to path
file=/usr/local/bin/crowbar-git
cat <<EOF > "${file}"
#!/bin/bash

cd /opt/crowbar-git/ && python crowbar.py "\$@"
EOF
chmod +x "${file}"


##### Installing xprobe
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}xprobe{RESET} ~ os fingerprinting"
apt-get install -y -qq xprobe


##### Installing p0f
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}p0f${RESET} ~ os fingerprinting"
apt-get install -y -qq p0f
#p0f -i eth0 -p & curl 192.168.0.1


##### Installing nbtscan ~ http://unixwiz.net/tools/nbtscan.html vs http://inetcat.org/software/nbtscan.html (see http://sectools.org/tool/nbtscan/)
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}nbtscan (unixwiz)${RESET} ~ netbios scanner"
#--- inetcat - 1.5.x
apt-get install -y -qq nbtscan
#nbtscan -r 192.168.0.1/24
#nbtscan -r 192.168.0.1/24 -v
#--- unixwiz - 1.0.x
mkdir -p /usr/local/src/nbtscan-unixwiz/
curl --progress -k -L -f "http://unixwiz.net/tools/nbtscan-source-1.0.35.tgz" > /usr/local/src/nbtscan-unixwiz/nbtscan.tgz    #***!!! hardcoded version! Need to manually check for updates
tar -zxf /usr/local/src/nbtscan-unixwiz/nbtscan.tgz -C /usr/local/src/nbtscan-unixwiz/
pushd /usr/local/src/nbtscan-unixwiz/ >/dev/null
make -s
popd >/dev/null
ln -sf /usr/local/src/nbtscan-unixwiz/nbtscan /usr/bin/nbtscan-uw
#nbtscan-uw -f 192.168.0.1/24


##### Setting up tftp client & server
echo -e "\n ${GREEN}[+]${RESET} Setting up ${GREEN}tftp client & server${RESET} ~ file transfer methods"
apt-get -y -qq install tftp || echo -e "${RED}issue with apt${RESET}"   # tftp client
apt-get -y -qq install atftpd || echo -e "${RED}issue with apt${RESET}"   # tftp server
#--- Configure atftpd
file=/etc/default/atftpd; [ -e "${file}" ] && cp -n $file{,.bkup}
echo -e 'USE_INETD=false\nOPTIONS="--tftpd-timeout 300 --retry-timeout 5 --maxthread 100 --verbose=5 --daemon --port 69 /var/tftp"' > "${file}"
mkdir -p /var/tftp/
chown -R nobody\:root /var/tftp/
chmod -R 0755 /var/tftp/
#--- Setup alias
file=/root/.bash_aliases; [ -e "${file}" ] && cp -n $file{,.bkup}   #/etc/bash.bash_aliases
([[ -e "${file}" && "$(tail -c 1 $file)" != "" ]]) && echo >> "${file}"
grep -q '^## tftp' "${file}" 2>/dev/null || echo -e '## tftp\nalias tftproot="cd /var/tftp/"\n' >> "${file}"                                        # service atftpd start
#--- Remove from start up
update-rc.d -f atftpd remove
#--- Disabling IPv6 can help
#echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6
#echo 1 > /proc/sys/net/ipv6/conf/default/disable_ipv6


##### Installing pure-ftpd
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}pure-ftpd${RESET} ~ FTP server/file transfer method"
apt-get -y -qq install pure-ftpd
#--- Setup pure-ftpd
mkdir -p /var/ftp/
groupdel ftpgroup 2>/dev/null; groupadd ftpgroup
userdel ftp 2>/dev/null; useradd -r -M -d /var/ftp/ -s /bin/false -c "FTP user" -g ftpgroup ftp
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
echo "30768 31768" > /etc/pure-ftpd/conf/PassivePortRange             #cat /proc/sys/net/ipv4/ip_local_port_range
echo "/etc/pure-ftpd/welcome.msg" > /etc/pure-ftpd/conf/FortunesFile  #/etc/motd
echo "FTP" > /etc/pure-ftpd/welcome.msg
#--- 'Better' MOTD
apt-get install -y -qq cowsay
echo "Moo" | /usr/games/cowsay > /etc/pure-ftpd/welcome.msg
#--- SSL
#mkdir -p /etc/ssl/private/
#openssl req -x509 -nodes -newkey rsa:4096 -keyout /etc/ssl/private/pure-ftpd.pem -out /etc/ssl/private/pure-ftpd.pem
#chmod -f 0600 /etc/ssl/private/*.pem
ln -sf /etc/pure-ftpd/conf/PureDB /etc/pure-ftpd/auth/50pure
#--- Apply settings
#service pure-ftpd restart
#--- Setup alias
file=/root/.bash_aliases; [ -e "${file}" ] && cp -n $file{,.bkup}   #/etc/bash.bash_aliases
([[ -e "${file}" && "$(tail -c 1 $file)" != "" ]]) && echo >> "${file}"
grep -q '^## ftp' "${file}" 2>/dev/null || echo -e '## ftp\nalias ftproot="cd /var/ftp/"\n' >> "${file}"                                            # service pure-ftpd start
#--- Remove from start up
update-rc.d -f pure-ftpd remove


##### Installing samba
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}samba${RESET} ~ file transfer method"
#--- Installing samba
apt-get -y -qq install samba
apt-get -y -qq install cifs-utils
#--- Create samba user
groupdel smbgroup 2>/dev/null; groupadd smbgroup
userdel samba 2>/dev/null; useradd -r -M -d /nonexistent -s /bin/false -c "Samba user" -g smbgroup samba
#--- Use the samba user
file=/etc/samba/smb.conf; [ -e "${file}" ] && cp -n $file{,.bkup}
sed -i 's/guest account = .*/guest account = samba/' "${file}" 2>/dev/null
grep -q 'guest account' "${file}" 2>/dev/null || sed -i 's#\[global\]#\[global\]\n   guest account = samba#' "${file}"
#--- Setup samba paths
grep -q '^\[shared\]' "${file}" 2>/dev/null || cat <<EOF >> "${file}"

[shared]
  comment = Shared
  path = /var/samba/
  browseable = yes
  guest ok = yes
  #guest only = yes
  read only = no
  writable = yes
  create mask = 0644
  directory mask = 0755
EOF
#--- Create samba path and configure it
mkdir -p /var/samba/
chown -R samba\:smbgroup /var/samba/
chmod -R 0755 /var/samba/   #chmod 0777 /var/samba/
#--- Bug fix
touch /etc/printcap
#--- Check result
#service samba restart
#smbclient -L \\127.0.0.1 -N
#mount -t cifs -o guest //192.168.1.2/share /mnt/smb     mkdir -p /mnt/smb
#--- Disable samba at startup
service samba stop
update-rc.d -f samba remove
#--- Setup alias
file=/root/.bash_aliases; [ -e "${file}" ] && cp -n $file{,.bkup}   #/etc/bash.bash_aliases
([[ -e "${file}" && "$(tail -c 1 $file)" != "" ]]) && echo >> "${file}"
grep -q '^## smb' "${file}" 2>/dev/null || echo -e '## smb\nalias sambaroot="cd /var/samba/"\n#alias smbroot="cd /var/samba/"\n' >> "${file}"


##### Installing apache2
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}apache2${RESET} ~ web server"
touch /var/www/favicon.ico
#--- Setup alias
file=/root/.bash_aliases; [ -e "${file}" ] && cp -n $file{,.bkup}   #/etc/bash.bash_aliases
([[ -e "${file}" && "$(tail -c 1 $file)" != "" ]]) && echo >> "${file}"
grep -q '^## www' "${file}" 2>/dev/null || echo -e '## www\nalias wwwroot="cd /var/www/"\n' >> "${file}"                                            # service apache2 start


###### Installing rsh-client
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}rsh-client${RESET} ~ remote shell connections"
apt-get -y -qq install rsh-client


##### Installing sshpass
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}sshpass${RESET} ~ automating SSH connections"
apt-get -y -qq install sshpass


##### Installing DBeaver
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}DBeaver${RESET} ~ GUI DB manager"
apt-get -y -qq install curl
arch="i386"
[[ "$(uname -m)" == "x86_64" ]] && arch="amd64"
curl --progress -k -L -f "http://dbeaver.jkiss.org/files/dbeaver_3.4.1_$arch.deb" > /tmp/dbeaver.deb   #***!!! hardcoded version! Need to manually check for updates
dpkg -i /tmp/dbeaver.deb
#--- Add to path
ln -sf /usr/share/dbeaver/dbeaver /usr/bin/dbeaver


##### Setting up a jail ~ http://allanfeid.com/content/creating-chroot-jail-ssh-access
echo -e "\n ${GREEN}[+]${RESET} Setting up a ${GREEN}jail${RESET} ~ testing environment"
apt-get -y -qq install debootstrap curl
#mkdir -p /var/jail/
#debootstrap wheezy /var/jail/
#SHELL=/bin/bash
#chroot /var/jail
#---
#mkdir -p /var/jail/{dev,etc,lib,usr,bin}/
#mkdir -p /var/jail/{,usr/}bin/
#chown root\:root /var/jail
#mknod -m 666 /var/jail/dev/null c 1 3
#cp -f /etc/ld.so.cache /etc/ld.so.cache /etc/ld.so.conf /etc/nsswitch.conf /etc/hosts /var/jail/etc/
#cp -f /bin/ls /bin/bash /var/jail/bin/
##ldd /bin/ls
#curl --progress -k -L -f "http://www.cyberciti.biz/files/lighttpd/l2chroot.txt" > /usr/sbin/l2chroot        #***!!! hardcoded path!
#sed -i 's#^BASE=".*"#BASE="/var/jail"#' /usr/sbin/l2chroot
#chmod +x /usr/sbin/l2chroot


##### Configuring pythcon console - all users
echo -e "\n ${GREEN}[+]${RESET} Configuring ${GREEN}pythcon console${RESET} ~ tab complete & history support"
export PYTHONSTARTUP=$HOME/.pythonstartup
file=/etc/bash.bashrc; [ -e "${file}" ] && cp -n $file{,.bkup}    #/root/.bashrc
grep -q PYTHONSTARTUP $file || echo 'export PYTHONSTARTUP=$HOME/.pythonstartup' >> "${file}"
#--- Python start up file
cat <<EOF > /root/.pythonstartup
import readline
import rlcompleter
import atexit
import os

## Tab completion
readline.parse_and_bind('tab: complete')

## History file
histfile = os.path.join(os.environ['HOME'], '.pythonhistory')
try:
    readline.read_history_file(histfile)
except IOError:
    pass

atexit.register(readline.write_history_file, histfile)

## Quit
del os, histfile, readline, rlcompleter
EOF
if [[ "$SHELL" == "/bin/zsh" ]]; then source ~/.zshrc else source "${file}"; fi


###### Installing virtualenvwrapper
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}virtualenvwrapper${RESET} ~ virtual environment wrapper"
apt-get -y -qq install virtualenvwrapper


###### Installing go
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}go${RESET} ~ programming language"
apt-get -y -qq install golang


###### Installing giggle
#echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}giggle${RESET} ~ GUI git client"
#apt-get -y -qq install giggle


###### Installing gitg
echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}gitg${RESET} ~ GUI git client"
apt-get -y -qq install gitg


##### Setting up SSH
echo -e "\n ${GREEN}[+]${RESET} Setting up ${GREEN}SSH${RESET}"
apt-get -y -qq install openssh-server
#--- Wipe current keys
rm -f /etc/ssh/ssh_host_*
find /root/.ssh/ -type f ! -name authorized_keys -delete 2>/dev/null   #rm -f "/root/.ssh/!(authorized_keys)" 2>/dev/null
#--- Generate new keys
#ssh-keygen -A   # Automatic method - we lose control of amount of bits used
ssh-keygen -b 4096 -t rsa1 -f /etc/ssh/ssh_host_key -P ""
ssh-keygen -b 4096 -t rsa -f /etc/ssh/ssh_host_rsa_key -P ""
ssh-keygen -b 1024 -t dsa -f /etc/ssh/ssh_host_dsa_key -P ""
ssh-keygen -b 521 -t ecdsa -f /etc/ssh/ssh_host_ecdsa_key -P ""
ssh-keygen -b 4096 -t rsa -f /root/.ssh/id_rsa -P ""
#--- Change MOTD
apt-get install -y -qq cowsay
echo "Kali Linux" | /usr/games/cowsay > /etc/motd
#--- Change SSH settings
file=/etc/ssh/sshd_config; [ -e "${file}" ] && cp -n $file{,.bkup}
sed -i 's/^PermitRootLogin .*/PermitRootLogin yes/g' "${file}"
#sed -i 's/^Port .*/Port 2222/g' "${file}"
#--- Enable ssh at startup
#update-rc.d -f ssh enable


###### Setting up G/UFW
#echo -e "\n ${GREEN}[+]${RESET} Installing ${GREEN}G/UFW${RESET} ~ firewall rule generator"
#apt-get -y -qq install ufw gufw


##### Cleaning the system
echo -e "\n ${GREEN}[+]${RESET} ${GREEN}Cleaning${RESET} the system"
#--- Clean package manager
for FILE in clean autoremove; do apt-get -y -qq "${FILE}"; done         # Clean up - clean remove autoremove autoclean
apt-get -y -qq purge $(dpkg -l | tail -n +6 | egrep -v '^(h|i)i' | awk '{print $2}')   # Purged packages
#--- Update slocate database
updatedb
#--- Reset folder location
cd ~/ &>/dev/null
#--- Remove any history files (as they could contain sensitive info)
[[ "$SHELL" == "/bin/zsh" ]] || history -c
for i in $(cut -d: -f6 /etc/passwd | sort -u); do
  [ -e "$i" ] && find "$i" -type f -name '.*_history' -delete
done

if [ "$freezeDEB" != "false" ]; then
  ##### Don't ever update these packages (during this install!)
  echo -e "\n ${GREEN}[+]${RESET} ${GREEN}Don't update${RESET} these packages:"
  for x in metasploit metasploit-framework metasploit-common; do
    echo -e " $YELLOW[i]$RESET   + $x"
    echo "$x install" | dpkg --set-selections
  done
fi


##### Time taken
finish_time=$(date +%s)
echo -e "\n ${YELLOW}[i]${RESET} Time (roughly) taken: ${YELLOW}$(( $(( finish_time - start_time )) / 60 ))${RESET} minutes"


#-Done-----------------------------------------------------------------#


##### Done!
echo -e "\n ${YELLOW}[i]${RESET} Don't forget to:"
echo -e " ${YELLOW}[i]${RESET}   + Check the above output (Did everything installed? No errors?)"
#echo -e " ${YELLOW}[i]${RESET}   + Check that Iceweasel's extensions are enabled (as well as FoxyProxy profiles)"
echo -e " ${YELLOW}[i]${RESET}   + Manually install: Nessus, Nexpose and/or Metasploit Community"
echo -e " ${YELLOW}[i]${RESET}   + Agree/Accept to: Maltego, OWASP ZAP, w3af etc"
echo -e " ${YELLOW}[i]${RESET}   + ${YELLOW}Change time zone & keyboard layout${RESET} (...if not ${YELLOW}${timezone} & ${keyboardlayout}${RESET})"
echo -e " ${YELLOW}[i]${RESET}   + ${YELLOW}Change default passwords${RESET}: PostgreSQL/MSF, MySQL, OpenVAS, BeEF XSS etc"
echo -e " ${YELLOW}[i]${RESET}   + ${YELLOW}Reboot${RESET}"
(dmidecode | grep -iq virtual) && echo -e " ${YELLOW}[i]${RESET}   + Take a snapshot"

echo -e '\n'${BLUE}'[*]'${RESET}' Done!\n\a'
#reboot
exit 0







alias wordlist="cd /usr/share/wordlist/"