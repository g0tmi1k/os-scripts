#!/bin/bash
#-Metadata----------------------------------------------------#
#  Filename: kali-rolling.sh             (Update: 2016-09-21) #
#-Info--------------------------------------------------------#
#  Personal post-install script for Kali Linux Rolling        #
#-Author(s)---------------------------------------------------#
#  g0tmilk ~ https://blog.g0tmi1k.com/                        #
#-Operating System--------------------------------------------#
#  Designed for: Kali Linux Rolling [x64] (VM - VMware)       #
#     Tested on: Kali Linux 2016.2 x64/x84/full/light/mini/vm #
#     Kali v1.x: https://g0tmi1k/os-scripts/master/kali1.sh   #
#     Kali v2.x: https://g0tmi1k/os-scripts/master/kali2.sh   #
#-Licence-----------------------------------------------------#
#  MIT License ~ http://opensource.org/licenses/MIT           #
#-Notes-------------------------------------------------------#
#  Run as root straight after a clean install of Kali Rolling #
#                             ---                             #
#  You will need 25GB+ free HDD space before running.         #
#                             ---                             #
#  Command line arguments:                                    #
#    -burp     = Automates configuring Burp Suite (Community) #
#    -dns      = Use OpenDNS and locks permissions            #
#    -openvas  = Installs & configures OpenVAS vuln scanner   #
#    -osx      = Changes to Apple keyboard layout             #
#                                                             #
#    -keyboard <value> = Change the keyboard layout language  #
#    -timezone <value> = Change the timezone location         #
#                                                             #
#  e.g. # bash kali-rolling.sh -burp -keyboard gb -openvas    #
#                             ---                             #
#  Will cut it up (so modular based), at a later date...      #
#                             ---                             #
#             ** This script is meant for _ME_. **            #
#         ** EDIT this to meet _YOUR_ requirements! **        #
#-------------------------------------------------------------#


if [ 1 -eq 0 ]; then    # This is never true, thus it acts as block comments ;)
################################################################################
### One liner - Grab the latest version and execute! ###########################
################################################################################
wget -qO kali-rolling.sh https://raw.github.com/g0tmi1k/os-scripts/master/kali-rolling.sh \
  && bash kali-rolling.sh -burp -keyboard gb -timezone "Europe/London"
################################################################################
fi


#-Defaults-------------------------------------------------------------#


##### Location information
keyboardApple=false         # Using a Apple/Macintosh keyboard (non VM)?                [ --osx ]
keyboardLayout=""           # Set keyboard layout                                       [ --keyboard gb]
timezone=""                 # Set timezone location                                     [ --timezone Europe/London ]

##### Optional steps
burpFree=false              # Disable configuring Burp Suite (for Burp Pro users...)    [ --burp ]
hardenDNS=false             # Set static & lock DNS name server                         [ --dns ]
openVAS=false               # Install & configure OpenVAS (not everyone wants it...)    [ --openvas ]

##### (Optional) Enable debug mode?
#set -x

##### (Cosmetic) Colour output
RED="\033[01;31m"      # Issues/Errors
GREEN="\033[01;32m"    # Success
YELLOW="\033[01;33m"   # Warnings/Information
BLUE="\033[01;34m"     # Heading
BOLD="\033[01;01m"     # Highlight
RESET="\033[00m"       # Normal

STAGE=0                                                         # Where are we up to
TOTAL=$( grep '(${STAGE}/${TOTAL})' $0 | wc -l );(( TOTAL-- ))  # How many things have we got todo


#-Arguments------------------------------------------------------------#


##### Read command line arguments
while [[ "${#}" -gt 0 && ."${1}" == .-* ]]; do
  opt="${1}";
  shift;
  case "$(echo ${opt} | tr '[:upper:]' '[:lower:]')" in
    -|-- ) break 2;;

    -osx|--osx )
      keyboardApple=true;;
    -apple|--apple )
      keyboardApple=true;;

    -dns|--dns )
      hardenDNS=true;;

    -openvas|--openvas )
      openVAS=true;;

    -burp|--burp )
      burpFree=true;;

    -keyboard|--keyboard )
      keyboardLayout="${1}"; shift;;
    -keyboard=*|--keyboard=* )
      keyboardLayout="${opt#*=}";;

    -timezone|--timezone )
      timezone="${1}"; shift;;
    -timezone=*|--timezone=* )
      timezone="${opt#*=}";;

    *) echo -e ' '${RED}'[!]'${RESET}" Unknown option: ${RED}${x}${RESET}" 1>&2 \
      && exit 1;;
   esac
done


##### Check user inputs
if [[ -n "${timezone}" && ! -f "/usr/share/zoneinfo/${timezone}" ]]; then
  echo -e ' '${RED}'[!]'${RESET}" Looks like the ${RED}timezone '${timezone}'${RESET} is incorrect/not supported (Example: ${BOLD}Europe/London${RESET})" 1>&2
  echo -e ' '${RED}'[!]'${RESET}" Quitting..." 1>&2
  exit 1
elif [[ -n "${keyboardLayout}" && -e /usr/share/X11/xkb/rules/xorg.lst ]]; then
  if ! $(grep -q " ${keyboardLayout} " /usr/share/X11/xkb/rules/xorg.lst); then
    echo -e ' '${RED}'[!]'${RESET}" Looks like the ${RED}keyboard layout '${keyboardLayout}'${RESET} is incorrect/not supported (Example: ${BOLD}gb${RESET})" 1>&2
    echo -e ' '${RED}'[!]'${RESET}" Quitting..." 1>&2
    exit 1
  fi
fi


#-Start----------------------------------------------------------------#


##### Check if we are running as root - else this script will fail (hard!)
if [[ "${EUID}" -ne 0 ]]; then
  echo -e ' '${RED}'[!]'${RESET}" This script must be ${RED}run as root${RESET}" 1>&2
  echo -e ' '${RED}'[!]'${RESET}" Quitting..." 1>&2
  exit 1
else
  echo -e " ${BLUE}[*]${RESET} ${BOLD}Kali Linux rolling post-install script${RESET}"
  sleep 3s
fi

if [ "${burpFree}" != "true" ]; then
  echo -e "\n\n ${YELLOW}[i]${RESET} ${YELLOW}Skipping Burp Suite${RESET} (missing: '$0 ${BOLD}--burp${RESET}')..." 1>&2
  sleep 2s
fi


##### Fix display output for GUI programs (when connecting via SSH)
export DISPLAY=:0.0
export TERM=xterm


##### Are we using GNOME?
if [[ $(which gnome-shell) ]]; then
  ##### RAM check
  if [[ "$(free -m | grep -i Mem | awk '{print $2}')" < 2048 ]]; then
    echo -e '\n '${RED}'[!]'${RESET}" ${RED}You have <= 2GB of RAM and using GNOME${RESET}" 1>&2
    echo -e " ${YELLOW}[i]${RESET} ${YELLOW}Might want to use XFCE instead${RESET}..."
    sleep 15s
  fi


  ##### Disable its auto notification package updater
  (( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Disabling GNOME's ${GREEN}notification package updater${RESET} service ~ in case it runs during this script"
  export DISPLAY=:0.0
  timeout 5 killall -w /usr/lib/apt/methods/http >/dev/null 2>&1


  ##### Disable screensaver
  (( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Disabling ${GREEN}screensaver${RESET}"
  xset s 0 0
  xset s off
  gsettings set org.gnome.desktop.session idle-delay 0
else
  echo -e "\n\n ${YELLOW}[i]${RESET} ${YELLOW}Skipping disabling package updater${RESET}..."
fi


##### Check Internet access
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Checking ${GREEN}Internet access${RESET}"
#--- Can we ping google?
for i in {1..10}; do ping -c 1 -W ${i} www.google.com &>/dev/null && break; done
#--- Run this, if we can't
if [[ "$?" -ne 0 ]]; then
  echo -e ' '${RED}'[!]'${RESET}" ${RED}Possible DNS issues${RESET}(?)" 1>&2
  echo -e ' '${RED}'[!]'${RESET}" Will try and use ${YELLOW}DHCP${RESET} to 'fix' the issue" 1>&2
  chattr -i /etc/resolv.conf 2>/dev/null
  dhclient -r
  #--- Second interface causing issues?
  ip addr show eth1 &>/dev/null
  [[ "$?" == 0 ]] \
    && route delete default gw 192.168.155.1 2>/dev/null
  #--- Request a new IP
  dhclient
  dhclient eth0 2>/dev/null
  dhclient wlan0 2>/dev/null
  #--- Wait and see what happens
  sleep 15s
  _TMP="true"
  _CMD="$(ping -c 1 8.8.8.8 &>/dev/null)"
  if [[ "$?" -ne 0 && "$_TMP" == "true" ]]; then
    _TMP="false"
    echo -e ' '${RED}'[!]'${RESET}" ${RED}No Internet access${RESET}" 1>&2
    echo -e ' '${RED}'[!]'${RESET}" You will need to manually fix the issue, before re-running this script" 1>&2
  fi
  _CMD="$(ping -c 1 www.google.com &>/dev/null)"
  if [[ "$?" -ne 0 && "$_TMP" == "true" ]]; then
    _TMP="false"
    echo -e ' '${RED}'[!]'${RESET}" ${RED}Possible DNS issues${RESET}(?)" 1>&2
    echo -e ' '${RED}'[!]'${RESET}" You will need to manually fix the issue, before re-running this script" 1>&2
  fi
  if [[ "$_TMP" == "false" ]]; then
    (dmidecode | grep -iq virtual) && echo -e " ${YELLOW}[i]${RESET} VM Detected"
    (dmidecode | grep -iq virtual) && echo -e " ${YELLOW}[i]${RESET} ${YELLOW}Try switching network adapter mode${RESET} (e.g. NAT/Bridged)"
    echo -e ' '${RED}'[!]'${RESET}" Quitting..." 1>&2
    exit 1
  fi
else
  echo -e " ${YELLOW}[i]${RESET} ${YELLOW}Detected Internet access${RESET}" 1>&2
fi
#--- GitHub under DDoS?
(( STAGE++ )); echo -e " ${GREEN}[i]${RESET} (${STAGE}/${TOTAL}) Checking ${GREEN}GitHub status${RESET}"
timeout 300 curl --progress -k -L -f "https://status.github.com/api/status.json" | grep -q "good" \
  || (echo -e ' '${RED}'[!]'${RESET}" ${RED}GitHub is currently having issues${RESET}. ${BOLD}Lots may fail${RESET}. See: https://status.github.com/" 1>&2 \
    && exit 1)


##### Enable default network repositories ~ http://docs.kali.org/general-use/kali-linux-sources-list-repositories
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Enabling default OS ${GREEN}network repositories${RESET}"
#--- Add network repositories
file=/etc/apt/sources.list; [ -e "${file}" ] && cp -n $file{,.bkup}
([[ -e "${file}" && "$(tail -c 1 ${file})" != "" ]]) && echo >> "${file}"
#--- Main
grep -q '^deb .* kali-rolling' "${file}" 2>/dev/null \
  || echo -e "\n\n# Kali Rolling\ndeb http://http.kali.org/kali kali-rolling main contrib non-free" >> "${file}"
#--- Source
grep -q '^deb-src .* kali-rolling' "${file}" 2>/dev/null \
  || echo -e "deb-src http://http.kali.org/kali kali-rolling main contrib non-free" >> "${file}"
#--- Disable CD repositories
sed -i '/kali/ s/^\( \|\t\|\)deb cdrom/#deb cdrom/g' "${file}"
#--- incase we were interrupted
dpkg --configure -a
#--- Update
apt -qq update
if [[ "$?" -ne 0 ]]; then
  echo -e ' '${RED}'[!]'${RESET}" There was an ${RED}issue accessing network repositories${RESET}" 1>&2
  echo -e " ${YELLOW}[i]${RESET} Are the remote network repositories ${YELLOW}currently being sync'd${RESET}?"
  echo -e " ${YELLOW}[i]${RESET} Here is ${BOLD}YOUR${RESET} local network ${BOLD}repository${RESET} information (Geo-IP based):\n"
  curl -sI http://http.kali.org/README
  exit 1
fi


##### Check to see if Kali is in a VM. If so, install "Virtual Machine Addons/Tools" for a "better" virtual experiment
if (dmidecode | grep -iq vmware); then
  ##### Install virtual machines tools ~ http://docs.kali.org/general-use/install-vmware-tools-kali-guest
  (( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}VMware's (open) virtual machine tools${RESET}"
  apt -y -qq install open-vm-tools-desktop fuse \
    || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
  apt -y -qq install make \
    || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2    # There's a nags afterwards
  ## Shared folders support for Open-VM-Tools (some odd bug)
  file=/usr/local/sbin/mount-shared-folders; [ -e "${file}" ] && cp -n $file{,.bkup}
  cat <<EOF > "${file}" \
    || echo -e ' '${RED}'[!] Issue with writing file'${RESET} 1>&2
#!/bin/bash

vmware-hgfsclient | while read folder; do
  echo "[i] Mounting \${folder}   (/mnt/hgfs/\${folder})"
  mkdir -p "/mnt/hgfs/\${folder}"
  umount -f "/mnt/hgfs/\${folder}" 2>/dev/null
  vmhgfs-fuse -o allow_other -o auto_unmount ".host:/\${folder}" "/mnt/hgfs/\${folder}"
done

sleep 2s
EOF
  chmod +x "${file}"
  ln -sf "${file}" /root/Desktop/mount-shared-folders.sh
elif (dmidecode | grep -iq virtualbox); then
  ##### Installing VirtualBox Guest Additions.   Note: Need VirtualBox 4.2.xx+ for the host (http://docs.kali.org/general-use/kali-linux-virtual-box-guest)
  (( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}VirtualBox's guest additions${RESET}"
  apt -y -qq install virtualbox-guest-x11 \
    || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
fi


##### Check to see if there is a second Ethernet card (if so, set an static IP address)
ip addr show eth1 &>/dev/null
if [[ "$?" == 0 ]]; then
  ##### Set a static IP address (192.168.155.175/24) on eth1
  (( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Setting a ${GREEN}static IP address${RESET} (${BOLD}192.168.155.175/24${RESET}) on ${BOLD}eth1${RESET}"
  ip addr add 192.168.155.175/24 dev eth1 2>/dev/null
  route delete default gw 192.168.155.1 2>/dev/null
  file=/etc/network/interfaces.d/eth1.cfg; [ -e "${file}" ] && cp -n $file{,.bkup}
  grep -q '^iface eth1 inet static' "${file}" 2>/dev/null \
    || cat <<EOF > "${file}"
auto eth1
iface eth1 inet static
    address 192.168.155.175
    netmask 255.255.255.0
    gateway 192.168.155.1
    post-up route delete default gw 192.168.155.1
EOF
else
  echo -e "\n\n ${YELLOW}[i]${RESET} ${YELLOW}Skipping eth1${RESET} (missing nic)..." 1>&2
fi


##### Set static & protecting DNS name servers.   Note: May cause issues with forced values (e.g. captive portals etc)
if [[ "${hardenDNS}" != "false" ]]; then
  (( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Setting static & protecting ${GREEN}DNS name servers${RESET}"
  file=/etc/resolv.conf; [ -e "${file}" ] && cp -n $file{,.bkup}
  chattr -i "${file}" 2>/dev/null
  #--- Use OpenDNS DNS
  echo -e 'nameserver 208.67.222.222\nnameserver 208.67.220.220' > "${file}"
  #--- Use Google DNS
  #echo -e 'nameserver 8.8.8.8\nnameserver 8.8.4.4' > "${file}"
  #--- Protect it
  chattr +i "${file}" 2>/dev/null
else
  echo -e "\n\n ${YELLOW}[i]${RESET} ${YELLOW}Skipping DNS${RESET} (missing: '$0 ${BOLD}--dns${RESET}')..." 1>&2
fi


##### Update location information - set either value to "" to skip.
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Updating ${GREEN}location information${RESET}"
#--- Configure keyboard layout (Apple)
if [ "${keyboardApple}" != "false" ]; then
  ( (( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Applying ${GREEN}Apple hardware${RESET} profile" )
  file=/etc/default/keyboard; #[ -e "${file}" ] && cp -n $file{,.bkup}
  sed -i 's/XKBVARIANT=".*"/XKBVARIANT="mac"/' "${file}"
fi
#--- Configure keyboard layout (location)
if [[ -n "${keyboardLayout}" ]]; then
  (( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Updating ${GREEN}location information${RESET} ~ keyboard layout (${BOLD}${keyboardLayout}${RESET})"
  geoip_keyboard=$(curl -s http://ifconfig.io/country_code | tr '[:upper:]' '[:lower:]')
  [ "${geoip_keyboard}" != "${keyboardLayout}" ] \
    && echo -e " ${YELLOW}[i]${RESET} Keyboard layout (${BOLD}${keyboardLayout}${RESET}) doesn't match what's been detected via GeoIP (${BOLD}${geoip_keyboard}${RESET})"
  file=/etc/default/keyboard; #[ -e "${file}" ] && cp -n $file{,.bkup}
  sed -i 's/XKBLAYOUT=".*"/XKBLAYOUT="'${keyboardLayout}'"/' "${file}"
else
  echo -e "\n\n ${YELLOW}[i]${RESET} ${YELLOW}Skipping keyboard layout${RESET} (missing: '$0 ${BOLD}--keyboard <value>${RESET}')..." 1>&2
fi
#--- Changing time zone
if [[ -n "${timezone}" ]]; then
  (( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Updating ${GREEN}location information${RESET} ~ time zone (${BOLD}${timezone}${RESET})"
  echo "${timezone}" > /etc/timezone
  ln -sf "/usr/share/zoneinfo/$(cat /etc/timezone)" /etc/localtime
  dpkg-reconfigure -f noninteractive tzdata
else
  echo -e "\n\n ${YELLOW}[i]${RESET} ${YELLOW}Skipping time zone${RESET} (missing: '$0 ${BOLD}--timezone <value>${RESET}')..." 1>&2
fi
#--- Installing ntp tools
(( STAGE++ )); echo -e " ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}ntpdate${RESET} ~ keeping the time in sync"
apt -y -qq install ntp ntpdate \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
#--- Update time
ntpdate -b -s -u pool.ntp.org
#--- Start service
systemctl restart ntp
#--- Remove from start up
systemctl disable ntp 2>/dev/null
#--- Only used for stats at the end
start_time=$(date +%s)


##### Update OS from network repositories
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) ${GREEN}Updating OS${RESET} from network repositories"
echo -e " ${YELLOW}[i]${RESET}  ...this ${BOLD}may take a while${RESET} depending on your Internet connection & Kali version/age"
for FILE in clean autoremove; do apt -y -qq "${FILE}"; done         # Clean up      clean remove autoremove autoclean
export DEBIAN_FRONTEND=noninteractive
apt -qq update && APT_LISTCHANGES_FRONTEND=none apt -o Dpkg::Options::="--force-confnew" -y dist-upgrade --fix-missing 2>&1 \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
#--- Cleaning up temp stuff
for FILE in clean autoremove; do apt -y -qq "${FILE}"; done         # Clean up - clean remove autoremove autoclean
#--- Check kernel stuff
_TMP=$(dpkg -l | grep linux-image- | grep -vc meta)
if [[ "${_TMP}" -gt 1 ]]; then
  echo -e "\n ${YELLOW}[i]${RESET} Detected ${YELLOW}multiple kernels${RESET}"
  TMP=$(dpkg -l | grep linux-image | grep -v meta | sort -t '.' -k 2 -g | tail -n 1 | grep "$(uname -r)")
  if [[ -z "${TMP}" ]]; then
    echo -e '\n '${RED}'[!]'${RESET}' You are '${RED}'not using the latest kernel'${RESET} 1>&2
    echo -e " ${YELLOW}[i]${RESET} You have it ${YELLOW}downloaded${RESET} & installed, just ${YELLOW}not USING IT${RESET}"
    #echo -e "\n ${YELLOW}[i]${RESET} You ${YELLOW}NEED to REBOOT${RESET}, before re-running this script"
    #exit 1
    sleep 30s
  else
    echo -e " ${YELLOW}[i]${RESET} ${YELLOW}You're using the latest kernel${RESET} (Good to continue)"
  fi
fi


##### Install kernel headers
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}kernel headers${RESET}"
apt -y -qq install make gcc "linux-headers-$(uname -r)" \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
if [[ $? -ne 0 ]]; then
  echo -e ' '${RED}'[!]'${RESET}" There was an ${RED}issue installing kernel headers${RESET}" 1>&2
  echo -e " ${YELLOW}[i]${RESET} Are you ${YELLOW}USING${RESET} the ${YELLOW}latest kernel${RESET}?"
  echo -e " ${YELLOW}[i]${RESET} ${YELLOW}Reboot${RESET} your machine"
  #exit 1
  sleep 30s
fi


##### Install "kali full" meta packages (default tool selection)
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}kali-linux-full${RESET} meta-package"
echo -e " ${YELLOW}[i]${RESET}  ...this ${BOLD}may take a while${RESET} depending on your Kali version (e.g. ARM, light, mini or docker...)"
#--- Kali's default tools ~ https://www.kali.org/news/kali-linux-metapackages/
apt -y -qq install kali-linux-full \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2


##### Set audio level
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Setting ${GREEN}audio${RESET} levels"
systemctl --user enable pulseaudio
systemctl --user start pulseaudio
pactl set-sink-mute 0 0
pactl set-sink-volume 0 25%


##### Configure GRUB
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Configuring ${GREEN}GRUB${RESET} ~ boot manager"
grubTimeout=5
(dmidecode | grep -iq virtual) && grubTimeout=1   # Much less if we are in a VM
file=/etc/default/grub; [ -e "${file}" ] && cp -n $file{,.bkup}
sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT='${grubTimeout}'/' "${file}"                           # Time out (lower if in a virtual machine, else possible dual booting)
sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="vga=0x0318"/' "${file}"   # TTY resolution
update-grub


if [[ $(dmidecode | grep -i virtual) ]]; then
  ###### Configure login screen
  (( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Configuring ${GREEN}login screen${RESET}"
  #--- Enable auto (gui) login
  file=/etc/gdm3/daemon.conf; [ -e "${file}" ] && cp -n $file{,.bkup}
  sed -i 's/^.*AutomaticLoginEnable = .*/AutomaticLoginEnable = true/' "${file}"
  sed -i 's/^.*AutomaticLogin = .*/AutomaticLogin = root/' "${file}"
fi


if [[ $(which gnome-shell) ]]; then
  ##### Configure GNOME 3
  (( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Configuring ${GREEN}GNOME 3${RESET} ~ desktop environment"
  export DISPLAY=:0.0
  #-- Gnome Extension - Dash Dock (the toolbar with all the icons)
  gsettings set org.gnome.shell.extensions.dash-to-dock extend-height true      # Set dock to use the full height
  gsettings set org.gnome.shell.extensions.dash-to-dock dock-position 'RIGHT'   # Set dock to the right
  gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed true         # Set dock to be always visible
  gsettings set org.gnome.shell favorite-apps \
    "['gnome-terminal.desktop', 'org.gnome.Nautilus.desktop', 'kali-wireshark.desktop', 'firefox-esr.desktop', 'kali-burpsuite.desktop', 'kali-msfconsole.desktop', 'gedit.desktop']"
  #-- Gnome Extension - Alternate-tab (So it doesn't group the same windows up)
  GNOME_EXTENSIONS=$(gsettings get org.gnome.shell enabled-extensions | sed 's_^.\(.*\).$_\1_')
  echo "${GNOME_EXTENSIONS}" | grep -q "alternate-tab@gnome-shell-extensions.gcampax.github.com" \
    || gsettings set org.gnome.shell enabled-extensions "[${GNOME_EXTENSIONS}, 'alternate-tab@gnome-shell-extensions.gcampax.github.com']"
  #-- Gnome Extension - Drive Menu (Show USB devices in tray)
  GNOME_EXTENSIONS=$(gsettings get org.gnome.shell enabled-extensions | sed 's_^.\(.*\).$_\1_')
  echo "${GNOME_EXTENSIONS}" | grep -q "drive-menu@gnome-shell-extensions.gcampax.github.com" \
    || gsettings set org.gnome.shell enabled-extensions "[${GNOME_EXTENSIONS}, 'drive-menu@gnome-shell-extensions.gcampax.github.com']"
  #--- Workspaces
  gsettings set org.gnome.shell.overrides dynamic-workspaces false                         # Static
  gsettings set org.gnome.desktop.wm.preferences num-workspaces 3                          # Increase workspaces count to 3
  #--- Top bar
  gsettings set org.gnome.desktop.interface clock-show-date true                           # Show date next to time in the top tool bar
  #--- Keyboard short-cuts
  (dmidecode | grep -iq virtual) && gsettings set org.gnome.mutter overlay-key "Super_R"   # Change 'super' key to right side (rather than left key), if in a VM
  #--- Hide desktop icon
  dconf write /org/gnome/nautilus/desktop/computer-icon-visible false
else
  echo -e "\n\n ${YELLOW}[i]${RESET} ${YELLOW}Skipping GNOME${RESET}..." 1>&2
fi


##### Install XFCE4
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}XFCE4${RESET}${RESET} ~ desktop environment"
export DISPLAY=:0.0
apt -y -qq install curl \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
apt -y -qq install xfce4 xfce4-mount-plugin xfce4-notifyd xfce4-places-plugin xfce4-power-manager \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
(dmidecode | grep -iq virtual) \
  || (apt -y -qq install xfce4-battery-plugin \
    || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2)
#--- Configuring XFCE
mkdir -p ~/.config/xfce4/panel/launcher-{2,4,5,6,7,8,9}/
mkdir -p ~/.config/xfce4/xfconf/xfce-perchannel-xml/
#--- Configuring XFCE (Keyboard shortcuts)
cat <<EOF > ~/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml \
  || echo -e ' '${RED}'[!] Issue with writing file'${RESET} 1>&2
<?xml version="1.0" encoding="UTF-8"?>

<channel name="xfce4-keyboard-shortcuts" version="1.0">
  <property name="commands" type="empty">
    <property name="custom" type="empty">
      <property name="XF86Display" type="string" value="xfce4-display-settings --minimal"/>
      <property name="&lt;Alt&gt;F2" type="string" value="xfrun4"/>
      <property name="&lt;Primary&gt;space" type="string" value="xfce4-appfinder"/>
      <property name="&lt;Primary&gt;&lt;Alt&gt;t" type="string" value="/usr/bin/exo-open --launch TerminalEmulator"/>
      <property name="&lt;Primary&gt;&lt;Alt&gt;Delete" type="string" value="xflock4"/>
      <property name="&lt;Primary&gt;Escape" type="string" value="xfdesktop --menu"/>
      <property name="&lt;Super&gt;p" type="string" value="xfce4-display-settings --minimal"/>
      <property name="override" type="bool" value="true"/>
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
      <property name="&lt;Super&gt;Left" type="string" value="tile_left_key"/>
      <property name="&lt;Super&gt;Right" type="string" value="tile_right_key"/>
      <property name="&lt;Super&gt;Up" type="string" value="maximize_window_key"/>
    </property>
  </property>
  <property name="providers" type="array">
    <value type="string" value="xfwm4"/>
    <value type="string" value="commands"/>
  </property>
</channel>
EOF
#--- Configuring XFCE (Power Options)
cat <<EOF > ~/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-power-manager.xml \
  || echo -e ' '${RED}'[!] Issue with writing file'${RESET} 1>&2
<?xml version="1.0" encoding="UTF-8"?>

<channel name="xfce4-power-manager" version="1.0">
  <property name="xfce4-power-manager" type="empty">
    <property name="power-button-action" type="empty"/>
    <property name="dpms-enabled" type="bool" value="true"/>
    <property name="blank-on-ac" type="int" value="0"/>
    <property name="dpms-on-ac-sleep" type="uint" value="0"/>
    <property name="dpms-on-ac-off" type="uint" value="0"/>
  </property>
</channel>
EOF
#--- Desktop files
ln -sf /usr/share/applications/exo-terminal-emulator.desktop ~/.config/xfce4/panel/launcher-2/exo-terminal-emulator.desktop
ln -sf /usr/share/applications/kali-wireshark.desktop        ~/.config/xfce4/panel/launcher-4/kali-wireshark.desktop
ln -sf /usr/share/applications/firefox-esr.desktop           ~/.config/xfce4/panel/launcher-5/firefox-esr.desktop
ln -sf /usr/share/applications/kali-burpsuite.desktop        ~/.config/xfce4/panel/launcher-6/kali-burpsuite.desktop
ln -sf /usr/share/applications/kali-msfconsole.desktop       ~/.config/xfce4/panel/launcher-7/kali-msfconsole.desktop
ln -sf /usr/share/applications/org.gnome.gedit.desktop       ~/.config/xfce4/panel/launcher-8/textedit.desktop
ln -sf /usr/share/applications/xfce4-appfinder.desktop       ~/.config/xfce4/panel/launcher-9/xfce4-appfinder.desktop
#--- XFCE settings
_TMP=""
[ "${burpFree}" != "false" ] \
  && _TMP="-t int -s 6"
xfconf-query -n -a -c xfce4-panel -p /panels -t int -s 0
xfconf-query --create --channel xfce4-panel --property /panels/panel-0/plugin-ids \
  -t int -s 1   -t int -s 2   -t int -s 3   -t int -s 4   -t int -s 5  ${_TMP}        -t int -s 7   -t int -s 8  -t int -s 9 \
  -t int -s 10  -t int -s 11  -t int -s 13  -t int -s 15  -t int -s 16  -t int -s 17  -t int -s 19  -t int -s 20
xfconf-query -n -c xfce4-panel -p /panels/panel-0/length -t int -s 100
xfconf-query -n -c xfce4-panel -p /panels/panel-0/size -t int -s 30
xfconf-query -n -c xfce4-panel -p /panels/panel-0/position -t string -s "p=6;x=0;y=0"
xfconf-query -n -c xfce4-panel -p /panels/panel-0/position-locked -t bool -s true
xfconf-query -n -c xfce4-panel -p /plugins/plugin-1 -t string -s applicationsmenu     # application menu
xfconf-query -n -c xfce4-panel -p /plugins/plugin-2 -t string -s launcher             # terminal   ID: exo-terminal-emulator
xfconf-query -n -c xfce4-panel -p /plugins/plugin-3 -t string -s places               # places
xfconf-query -n -c xfce4-panel -p /plugins/plugin-4 -t string -s launcher             # wireshark  ID: kali-wireshark
xfconf-query -n -c xfce4-panel -p /plugins/plugin-5 -t string -s launcher             # firefox    ID: firefox-esr
[ "${burpFree}" != "false" ] \
  && xfconf-query -n -c xfce4-panel -p /plugins/plugin-6 -t string -s launcher        # burpsuite  ID: kali-burpsuite
xfconf-query -n -c xfce4-panel -p /plugins/plugin-7 -t string -s launcher             # msf        ID: kali-msfconsole
xfconf-query -n -c xfce4-panel -p /plugins/plugin-8 -t string -s launcher             # gedit      ID: org.gnome.gedit.desktop
xfconf-query -n -c xfce4-panel -p /plugins/plugin-9 -t string -s launcher             # search     ID: xfce4-appfinder
xfconf-query -n -c xfce4-panel -p /plugins/plugin-10 -t string -s tasklist
xfconf-query -n -c xfce4-panel -p /plugins/plugin-11 -t string -s separator
xfconf-query -n -c xfce4-panel -p /plugins/plugin-13 -t string -s mixer   # audio
xfconf-query -n -c xfce4-panel -p /plugins/plugin-15 -t string -s systray
xfconf-query -n -c xfce4-panel -p /plugins/plugin-16 -t string -s actions
xfconf-query -n -c xfce4-panel -p /plugins/plugin-17 -t string -s clock
xfconf-query -n -c xfce4-panel -p /plugins/plugin-19 -t string -s pager
xfconf-query -n -c xfce4-panel -p /plugins/plugin-20 -t string -s showdesktop
#--- application menu
xfconf-query -n -c xfce4-panel -p /plugins/plugin-1/show-tooltips -t bool -s true
xfconf-query -n -c xfce4-panel -p /plugins/plugin-1/show-button-title -t bool -s false
#--- terminal
xfconf-query -n -c xfce4-panel -p /plugins/plugin-2/items -t string -s "exo-terminal-emulator.desktop" -a
#--- places
xfconf-query -n -c xfce4-panel -p /plugins/plugin-3/mount-open-volumes -t bool -s true
#--- wireshark
xfconf-query -n -c xfce4-panel -p /plugins/plugin-4/items -t string -s "kali-wireshark.desktop" -a
#--- firefox
xfconf-query -n -c xfce4-panel -p /plugins/plugin-5/items -t string -s "firefox-esr.desktop" -a
#--- burp
[ "${burpFree}" != "false" ] \
  && xfconf-query -n -c xfce4-panel -p /plugins/plugin-6/items -t string -s "kali-burpsuite.desktop" -a
#--- metasploit
xfconf-query -n -c xfce4-panel -p /plugins/plugin-7/items -t string -s "kali-msfconsole.desktop" -a
#--- gedit
xfconf-query -n -c xfce4-panel -p /plugins/plugin-8/items -t string -s "textedit.desktop" -a
#--- search
xfconf-query -n -c xfce4-panel -p /plugins/plugin-9/items -t string -s "xfce4-appfinder.desktop" -a
#--- tasklist (& separator - required for padding)
xfconf-query -n -c xfce4-panel -p /plugins/plugin-10/show-labels -t bool -s true
xfconf-query -n -c xfce4-panel -p /plugins/plugin-10/show-handle -t bool -s false
xfconf-query -n -c xfce4-panel -p /plugins/plugin-11/style -t int -s 0
xfconf-query -n -c xfce4-panel -p /plugins/plugin-11/expand -t bool -s true
#--- systray
xfconf-query -n -c xfce4-panel -p /plugins/plugin-15/show-frame -t bool -s false
#--- actions
xfconf-query -n -c xfce4-panel -p /plugins/plugin-16/appearance -t int -s 1
xfconf-query -n -c xfce4-panel -p /plugins/plugin-16/items \
  -t string -s "+logout-dialog"  -t string -s "-switch-user"  -t string -s "-separator" \
  -t string -s "-logout"  -t string -s "+lock-screen"  -t string -s "+hibernate"  -t string -s "+suspend"  -t string -s "+restart"  -t string -s "+shutdown"  -a
#--- clock
xfconf-query -n -c xfce4-panel -p /plugins/plugin-17/show-frame -t bool -s false
xfconf-query -n -c xfce4-panel -p /plugins/plugin-17/mode -t int -s 2
xfconf-query -n -c xfce4-panel -p /plugins/plugin-17/digital-format -t string -s "%R, %Y-%m-%d"
#--- pager / workspace
xfconf-query -n -c xfce4-panel -p /plugins/plugin-19/miniature-view -t bool -s true
xfconf-query -n -c xfce4-panel -p /plugins/plugin-19/rows -t int -s 1
xfconf-query -n -c xfwm4 -p /general/workspace_count -t int -s 3
#--- Theme options
xfconf-query -n -c xsettings -p /Net/ThemeName -s "Kali-X"
xfconf-query -n -c xsettings -p /Net/IconThemeName -s "Vibrancy-Kali"
xfconf-query -n -c xsettings -p /Gtk/MenuImages -t bool -s true
xfconf-query -n -c xfce4-panel -p /plugins/plugin-1/button-icon -t string -s "kali-menu"
#--- Window management
xfconf-query -n -c xfwm4 -p /general/snap_to_border -t bool -s true
xfconf-query -n -c xfwm4 -p /general/snap_to_windows -t bool -s true
xfconf-query -n -c xfwm4 -p /general/wrap_windows -t bool -s false
xfconf-query -n -c xfwm4 -p /general/wrap_workspaces -t bool -s false
xfconf-query -n -c xfwm4 -p /general/click_to_focus -t bool -s false
xfconf-query -n -c xfwm4 -p /general/click_to_focus -t bool -s true
#--- Hide icons
xfconf-query -n -c xfce4-desktop -p /desktop-icons/file-icons/show-filesystem -t bool -s false
xfconf-query -n -c xfce4-desktop -p /desktop-icons/file-icons/show-home -t bool -s false
xfconf-query -n -c xfce4-desktop -p /desktop-icons/file-icons/show-trash -t bool -s false
xfconf-query -n -c xfce4-desktop -p /desktop-icons/file-icons/show-removable -t bool -s false
#--- Start and exit values
xfconf-query -n -c xfce4-session -p /splash/Engine -t string -s ""
xfconf-query -n -c xfce4-session -p /shutdown/LockScreen -t bool -s true
xfconf-query -n -c xfce4-session -p /general/SaveOnExit -t bool -s false
#--- App Finder
xfconf-query -n -c xfce4-appfinder -p /last/pane-position -t int -s 248
xfconf-query -n -c xfce4-appfinder -p /last/window-height -t int -s 742
xfconf-query -n -c xfce4-appfinder -p /last/window-width -t int -s 648
#--- Enable compositing
xfconf-query -n -c xfwm4 -p /general/use_compositing -t bool -s true
xfconf-query -n -c xfwm4 -p /general/frame_opacity -t int -s 85
#--- Remove "Mail Reader" from menu
file=/usr/share/applications/exo-mail-reader.desktop   #; [ -e "${file}" ] && cp -n $file{,.bkup}
sed -i 's/^NotShowIn=*/NotShowIn=XFCE;/; s/^OnlyShowIn=XFCE;/OnlyShowIn=/' "${file}"
grep -q "NotShowIn=XFCE" "${file}" \
  || echo "NotShowIn=XFCE;" >> "${file}"
#--- XFCE for default applications
mkdir -p ~/.local/share/applications/
file=~/.local/share/applications/mimeapps.list; [ -e "${file}" ] && cp -n $file{,.bkup}
[ ! -e "${file}" ] \
  && echo '[Added Associations]' > "${file}"
([[ -e "${file}" && "$(tail -c 1 ${file})" != "" ]]) && echo >> "${file}"
#--- Firefox
for VALUE in http https; do
  sed -i 's#^x-scheme-handler/'${VALUE}'=.*#x-scheme-handler/'${VALUE}'=exo-web-browser.desktop#' "${file}"
  grep -q '^x-scheme-handler/'${VALUE}'=' "${file}" 2>/dev/null \
    || echo 'x-scheme-handler/'${VALUE}'=exo-web-browser.desktop' >> "${file}"
done
#--- Thunar
for VALUE in file trash; do
  sed -i 's#x-scheme-handler/'${VALUE}'=.*#x-scheme-handler/'${VALUE}'=exo-file-manager.desktop#' "${file}"
  grep -q '^x-scheme-handler/'${VALUE}'=' "${file}" 2>/dev/null \
    || echo 'x-scheme-handler/'${VALUE}'=exo-file-manager.desktop' >> "${file}"
done
file=~/.config/xfce4/helpers.rc; [ -e "${file}" ] && cp -n $file{,.bkup}
([[ -e "${file}" && "$(tail -c 1 ${file})" != "" ]]) && echo >> "${file}"
sed -i 's#^FileManager=.*#FileManager=Thunar#' "${file}" 2>/dev/null
grep -q '^FileManager=Thunar' "${file}" 2>/dev/null \
  || echo 'FileManager=Thunar' >> "${file}"
#--- Disable user folders in home folder
file=/etc/xdg/user-dirs.conf; [ -e "${file}" ] && cp -n $file{,.bkup}
sed -i 's/^XDG_/#XDG_/g; s/^#XDG_DESKTOP/XDG_DESKTOP/g;' "${file}"
sed -i 's/^enable=.*/enable=False/' "${file}"
find ~/ -maxdepth 1 -mindepth 1 -type d \
  \( -name 'Documents' -o -name 'Music' -o -name 'Pictures' -o -name 'Public' -o -name 'Templates' -o -name 'Videos' \) -empty -delete
apt -y -qq install xdg-user-dirs \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
xdg-user-dirs-update
#--- Remove any old sessions
rm -f ~/.cache/sessions/*
#--- Set XFCE as default desktop manager
update-alternatives --set x-session-manager /usr/bin/xfce4-session   #update-alternatives --config x-window-manager   #echo "xfce4-session" > ~/.xsession


##### Cosmetics (themes & wallpapers)
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) ${GREEN}Cosmetics${RESET}${RESET} ~ Giving it a personal touch"
export DISPLAY=:0.0
#--- axiom / axiomd (May 18 2010) XFCE4 theme ~ http://xfce-look.org/content/show.php/axiom+xfwm?content=90145
mkdir -p ~/.themes/
timeout 300 curl --progress -k -L -f "https://dl.opendesktop.org/api/files/download/id/1461767736/90145-axiom.tar.gz" > /tmp/axiom.tar.gz \
  || echo -e ' '${RED}'[!]'${RESET}" Issue downloading axiom.tar.gz" 1>&2    #***!!! hardcoded path!
tar -zxf /tmp/axiom.tar.gz -C ~/.themes/
xfconf-query -n -c xsettings -p /Net/ThemeName -s "axiomd"
xfconf-query -n -c xsettings -p /Net/IconThemeName -s "Vibrancy-Kali-Dark"
#--- Get new desktop wallpaper      (All are #***!!! hardcoded paths!)
mkdir -p /usr/share/wallpapers/
echo -n '[1/10]'; timeout 300 curl --progress -k -L -f "https://www.kali.org/images/wallpapers-01/kali-wp-june-2014_1920x1080_A.png" > /usr/share/wallpapers/kali_blue_3d_a.png \
  || echo -e ' '${RED}'[!]'${RESET}" Issue downloading kali_blue_3d_a.png" 1>&2
echo -n '[2/10]'; timeout 300 curl --progress -k -L -f "https://www.kali.org/images/wallpapers-01/kali-wp-june-2014_1920x1080_B.png" > /usr/share/wallpapers/kali_blue_3d_b.png \
  || echo -e ' '${RED}'[!]'${RESET}" Issue downloading kali_blue_3d_b.png" 1>&2
echo -n '[3/10]'; timeout 300 curl --progress -k -L -f "https://www.kali.org/images/wallpapers-01/kali-wp-june-2014_1920x1080_G.png" > /usr/share/wallpapers/kali_black_honeycomb.png \
  || echo -e ' '${RED}'[!]'${RESET}" Issue downloading kali_black_honeycomb.png" 1>&2
echo -n '[4/10]'; timeout 300 curl --progress -k -L -f "https://lh5.googleusercontent.com/-CW1-qRVBiqc/U7ARd2T9LCI/AAAAAAAAAGw/oantfR6owSg/w1920-h1080/vzex.png" > /usr/share/wallpapers/kali_blue_splat.png \
  || echo -e ' '${RED}'[!]'${RESET}" Issue downloading kali_blue_splat.png" 1>&2
echo -n '[5/10]'; timeout 300 curl --progress -k -L -f "http://wallpaperstock.net/kali-linux_wallpapers_39530_1920x1080.jpg" > /usr/share/wallpapers/kali-linux_wallpapers_39530.png \
  || echo -e ' '${RED}'[!]'${RESET}" Issue downloading kali-linux_wallpapers_39530.png" 1>&2
echo -n '[6/10]'; timeout 300 curl --progress -k -L -f "http://em3rgency.com/wp-content/uploads/2012/12/Kali-Linux-faded-no-Dragon-small-text.png" > /usr/share/wallpapers/kali_black_clean.png \
  || echo -e ' '${RED}'[!]'${RESET}" Issue downloading kali_black_clean.png" 1>&2
#echo -n '[7/10]'; timeout 300 curl --progress -k -L -f "http://www.hdwallpapers.im/download/kali_linux-wallpaper.jpg" > /usr/share/wallpapers/kali_black_stripes.jpg \
#  || echo -e ' '${RED}'[!]'${RESET}" Issue downloading kali_black_stripes.jpg" 1>&2
echo -n '[8/10]'; timeout 300 curl --progress -k -L -f "http://fc01.deviantart.net/fs71/f/2011/118/e/3/bt___edb_wallpaper_by_xxdigipxx-d3f4nxv.png" > /usr/share/wallpapers/kali_bt_edb.jpg \
  || echo -e ' '${RED}'[!]'${RESET}" Issue downloading kali_bt_edb.jpg" 1>&2
echo -n '[9/10]'; timeout 300 curl --progress -k -L -f "http://pre07.deviantart.net/58d1/th/pre/i/2015/223/4/8/kali_2_0_alternate_wallpaper_by_xxdigipxx-d95800s.png" > /usr/share/wallpapers/kali_2_0_alternate_wallpaper.png \
  || echo -e ' '${RED}'[!]'${RESET}" Issue downloading kali_2_0_alternate_wallpaper.png" 1>&2
echo -n '[10/10]'; timeout 300 curl --progress -k -L -f "http://pre01.deviantart.net/4210/th/pre/i/2015/195/3/d/kali_2_0__personal__wp_by_xxdigipxx-d91c8dq.png" > /usr/share/wallpapers/kali_2_0_personal.png \
  || echo -e ' '${RED}'[!]'${RESET}" Issue downloading kali_2_0_personal.png" 1>&2
_TMP="$(find /usr/share/wallpapers/ -maxdepth 1 -type f -name 'kali_*' | xargs -n1 file | grep -i 'HTML\|empty' | cut -d ':' -f1)"
for FILE in $(echo ${_TMP}); do rm -f "${FILE}"; done
#--- Kali 1 (Wallpaper)
[ -e "/usr/share/wallpapers/kali_default-1440x900.jpg" ] \
  && ln -sf /usr/share/wallpapers/kali/contents/images/1440x900.png /usr/share/wallpapers/kali_default-1440x900.jpg
#--- Kali 2 (Login)
[ -e "/usr/share/gnome-shell/theme/KaliLogin.png" ] \
  && cp -f /usr/share/gnome-shell/theme/KaliLogin.png /usr/share/wallpapers/KaliLogin2.0-login.jpg
#--- Kali 2 & Rolling (Wallpaper)
[ -e "/usr/share/images/desktop-base/kali-wallpaper_1920x1080.png" ] \
  && ln -sf /usr/share/images/desktop-base/kali-wallpaper_1920x1080.png /usr/share/wallpapers/kali_default2.0-1920x1080.jpg
#--- New wallpaper & add to startup (so its random each login)
mkdir -p /usr/local/bin/
file=/usr/local/bin/rand-wallpaper; [ -e "${file}" ] && cp -n $file{,.bkup}
cat <<EOF > "${file}" \
  || echo -e ' '${RED}'[!] Issue with writing file'${RESET} 1>&2
#!/bin/bash

wallpaper="\$(shuf -n1 -e \$(find /usr/share/wallpapers/ -maxdepth 1 -name 'kali_*'))"

## XFCE - Desktop wallpaper
/usr/bin/xfconf-query -n -c xfce4-desktop -p /backdrop/screen0/monitor0/image-show -t bool -s true
/usr/bin/xfconf-query -n -c xfce4-desktop -p /backdrop/screen0/monitor0/image-path -t string -s "\${wallpaper}"
/usr/bin/xfconf-query -n -c xfce4-desktop -p /backdrop/screen0/monitor0/workspace0/last-image -t string -s "\${wallpaper}"

## GNOME - Desktop wallpaper
#[[ $(which gnome-shell) ]] \
#  && dconf write /org/gnome/desktop/background/picture-uri "'file://\${wallpaper}'"

## Change lock wallpaper (before swipe) - kali 2 & rolling
/usr/bin/dconf write /org/gnome/desktop/screensaver/picture-uri "'file://\${wallpaper}'"

## Change login wallpaper (after swipe) - kali 2
#cp -f "\${wallpaper}" /usr/share/gnome-shell/theme/KaliLogin.png

/usr/bin/xfdesktop --reload 2>/dev/null &
EOF
chmod -f 0500 "${file}"
#--- Run now
bash "${file}"
#--- Add to startup
mkdir -p ~/.config/autostart/
file=~/.config/autostart/wallpaper.desktop; [ -e "${file}" ] && cp -n $file{,.bkup}
cat <<EOF > "${file}" \
  || echo -e ' '${RED}'[!] Issue with writing file'${RESET} 1>&2
[Desktop Entry]
Type=Application
Exec=/usr/local/bin/rand-wallpaper
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=wallpaper
EOF


##### Configure file   Note: need to restart xserver for effect
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Configuring ${GREEN}file${RESET} (Nautilus/Thunar) ~ GUI file system navigation"
#--- Settings
mkdir -p ~/.config/gtk-2.0/
file=~/.config/gtk-2.0/gtkfilechooser.ini; [ -e "${file}" ] && cp -n $file{,.bkup}
([[ -e "${file}" && "$(tail -c 1 ${file})" != "" ]]) && echo >> "${file}"
sed -i 's/^.*ShowHidden.*/ShowHidden=true/' "${file}" 2>/dev/null \
  || cat <<EOF > "${file}"
[Filechooser Settings]
LocationMode=path-bar
ShowHidden=true
ExpandFolders=false
ShowSizeColumn=true
GeometryX=66
GeometryY=39
GeometryWidth=780
GeometryHeight=618
SortColumn=name
SortOrder=ascending
EOF
dconf write /org/gnome/nautilus/preferences/show-hidden-files true
#--- Bookmarks
file=/root/.gtk-bookmarks; [ -e "${file}" ] && cp -n $file{,.bkup}
([[ -e "${file}" && "$(tail -c 1 ${file})" != "" ]]) && echo >> "${file}"
grep -q '^file:///root/Downloads ' "${file}" 2>/dev/null \
  || echo 'file:///root/Downloads Downloads' >> "${file}"
(dmidecode | grep -iq vmware) \
  && (mkdir -p /mnt/hgfs/ 2>/dev/null; grep -q '^file:///mnt/hgfs ' "${file}" 2>/dev/null \
    || echo 'file:///mnt/hgfs VMShare' >> "${file}")
grep -q '^file:///tmp ' "${file}" 2>/dev/null \
  || echo 'file:///tmp /TMP' >> "${file}"
grep -q '^file:///usr/share ' "${file}" 2>/dev/null \
  || echo 'file:///usr/share Kali Tools' >> "${file}"
grep -q '^file:///opt ' "${file}" 2>/dev/null \
  || echo 'file:///opt /opt' >> "${file}"
grep -q '^file:///usr/local/src ' "${file}" 2>/dev/null \
  || echo 'file:///usr/local/src SRC' >> "${file}"
grep -q '^file:///var/ftp ' "${file}" 2>/dev/null \
  || echo 'file:///var/ftp FTP' >> "${file}"
grep -q '^file:///var/samba ' "${file}" 2>/dev/null \
  || echo 'file:///var/samba Samba' >> "${file}"
grep -q '^file:///var/tftp ' "${file}" 2>/dev/null \
  || echo 'file:///var/tftp TFTP' >> "${file}"
grep -q '^file:///var/www/html ' "${file}" 2>/dev/null \
  || echo 'file:///var/www/html WWW' >> "${file}"
#--- Configure file browser - Thunar (need to re-login for effect)
mkdir -p ~/.config/Thunar/
file=~/.config/Thunar/thunarrc; [ -e "${file}" ] && cp -n $file{,.bkup}
([[ -e "${file}" && "$(tail -c 1 ${file})" != "" ]]) && echo >> "${file}"
sed -i 's/LastShowHidden=.*/LastShowHidden=TRUE/' "${file}" 2>/dev/null \
  || echo -e "[Configuration]\nLastShowHidden=TRUE" > "${file}"


##### Configure GNOME terminal   Note: need to restart xserver for effect
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Configuring GNOME ${GREEN}terminal${RESET} ~ CLI interface"
gconftool-2 -t bool -s /apps/gnome-terminal/profiles/Default/scrollback_unlimited true
gconftool-2 -t string -s /apps/gnome-terminal/profiles/Default/background_type transparent
gconftool-2 -t string -s /apps/gnome-terminal/profiles/Default/background_darkness 0.85611499999999996


##### Configure bash - all users
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Configuring ${GREEN}bash${RESET} ~ CLI shell"
file=/etc/bash.bashrc; [ -e "${file}" ] && cp -n $file{,.bkup}   #~/.bashrc
grep -q "cdspell" "${file}" \
  || echo "shopt -sq cdspell" >> "${file}"             # Spell check 'cd' commands
grep -q "autocd" "${file}" \
 || echo "shopt -s autocd" >> "${file}"                # So you don't have to 'cd' before a folder
#grep -q "CDPATH" "${file}" \
# || echo "CDPATH=/etc:/usr/share/:/opt" >> "${file}"  # Always CD into these folders
grep -q "checkwinsize" "${file}" \
 || echo "shopt -sq checkwinsize" >> "${file}"         # Wrap lines correctly after resizing
grep -q "nocaseglob" "${file}" \
 || echo "shopt -sq nocaseglob" >> "${file}"           # Case insensitive pathname expansion
grep -q "HISTSIZE" "${file}" \
 || echo "HISTSIZE=10000" >> "${file}"                 # Bash history (memory scroll back)
grep -q "HISTFILESIZE" "${file}" \
 || echo "HISTFILESIZE=10000" >> "${file}"             # Bash history (file .bash_history)
#--- Apply new configs
source "${file}" || source ~/.zshrc


##### Install bash colour - all users
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}bash colour${RESET} ~ colours shell output"
file=/etc/bash.bashrc; [ -e "${file}" ] && cp -n $file{,.bkup}   #~/.bashrc
([[ -e "${file}" && "$(tail -c 1 ${file})" != "" ]]) && echo >> "${file}"
sed -i 's/.*force_color_prompt=.*/force_color_prompt=yes/' "${file}"
grep -q '^force_color_prompt' "${file}" 2>/dev/null \
  || echo 'force_color_prompt=yes' >> "${file}"
sed -i 's#PS1='"'"'.*'"'"'#PS1='"'"'${debian_chroot:+($debian_chroot)}\\[\\033\[01;31m\\]\\u@\\h\\\[\\033\[00m\\]:\\[\\033\[01;34m\\]\\w\\[\\033\[00m\\]\\$ '"'"'#' "${file}"
grep -q "^export LS_OPTIONS='--color=auto'" "${file}" 2>/dev/null \
  || echo "export LS_OPTIONS='--color=auto'" >> "${file}"
grep -q '^eval "$(dircolors)"' "${file}" 2>/dev/null \
  || echo 'eval "$(dircolors)"' >> "${file}"
grep -q "^alias ls='ls $LS_OPTIONS'" "${file}" 2>/dev/null \
  || echo "alias ls='ls $LS_OPTIONS'" >> "${file}"
grep -q "^alias ll='ls $LS_OPTIONS -l'" "${file}" 2>/dev/null \
  || echo "alias ll='ls $LS_OPTIONS -l'" >> "${file}"
grep -q "^alias l='ls $LS_OPTIONS -lA'" "${file}" 2>/dev/null \
  || echo "alias l='ls $LS_OPTIONS -lA'" >> "${file}"
#--- All other users that are made afterwards
file=/etc/skel/.bashrc   #; [ -e "${file}" ] && cp -n $file{,.bkup}
sed -i 's/.*force_color_prompt=.*/force_color_prompt=yes/' "${file}"
#--- Apply new configs
source "${file}" || source ~/.zshrc


##### Install grc
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}grc${RESET} ~ colours shell output"
apt -y -qq install grc \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
#--- Setup aliases
file=~/.bash_aliases; [ -e "${file}" ] && cp -n $file{,.bkup}   #/etc/bash.bash_aliases
([[ -e "${file}" && "$(tail -c 1 ${file})" != "" ]]) && echo >> "${file}"
grep -q '^## grc diff alias' "${file}" 2>/dev/null \
  || echo -e "## grc diff alias\nalias diff='$(which grc) $(which diff)'\n" >> "${file}"
grep -q '^## grc dig alias' "${file}" 2>/dev/null \
  || echo -e "## grc dig alias\nalias dig='$(which grc) $(which dig)'\n" >> "${file}"
grep -q '^## grc gcc alias' "${file}" 2>/dev/null \
  || echo -e "## grc gcc alias\nalias gcc='$(which grc) $(which gcc)'\n" >> "${file}"
grep -q '^## grc ifconfig alias' "${file}" 2>/dev/null \
  || echo -e "## grc ifconfig alias\nalias ifconfig='$(which grc) $(which ifconfig)'\n" >> "${file}"
grep -q '^## grc mount alias' "${file}" 2>/dev/null \
  || echo -e "## grc mount alias\nalias mount='$(which grc) $(which mount)'\n" >> "${file}"
grep -q '^## grc netstat alias' "${file}" 2>/dev/null \
  || echo -e "## grc netstat alias\nalias netstat='$(which grc) $(which netstat)'\n" >> "${file}"
grep -q '^## grc ping alias' "${file}" 2>/dev/null \
  || echo -e "## grc ping alias\nalias ping='$(which grc) $(which ping)'\n" >> "${file}"
grep -q '^## grc ps alias' "${file}" 2>/dev/null \
  || echo -e "## grc ps alias\nalias ps='$(which grc) $(which ps)'\n" >> "${file}"
grep -q '^## grc tail alias' "${file}" 2>/dev/null \
  || echo -e "## grc tail alias\nalias tail='$(which grc) $(which tail)'\n" >> "${file}"
grep -q '^## grc traceroute alias' "${file}" 2>/dev/null \
  || echo -e "## grc traceroute alias\nalias traceroute='$(which grc) $(which traceroute)'\n" >> "${file}"
grep -q '^## grc wdiff alias' "${file}" 2>/dev/null \
  || echo -e "## grc wdiff alias\nalias wdiff='$(which grc) $(which wdiff)'\n" >> "${file}"
#configure  #esperanto  #ldap  #e  #cvs  #log  #mtr  #ls  #irclog  #mount2  #mount
#--- Apply new aliases
source "${file}" || source ~/.zshrc


##### Install bash completion - all users
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}bash completion${RESET} ~ tab complete CLI commands"
apt -y -qq install bash-completion \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
file=/etc/bash.bashrc; [ -e "${file}" ] && cp -n $file{,.bkup}   #~/.bashrc
sed -i '/# enable bash completion in/,+7{/enable bash completion/!s/^#//}' "${file}"
#--- Apply new configs
source "${file}" || source ~/.zshrc


##### Configure aliases - root user
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Configuring ${GREEN}aliases${RESET} ~ CLI shortcuts"
#--- Enable defaults - root user
for FILE in /etc/bash.bashrc ~/.bashrc ~/.bash_aliases; do    #/etc/profile /etc/bashrc /etc/bash_aliases /etc/bash.bash_aliases
  [[ ! -f "${FILE}" ]] \
    && continue
  cp -n $FILE{,.bkup}
  sed -i 's/#alias/alias/g' "${FILE}"
done
#--- General system ones
file=~/.bash_aliases; [ -e "${file}" ] && cp -n $file{,.bkup}   #/etc/bash.bash_aliases
([[ -e "${file}" && "$(tail -c 1 ${file})" != "" ]]) && echo >> "${file}"
grep -q '^## grep aliases' "${file}" 2>/dev/null \
  || echo -e '## grep aliases\nalias grep="grep --color=always"\nalias ngrep="grep -n"\n' >> "${file}"
grep -q '^alias egrep=' "${file}" 2>/dev/null \
  || echo -e 'alias egrep="egrep --color=auto"\n' >> "${file}"
grep -q '^alias fgrep=' "${file}" 2>/dev/null \
  || echo -e 'alias fgrep="fgrep --color=auto"\n' >> "${file}"
#--- Add in ours (OS programs)
grep -q '^alias tmux' "${file}" 2>/dev/null \
  || echo -e '## tmux\nalias tmux="tmux attach || tmux new"\n' >> "${file}"    #alias tmux="tmux attach -t $HOST || tmux new -s $HOST"
grep -q '^alias axel' "${file}" 2>/dev/null \
  || echo -e '## axel\nalias axel="axel -a"\n' >> "${file}"
grep -q '^alias screen' "${file}" 2>/dev/null \
  || echo -e '## screen\nalias screen="screen -xRR"\n' >> "${file}"
#--- Add in ours (shortcuts)
grep -q '^## Checksums' "${file}" 2>/dev/null \
  || echo -e '## Checksums\nalias sha1="openssl sha1"\nalias md5="openssl md5"\n' >> "${file}"
grep -q '^## Force create folders' "${file}" 2>/dev/null \
  || echo -e '## Force create folders\nalias mkdir="/bin/mkdir -pv"\n' >> "${file}"
#grep -q '^## Mount' "${file}" 2>/dev/null \
#  || echo -e '## Mount\nalias mount="mount | column -t"\n' >> "${file}"
grep -q '^## List open ports' "${file}" 2>/dev/null \
  || echo -e '## List open ports\nalias ports="netstat -tulanp"\n' >> "${file}"
grep -q '^## Get header' "${file}" 2>/dev/null \
  || echo -e '## Get header\nalias header="curl -I"\n' >> "${file}"
grep -q '^## Get external IP address' "${file}" 2>/dev/null \
  || echo -e '## Get external IP address\nalias ipx="curl -s http://ipinfo.io/ip"\n' >> "${file}"
grep -q '^## DNS - External IP #1' "${file}" 2>/dev/null \
  || echo -e '## DNS - External IP #1\nalias dns1="dig +short @resolver1.opendns.com myip.opendns.com"\n' >> "${file}"
grep -q '^## DNS - External IP #2' "${file}" 2>/dev/null \
  || echo -e '## DNS - External IP #2\nalias dns2="dig +short @208.67.222.222 myip.opendns.com"\n' >> "${file}"
grep -q '^## DNS - Check' "${file}" 2>/dev/null \
  || echo -e '### DNS - Check ("#.abc" is Okay)\nalias dns3="dig +short @208.67.220.220 which.opendns.com txt"\n' >> "${file}"
grep -q '^## Directory navigation aliases' "${file}" 2>/dev/null \
  || echo -e '## Directory navigation aliases\nalias ..="cd .."\nalias ...="cd ../.."\nalias ....="cd ../../.."\nalias .....="cd ../../../.."\n' >> "${file}"
grep -q '^## Extract file' "${file}" 2>/dev/null \
  || cat <<EOF >> "${file}" \
    || echo -e ' '${RED}'[!] Issue with writing file'${RESET} 1>&2

## Extract file, example. "ex package.tar.bz2"
ex() {
  if [[ -f \$1 ]]; then
    case \$1 in
      *.tar.bz2) tar xjf \$1 ;;
      *.tar.gz)  tar xzf \$1 ;;
      *.bz2)     bunzip2 \$1 ;;
      *.rar)     rar x \$1 ;;
      *.gz)      gunzip \$1  ;;
      *.tar)     tar xf \$1  ;;
      *.tbz2)    tar xjf \$1 ;;
      *.tgz)     tar xzf \$1 ;;
      *.zip)     unzip \$1 ;;
      *.Z)       uncompress \$1 ;;
      *.7z)      7z x \$1 ;;
      *)         echo \$1 cannot be extracted ;;
    esac
  else
    echo \$1 is not a valid file
  fi
}
EOF
grep -q '^## strings' "${file}" 2>/dev/null \
  || echo -e '## strings\nalias strings="strings -a"\n' >> "${file}"
grep -q '^## history' "${file}" 2>/dev/null \
  || echo -e '## history\nalias hg="history | grep"\n' >> "${file}"
grep -q '^## Network Services' "${file}" 2>/dev/null \
  || echo -e '### Network Services\nalias listen="netstat -antp | grep LISTEN"\n' >> "${file}"
grep -q '^## HDD size' "${file}" 2>/dev/null \
  || echo -e '### HDD size\nalias hogs="for i in G M K; do du -ah | grep [0-9]$i | sort -nr -k 1; done | head -n 11"\n' >> "${file}"
grep -q '^## Listing' "${file}" 2>/dev/null \
  || echo -e '### Listing\nalias ll="ls -l --block-size=1 --color=auto"\n' >> "${file}"
#--- Add in tools
grep -q '^## nmap' "${file}" 2>/dev/null \
  || echo -e '## nmap\nalias nmap="nmap --reason --open --stats-every 3m --max-retries 1 --max-scan-delay 20 --defeat-rst-ratelimit"\n' >> "${file}"
grep -q '^## aircrack-ng' "${file}" 2>/dev/null \
  || echo -e '## aircrack-ng\nalias aircrack-ng="aircrack-ng -z"\n' >> "${file}"
grep -q '^## airodump-ng' "${file}" 2>/dev/null \
  || echo -e '## airodump-ng \nalias airodump-ng="airodump-ng --manufacturer --wps --uptime"\n' >> "${file}"
grep -q '^## metasploit' "${file}" 2>/dev/null \
  || (echo -e '## metasploit\nalias msfc="systemctl start postgresql; msfdb start; msfconsole -q \"\$@\""' >> "${file}" \
    && echo -e 'alias msfconsole="systemctl start postgresql; msfdb start; msfconsole \"\$@\""\n' >> "${file}" )
[ "${openVAS}" != "false" ] \
  && (grep -q '^## openvas' "${file}" 2>/dev/null \
    || echo -e '## openvas\nalias openvas="openvas-stop; openvas-start; sleep 3s; xdg-open https://127.0.0.1:9392/ >/dev/null 2>&1"\n' >> "${file}")
grep -q '^## mana-toolkit' "${file}" 2>/dev/null \
  || (echo -e '## mana-toolkit\nalias mana-toolkit-start="a2ensite 000-mana-toolkit;a2dissite 000-default; systemctl restart apache2"' >> "${file}" \
    && echo -e 'alias mana-toolkit-stop="a2dissite 000-mana-toolkit; a2ensite 000-default; systemctl restart apache2"\n' >> "${file}" )
grep -q '^## ssh' "${file}" 2>/dev/null \
  || echo -e '## ssh\nalias ssh-start="systemctl restart ssh"\nalias ssh-stop="systemctl stop ssh"\n' >> "${file}"
grep -q '^## samba' "${file}" 2>/dev/null \
  || echo -e '## samba\nalias smb-start="systemctl restart smbd nmbd"\nalias smb-stop="systemctl stop smbd nmbd"\n' >> "${file}"
grep -q '^## rdesktop' "${file}" 2>/dev/null \
  || echo -e '## rdesktop\nalias rdesktop="rdesktop -z -P -g 90% -r disk:local=\"/tmp/\""\n' >> "${file}"
grep -q '^## python http' "${file}" 2>/dev/null \
  || echo -e '## python http\nalias http="python2 -m SimpleHTTPServer"\n' >> "${file}"
#--- Add in folders
grep -q '^## www' "${file}" 2>/dev/null \
  || echo -e '## www\nalias wwwroot="cd /var/www/html/"\n#alias www="cd /var/www/html/"\n' >> "${file}"
grep -q '^## ftp' "${file}" 2>/dev/null \
  || echo -e '## ftp\nalias ftproot="cd /var/ftp/"\n' >> "${file}"
grep -q '^## tftp' "${file}" 2>/dev/null \
  || echo -e '## tftp\nalias tftproot="cd /var/tftp/"\n' >> "${file}"
grep -q '^## smb' "${file}" 2>/dev/null \
  || echo -e '## smb\nalias smb="cd /var/samba/"\n#alias smbroot="cd /var/samba/"\n' >> "${file}"
(dmidecode | grep -iq vmware) \
  && (grep -q '^## vmware' "${file}" 2>/dev/null \
    || echo -e '## vmware\nalias vmroot="cd /mnt/hgfs/"\n' >> "${file}")
grep -q '^## edb' "${file}" 2>/dev/null \
  || echo -e '## edb\nalias edb="cd /usr/share/exploitdb/platforms/"\nalias edbroot="cd /usr/share/exploitdb/platforms/"\n' >> "${file}"
grep -q '^## wordlist' "${file}" 2>/dev/null \
  || echo -e '## wordlist\nalias wordlists="cd /usr/share/wordlists/"\n' >> "${file}"
#--- Apply new aliases
source "${file}" || source ~/.zshrc
#--- Check
#alias


##### Install (GNOME) Terminator
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing (GNOME) ${GREEN}Terminator${RESET} ~ multiple terminals in a single window"
apt -y -qq install terminator \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
#--- Configure terminator
mkdir -p ~/.config/terminator/
file=~/.config/terminator/config; [ -e "${file}" ] && cp -n $file{,.bkup}
cat <<EOF > "${file}" \
  || echo -e ' '${RED}'[!] Issue with writing file'${RESET} 1>&2
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
#--- Set terminator for XFCE's default
mkdir -p ~/.config/xfce4/
file=~/.config/xfce4/helpers.rc; [ -e "${file}" ] && cp -n $file{,.bkup}    #exo-preferred-applications   #xdg-mime default
([[ -e "${file}" && "$(tail -c 1 ${file})" != "" ]]) && echo >> "${file}"
sed -i 's_^TerminalEmulator=.*_TerminalEmulator=debian-x-terminal-emulator_' "${file}" 2>/dev/null \
  || echo -e 'TerminalEmulator=debian-x-terminal-emulator' >> "${file}"


##### Install ZSH & Oh-My-ZSH - root user.   Note:  'Open terminal here', will not work with ZSH.   Make sure to have tmux already installed
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}ZSH${RESET} & ${GREEN}Oh-My-ZSH${RESET} ~ unix shell"
apt -y -qq install zsh git curl \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
#--- Setup oh-my-zsh
timeout 300 curl --progress -k -L -f "https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh" | zsh
#--- Configure zsh
file=~/.zshrc; [ -e "${file}" ] && cp -n $file{,.bkup}   #/etc/zsh/zshrc
([[ -e "${file}" && "$(tail -c 1 ${file})" != "" ]]) && echo >> "${file}"
grep -q 'interactivecomments' "${file}" 2>/dev/null \
  || echo 'setopt interactivecomments' >> "${file}"
grep -q 'ignoreeof' "${file}" 2>/dev/null \
  || echo 'setopt ignoreeof' >> "${file}"
grep -q 'correctall' "${file}" 2>/dev/null \
  || echo 'setopt correctall' >> "${file}"
grep -q 'globdots' "${file}" 2>/dev/null \
  || echo 'setopt globdots' >> "${file}"
grep -q '.bash_aliases' "${file}" 2>/dev/null \
  || echo 'source $HOME/.bash_aliases' >> "${file}"
grep -q '/usr/bin/tmux' "${file}" 2>/dev/null \
  || echo '#if ([[ -z "$TMUX" && -n "$SSH_CONNECTION" ]]); then /usr/bin/tmux attach || /usr/bin/tmux new; fi' >> "${file}"   # If not already in tmux and via SSH
#--- Configure zsh (themes) ~ https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
sed -i 's/ZSH_THEME=.*/ZSH_THEME="mh"/' "${file}"   # Other themes: mh, jreese,   alanpeabody,   candy,   terminalparty, kardan,   nicoulaj, sunaku
#--- Configure oh-my-zsh
sed -i 's/plugins=(.*)/plugins=(git git-extras tmux dirhistory python pip)/' "${file}"
#--- Set zsh as default shell (current user)
chsh -s "$(which zsh)"


##### Install tmux - all users
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}tmux${RESET} ~ multiplex virtual consoles"
apt -y -qq install tmux \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
file=~/.tmux.conf; [ -e "${file}" ] && cp -n $file{,.bkup}   #/etc/tmux.conf
#--- Configure tmux
cat <<EOF > "${file}" \
  || echo -e ' '${RED}'[!] Issue with writing file'${RESET} 1>&2
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
[ -e /bin/zsh ] \
  && echo -e '## Use ZSH as default shell\nset-option -g default-shell /bin/zsh\n' >> "${file}"
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
file=~/.bash_aliases; [ -e "${file}" ] && cp -n $file{,.bkup}   #/etc/bash.bash_aliases
([[ -e "${file}" && "$(tail -c 1 ${file})" != "" ]]) && echo >> "${file}"
grep -q '^alias tmux' "${file}" 2>/dev/null \
  || echo -e '## tmux\nalias tmux="tmux attach || tmux new"\n' >> "${file}"    #alias tmux="tmux attach -t $HOST || tmux new -s $HOST"
#--- Apply new alias
source "${file}" || source ~/.zshrc


##### Configure screen ~ if possible, use tmux instead!
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Configuring ${GREEN}screen${RESET} ~ multiplex virtual consoles"
#apt -y -qq install screen \
#  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
#--- Configure screen
file=~/.screenrc; [ -e "${file}" ] && cp -n $file{,.bkup}
if [[ -f "${file}" ]]; then
  echo -e ' '${RED}'[!]'${RESET}" ${file} detected. Skipping..." 1>&2
else
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
fi


##### Install vim - all users
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}vim${RESET} ~ CLI text editor"
apt -y -qq install vim \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
#--- Configure vim
file=/etc/vim/vimrc; [ -e "${file}" ] && cp -n $file{,.bkup}   #~/.vimrc
([[ -e "${file}" && "$(tail -c 1 ${file})" != "" ]]) && echo >> "${file}"
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
grep -q '^set number' "${file}" 2>/dev/null \
  || echo 'set number' >> "${file}"                                                                      # Add line numbers
grep -q '^set expandtab' "${file}" 2>/dev/null \
  || echo -e 'set expandtab\nset smarttab' >> "${file}"                                                  # Set use spaces instead of tabs
grep -q '^set softtabstop' "${file}" 2>/dev/null \
  || echo -e 'set softtabstop=4\nset shiftwidth=4' >> "${file}"                                          # Set 4 spaces as a 'tab'
grep -q '^set foldmethod=marker' "${file}" 2>/dev/null \
  || echo 'set foldmethod=marker' >> "${file}"                                                           # Folding
grep -q '^nnoremap <space> za' "${file}" 2>/dev/null \
  || echo 'nnoremap <space> za' >> "${file}"                                                             # Space toggle folds
grep -q '^set hlsearch' "${file}" 2>/dev/null \
  || echo 'set hlsearch' >> "${file}"                                                                    # Highlight search results
grep -q '^set laststatus' "${file}" 2>/dev/null \
  || echo -e 'set laststatus=2\nset statusline=%F%m%r%h%w\ (%{&ff}){%Y}\ [%l,%v][%p%%]' >> "${file}"     # Status bar
grep -q '^filetype on' "${file}" 2>/dev/null \
  || echo -e 'filetype on\nfiletype plugin on\nsyntax enable\nset grepprg=grep\ -nH\ $*' >> "${file}"    # Syntax highlighting
grep -q '^set wildmenu' "${file}" 2>/dev/null \
  || echo -e 'set wildmenu\nset wildmode=list:longest,full' >> "${file}"                                 # Tab completion
grep -q '^set invnumber' "${file}" 2>/dev/null \
  || echo -e ':nmap <F8> :set invnumber<CR>' >> "${file}"                                                # Toggle line numbers
grep -q '^set pastetoggle=<F9>' "${file}" 2>/dev/null \
  || echo -e 'set pastetoggle=<F9>' >> "${file}"                                                         # Hotkey - turning off auto indent when pasting
grep -q '^:command Q q' "${file}" 2>/dev/null \
  || echo -e ':command Q q' >> "${file}"                                                                 # Fix stupid typo I always make
#--- Set as default editor
export EDITOR="vim"   #update-alternatives --config editor
file=/etc/bash.bashrc; [ -e "${file}" ] && cp -n $file{,.bkup}
([[ -e "${file}" && "$(tail -c 1 ${file})" != "" ]]) && echo >> "${file}"
grep -q '^EDITOR' "${file}" 2>/dev/null \
  || echo 'EDITOR="vim"' >> "${file}"
git config --global core.editor "vim"
#--- Set as default mergetool
git config --global merge.tool vimdiff
git config --global merge.conflictstyle diff3
git config --global mergetool.prompt false


##### Install git - all users
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}git${RESET} ~ revision control"
apt -y -qq install git \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
#--- Set as default editor
git config --global core.editor "vim"
#--- Set as default mergetool
git config --global merge.tool vimdiff
git config --global merge.conflictstyle diff3
git config --global mergetool.prompt false
#--- Set as default push
git config --global push.default simple


##### Setup firefox
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}firefox${RESET} ~ GUI web browser"
apt -y -qq install unzip curl firefox-esr \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
#--- Configure firefox
export DISPLAY=:0.0
timeout 15 firefox >/dev/null 2>&1                # Start and kill. Files needed for first time run
timeout 5 killall -9 -q -w firefox-esr >/dev/null
file=$(find ~/.mozilla/firefox/*.default*/ -maxdepth 1 -type f -name 'prefs.js' -print -quit)
[ -e "${file}" ] \
  && cp -n $file{,.bkup}   #/etc/firefox-esr/pref/*.js
([[ -e "${file}" && "$(tail -c 1 ${file})" != "" ]]) && echo >> "${file}"
sed -i 's/^.network.proxy.socks_remote_dns.*/user_pref("network.proxy.socks_remote_dns", true);' "${file}" 2>/dev/null \
  || echo 'user_pref("network.proxy.socks_remote_dns", true);' >> "${file}"
sed -i 's/^.browser.safebrowsing.enabled.*/user_pref("browser.safebrowsing.enabled", false);' "${file}" 2>/dev/null \
  || echo 'user_pref("browser.safebrowsing.enabled", false);' >> "${file}"
sed -i 's/^.browser.safebrowsing.malware.enabled.*/user_pref("browser.safebrowsing.malware.enabled", false);' "${file}" 2>/dev/null \
  || echo 'user_pref("browser.safebrowsing.malware.enabled", false);' >> "${file}"
sed -i 's/^.browser.safebrowsing.remoteLookups.enabled.*/user_pref("browser.safebrowsing.remoteLookups.enabled", false);' "${file}" 2>/dev/null \
  || echo 'user_pref("browser.safebrowsing.remoteLookups.enabled", false);' >> "${file}"
sed -i 's/^.*browser.startup.page.*/user_pref("browser.startup.page", 0);' "${file}" 2>/dev/null \
  || echo 'user_pref("browser.startup.page", 0);' >> "${file}"
sed -i 's/^.*privacy.donottrackheader.enabled.*/user_pref("privacy.donottrackheader.enabled", true);' "${file}" 2>/dev/null \
  || echo 'user_pref("privacy.donottrackheader.enabled", true);' >> "${file}"
sed -i 's/^.*browser.showQuitWarning.*/user_pref("browser.showQuitWarning", true);' "${file}" 2>/dev/null \
  || echo 'user_pref("browser.showQuitWarning", true);' >> "${file}"
sed -i 's/^.*extensions.https_everywhere._observatory.popup_shown.*/user_pref("extensions.https_everywhere._observatory.popup_shown", true);' "${file}" 2>/dev/null \
  || echo 'user_pref("extensions.https_everywhere._observatory.popup_shown", true);' >> "${file}"
sed -i 's/^.network.security.ports.banned.override/user_pref("network.security.ports.banned.override", "1-65455");' "${file}" 2>/dev/null \
  || echo 'user_pref("network.security.ports.banned.override", "1-65455");' >> "${file}"
#--- Replace bookmarks (base: http://pentest-bookmarks.googlecode.com)
file=$(find ~/.mozilla/firefox/*.default*/ -maxdepth 1 -type f -name 'bookmarks.html' -print -quit)
[ -e "${file}" ] \
  && cp -n $file{,.bkup}   #/etc/firefox-esr/profile/bookmarks.html
#timeout 300 curl --progress -k -L -f "http://pentest-bookmarks.googlecode.com/files/bookmarksv1.5.html" > /tmp/bookmarks_new.html \
#  || echo -e ' '${RED}'[!]'${RESET}" Issue downloading bookmarks_new.html" 1>&2      #***!!! hardcoded version! Need to manually check for updates
#--- Configure bookmarks
#awk '!a[$0]++' /tmp/bookmarks_new.html \
#  | \egrep -v ">(Latest Headlines|Getting Started|Recently Bookmarked|Recent Tags|Mozilla Firefox|Help and Tutorials|Customize Firefox|Get Involved|About Us|Hacker Media|Bookmarks Toolbar|Most Visited)</" \
#  | \egrep -v "^    </DL><p>" \
#  | \egrep -v "^<DD>Add" > "${file}"
sed -i 's#^</DL><p>#        </DL><p>\n    </DL><p>\n</DL><p>#' "${file}"                                          # Fix import issues from pentest-bookmarks...
sed -i 's#^    <DL><p>#    <DL><p>\n    <DT><A HREF="http://127.0.0.1/">localhost</A>#' "${file}"                 # Add localhost to bookmark toolbar (before hackery folder)
sed -i 's#^</DL><p>#    <DT><A HREF="https://127.0.0.1:8834/">Nessus</A>\n</DL><p>#' "${file}"                    # Add Nessus UI bookmark toolbar
[ "${openVAS}" != "false" ] \
  && sed -i 's#^</DL><p>#    <DT><A HREF="https://127.0.0.1:9392/">OpenVAS</A>\n</DL><p>#' "${file}"              # Add OpenVAS UI to bookmark toolbar
sed -i 's#^</DL><p>#    <DT><A HREF="http://127.0.0.1:3000/ui/panel">BeEF</A>\n</DL><p>#' "${file}"               # Add BeEF UI to bookmark toolbar
sed -i 's#^</DL><p>#    <DT><A HREF="http://127.0.0.1/rips/">RIPS</A>\n</DL><p>#' "${file}"                       # Add RIPs to bookmark toolbar
sed -i 's#^</DL><p>#    <DT><A HREF="https://paulschou.com/tools/xlate/">XLATE</A>\n</DL><p>#' "${file}"          # Add XLATE to bookmark toolbar
sed -i 's#^</DL><p>#    <DT><A HREF="https://hackvertor.co.uk/public">HackVertor</A>\n</DL><p>#' "${file}"        # Add HackVertor to bookmark toolbar
sed -i 's#^</DL><p>#    <DT><A HREF="http://www.irongeek.com/skiddypad.php">SkiddyPad</A>\n</DL><p>#' "${file}"   # Add Skiddypad to bookmark toolbar
sed -i 's#^</DL><p>#    <DT><A HREF="https://www.exploit-db.com/search/">Exploit-DB</A>\n</DL><p>#' "${file}"     # Add Exploit-DB to bookmark toolbar
sed -i 's#^</DL><p>#    <DT><A HREF="http://offset-db.com/">Offset-DB</A>\n</DL><p>#' "${file}"                   # Add Offset-DB to bookmark toolbar
sed -i 's#^</DL><p>#    <DT><A HREF="http://shell-storm.org/shellcode/">Shelcodes</A>\n</DL><p>#' "${file}"       # Add Shelcodes to bookmark toolbar
sed -i 's#^</DL><p>#    <DT><A HREF="http://ropshell.com/">ROP Shell</A>\n</DL><p>#' "${file}"                    # Add ROP Shell to bookmark toolbar
sed -i 's#^</DL><p>#    <DT><A HREF="https://ifconfig.io/">ifconfig</A>\n</DL><p>#' "${file}"                     # Add ifconfig.io to bookmark toolbar
sed -i 's#<HR>#<DT><H3 ADD_DATE="1303667175" LAST_MODIFIED="1303667175" PERSONAL_TOOLBAR_FOLDER="true">Bookmarks Toolbar</H3>\n<DD>Add bookmarks to this folder to see them displayed on the Bookmarks Toolbar#' "${file}"
#--- Clear bookmark cache
find ~/.mozilla/firefox/*.default*/ -maxdepth 1 -mindepth 1 -type f -name "places.sqlite" -delete
find ~/.mozilla/firefox/*.default*/bookmarkbackups/ -type f -delete
#--- Set firefox for XFCE's default
mkdir -p ~/.config/xfce4/
file=~/.config/xfce4/helpers.rc; [ -e "${file}" ] && cp -n $file{,.bkup}    #exo-preferred-applications   #xdg-mime default
([[ -e "${file}" && "$(tail -c 1 ${file})" != "" ]]) && echo >> "${file}"
sed -i 's#^WebBrowser=.*#WebBrowser=firefox#' "${file}" 2>/dev/null \
  || echo -e 'WebBrowser=firefox' >> "${file}"


##### Setup firefox's plugins
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}firefox's plugins${RESET} ~ useful addons"
#--- Configure firefox
export DISPLAY=:0.0
#--- Download extensions
ffpath="$(find ~/.mozilla/firefox/*.default*/ -maxdepth 0 -mindepth 0 -type d -name '*.default*' -print -quit)/extensions"
[ "${ffpath}" == "/extensions" ] \
  && echo -e ' '${RED}'[!]'${RESET}" Couldn't find Firefox folder" 1>&2
mkdir -p "${ffpath}/"
#--- plug-n-hack
#curl --progress -k -L -f "https://github.com/mozmark/ringleader/blob/master/fx_pnh.xpi?raw=true????????????????"  \
#  || echo -e ' '${RED}'[!]'${RESET}" Issue downloading 'plug-n-hack' 1>&2
#--- HttpFox
#curl --progress -k -L -f "https://addons.mozilla.org/en-GB/firefox/addon/httpfox/??????????????"  \
#  || echo -e ' '${RED}'[!]'${RESET}" Issue downloading 'HttpFox' 1>&2
#--- SQLite Manager
echo -n '[1/11]'; timeout 300 curl --progress -k -L -f "https://addons.mozilla.org/firefox/downloads/latest/5817/addon-5817-latest.xpi?src=dp-btn-primary" \
  -o "${ffpath}/SQLiteManager@mrinalkant.blogspot.com.xpi" \
    || echo -e ' '${RED}'[!]'${RESET}" Issue downloading 'SQLite Manager'" 1>&2
#--- Cookies Manager+
echo -n '[2/11]'; timeout 300 curl --progress -k -L -f "https://addons.mozilla.org/firefox/downloads/latest/92079/addon-92079-latest.xpi?src=dp-btn-primary" \
  -o "${ffpath}/{bb6bc1bb-f824-4702-90cd-35e2fb24f25d}.xpi" \
    || echo -e ' '${RED}'[!]'${RESET}" Issue downloading 'Cookies Manager+'" 1>&2
#--- Firebug
echo -n '[3/11]'; timeout 300 curl --progress -k -L -f "https://addons.mozilla.org/firefox/downloads/latest/1843/addon-1843-latest.xpi?src=dp-btn-primary" \
  -o "${ffpath}/firebug@software.joehewitt.com.xpi" \
    || echo -e ' '${RED}'[!]'${RESET}" Issue downloading 'Firebug'" 1>&2
#--- FoxyProxy Basic
echo -n '[4/11]'; timeout 300 curl --progress -k -L -f "https://addons.mozilla.org/firefox/downloads/latest/15023/addon-15023-latest.xpi?src=dp-btn-primary" \
  -o "${ffpath}/foxyproxy-basic@eric.h.jung.xpi" \
    || echo -e ' '${RED}'[!]'${RESET}" Issue downloading 'FoxyProxy Basic'" 1>&2
#--- User Agent Overrider
echo -n '[5/11]'; timeout 300 curl --progress -k -L -f "https://addons.mozilla.org/firefox/downloads/latest/429678/addon-429678-latest.xpi?src=dp-btn-primary" \
  -o "${ffpath}/useragentoverrider@qixinglu.com.xpi" \
    || echo -e ' '${RED}'[!]'${RESET}" Issue downloading 'User Agent Overrider'" 1>&2
#--- HTTPS Everywhere
echo -n '[6/11]'; timeout 300 curl --progress -k -L -f "https://www.eff.org/files/https-everywhere-latest.xpi" \
  -o "${ffpath}/https-everywhere@eff.org.xpi" \
    || echo -e ' '${RED}'[!]'${RESET}" Issue downloading 'HTTPS Everywhere'" 1>&2
#--- Live HTTP Headers
echo -n '[7/11]'; timeout 300 curl --progress -k -L -f "https://addons.mozilla.org/firefox/downloads/latest/3829/addon-3829-latest.xpi?src=dp-btn-primary" \
  -o "${ffpath}/{8f8fe09b-0bd3-4470-bc1b-8cad42b8203a}.xpi" \
    || echo -e ' '${RED}'[!]'${RESET}" Issue downloading 'Live HTTP Headers'" 1>&2
#---Tamper Data
echo -n '[8/11]'; timeout 300 curl --progress -k -L -f "https://addons.mozilla.org/firefox/downloads/latest/966/addon-966-latest.xpi?src=dp-btn-primary" \
  -o "${ffpath}/{9c51bd27-6ed8-4000-a2bf-36cb95c0c947}.xpi" \
    || echo -e ' '${RED}'[!]'${RESET}" Issue downloading 'Tamper Data'" 1>&2
#--- Disable Add-on Compatibility Checks
echo -n '[9/11]'; timeout 300 curl --progress -k -L -f "https://addons.mozilla.org/firefox/downloads/latest/300254/addon-300254-latest.xpi?src=dp-btn-primary" \
  -o "${ffpath}/check-compatibility@dactyl.googlecode.com.xpi" \
    || echo -e ' '${RED}'[!]'${RESET}" Issue downloading 'Disable Add-on Compatibility Checks'" 1>&2
#--- Disable HackBar
echo -n '[10/11]'; timeout 300 curl --progress -k -L -f "https://addons.mozilla.org/firefox/downloads/latest/3899/addon-3899-latest.xpi?src=dp-btn-primary" \
  -o "${ffpath}/{F5DDF39C-9293-4d5e-9AA8-E04E6DD5E9B4}.xpi" \
    || echo -e ' '${RED}'[!]'${RESET}" Issue downloading 'HackBar'" 1>&2
#--- uBlock
echo -n '[11/11]'; timeout 300 curl --progress -k -L -f "https://addons.mozilla.org/firefox/downloads/latest/607454/addon-607454-latest.xpi?src=dp-btn-primary" \
  -o "${ffpath}/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}.xpi" \
    || echo -e ' '${RED}'[!]'${RESET}" Issue downloading 'uBlock'" 1>&2
#--- Installing extensions
for FILE in $(find "${ffpath}" -maxdepth 1 -type f -name '*.xpi'); do
  d="$(basename "${FILE}" .xpi)"
  mkdir -p "${ffpath}/${d}/"
  unzip -q -o -d "${ffpath}/${d}/" "${FILE}"
  rm -f "${FILE}"
done
#--- Enable Firefox's addons/plugins/extensions
timeout 15 firefox >/dev/null 2>&1
timeout 5 killall -9 -q -w firefox-esr >/dev/null
sleep 3s
#--- Method #1 (Works on older versions)
file=$(find ~/.mozilla/firefox/*.default*/ -maxdepth 1 -type f -name 'extensions.sqlite' -print -quit)   #&& [ -e "${file}" ] && cp -n $file{,.bkup}
if [[ -e "${file}" ]] || [[ -n "${file}" ]]; then
  echo -e " ${YELLOW}[i]${RESET} Enabled ${YELLOW}Firefox's extensions${RESET} (via method #1 - extensions.sqlite)"
  apt -y -qq install sqlite3 \
    || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
  rm -f /tmp/firefox.sql
  touch /tmp/firefox.sql
  echo "UPDATE 'main'.'addon' SET 'active' = 1, 'userDisabled' = 0;" > /tmp/firefox.sql    # Force them all!
  sqlite3 "${file}" < /tmp/firefox.sql      #fuser extensions.sqlite
fi
#--- Method #2 (Newer versions)
file=$(find ~/.mozilla/firefox/*.default*/ -maxdepth 1 -type f -name 'extensions.json' -print -quit)   #&& [ -e "${file}" ] && cp -n $file{,.bkup}
if [[ -e "${file}" ]] || [[ -n "${file}" ]]; then
  echo -e " ${YELLOW}[i]${RESET} Enabled ${YELLOW}Firefox's extensions${RESET} (via method #2 - extensions.json)"
  sed -i 's/"active":false,/"active":true,/g' "${file}"                # Force them all!
  sed -i 's/"userDisabled":true,/"userDisabled":false,/g' "${file}"    # Force them all!
fi
#--- Remove cache
file=$(find ~/.mozilla/firefox/*.default*/ -maxdepth 1 -type f -name 'prefs.js' -print -quit)   #&& [ -e "${file}" ] && cp -n $file{,.bkup}
[ -n "${file}" ] \
  && sed -i '/extensions.installCache/d' "${file}"
#--- For extensions that just work without restarting
timeout 15 firefox >/dev/null 2>&1
timeout 5 killall -9 -q -w firefox-esr >/dev/null
sleep 3s
#--- For (most) extensions, as they need firefox to restart
timeout 15 firefox >/dev/null 2>&1
timeout 5 killall -9 -q -w firefox-esr >/dev/null
sleep 5s
#--- Wipe session (due to force close)
find ~/.mozilla/firefox/*.default*/ -maxdepth 1 -type f -name 'sessionstore.*' -delete
#--- Configure foxyproxy
file=$(find ~/.mozilla/firefox/*.default*/ -maxdepth 1 -type f -name 'foxyproxy.xml' -print -quit)   #&& [ -e "${file}" ] && cp -n $file{,.bkup}
if [[ -z "${file}" ]]; then
  echo -e ' '${RED}'[!]'${RESET}' Something went wrong with the FoxyProxy firefox extension (did any extensions install?). Skipping...' 1>&2
else     # Create new
  echo -ne '<?xml version="1.0" encoding="UTF-8"?>\n<foxyproxy mode="disabled" selectedTabIndex="0" toolbaricon="true" toolsMenu="true" contextMenu="false" advancedMenus="false" previousMode="disabled" resetIconColors="true" useStatusBarPrefix="true" excludePatternsFromCycling="false" excludeDisabledFromCycling="false" ignoreProxyScheme="false" apiDisabled="false" proxyForVersionCheck=""><random includeDirect="false" includeDisabled="false"/><statusbar icon="true" text="false" left="options" middle="cycle" right="contextmenu" width="0"/><toolbar left="options" middle="cycle" right="contextmenu"/><logg enabled="false" maxSize="500" noURLs="false" header="&lt;?xml version=&quot;1.0&quot; encoding=&quot;UTF-8&quot;?&gt;\n&lt;!DOCTYPE html PUBLIC &quot;-//W3C//DTD XHTML 1.0 Strict//EN&quot; &quot;http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd&quot;&gt;\n&lt;html xmlns=&quot;http://www.w3.org/1999/xhtml&quot;&gt;&lt;head&gt;&lt;title&gt;&lt;/title&gt;&lt;link rel=&quot;icon&quot; href=&quot;http://getfoxyproxy.org/favicon.ico&quot;/&gt;&lt;link rel=&quot;shortcut icon&quot; href=&quot;http://getfoxyproxy.org/favicon.ico&quot;/&gt;&lt;link rel=&quot;stylesheet&quot; href=&quot;http://getfoxyproxy.org/styles/log.css&quot; type=&quot;text/css&quot;/&gt;&lt;/head&gt;&lt;body&gt;&lt;table class=&quot;log-table&quot;&gt;&lt;thead&gt;&lt;tr&gt;&lt;td class=&quot;heading&quot;&gt;${timestamp-heading}&lt;/td&gt;&lt;td class=&quot;heading&quot;&gt;${url-heading}&lt;/td&gt;&lt;td class=&quot;heading&quot;&gt;${proxy-name-heading}&lt;/td&gt;&lt;td class=&quot;heading&quot;&gt;${proxy-notes-heading}&lt;/td&gt;&lt;td class=&quot;heading&quot;&gt;${pattern-name-heading}&lt;/td&gt;&lt;td class=&quot;heading&quot;&gt;${pattern-heading}&lt;/td&gt;&lt;td class=&quot;heading&quot;&gt;${pattern-case-heading}&lt;/td&gt;&lt;td class=&quot;heading&quot;&gt;${pattern-type-heading}&lt;/td&gt;&lt;td class=&quot;heading&quot;&gt;${pattern-color-heading}&lt;/td&gt;&lt;td class=&quot;heading&quot;&gt;${pac-result-heading}&lt;/td&gt;&lt;td class=&quot;heading&quot;&gt;${error-msg-heading}&lt;/td&gt;&lt;/tr&gt;&lt;/thead&gt;&lt;tfoot&gt;&lt;tr&gt;&lt;td/&gt;&lt;/tr&gt;&lt;/tfoot&gt;&lt;tbody&gt;" row="&lt;tr&gt;&lt;td class=&quot;timestamp&quot;&gt;${timestamp}&lt;/td&gt;&lt;td class=&quot;url&quot;&gt;&lt;a href=&quot;${url}&quot;&gt;${url}&lt;/a&gt;&lt;/td&gt;&lt;td class=&quot;proxy-name&quot;&gt;${proxy-name}&lt;/td&gt;&lt;td class=&quot;proxy-notes&quot;&gt;${proxy-notes}&lt;/td&gt;&lt;td class=&quot;pattern-name&quot;&gt;${pattern-name}&lt;/td&gt;&lt;td class=&quot;pattern&quot;&gt;${pattern}&lt;/td&gt;&lt;td class=&quot;pattern-case&quot;&gt;${pattern-case}&lt;/td&gt;&lt;td class=&quot;pattern-type&quot;&gt;${pattern-type}&lt;/td&gt;&lt;td class=&quot;pattern-color&quot;&gt;${pattern-color}&lt;/td&gt;&lt;td class=&quot;pac-result&quot;&gt;${pac-result}&lt;/td&gt;&lt;td class=&quot;error-msg&quot;&gt;${error-msg}&lt;/td&gt;&lt;/tr&gt;" footer="&lt;/tbody&gt;&lt;/table&gt;&lt;/body&gt;&lt;/html&gt;"/><warnings/><autoadd enabled="false" temp="false" reload="true" notify="true" notifyWhenCanceled="true" prompt="true"><match enabled="true" name="Dynamic AutoAdd Pattern" pattern="*://${3}${6}/*" isRegEx="false" isBlackList="false" isMultiLine="false" caseSensitive="false" fromSubscription="false"/><match enabled="true" name="" pattern="*You are not authorized to view this page*" isRegEx="false" isBlackList="false" isMultiLine="true" caseSensitive="false" fromSubscription="false"/></autoadd><quickadd enabled="false" temp="false" reload="true" notify="true" notifyWhenCanceled="true" prompt="true"><match enabled="true" name="Dynamic QuickAdd Pattern" pattern="*://${3}${6}/*" isRegEx="false" isBlackList="false" isMultiLine="false" caseSensitive="false" fromSubscription="false"/></quickadd><defaultPrefs origPrefetch="null"/><proxies>' > "${file}"
  echo -ne '<proxy name="localhost:8080" id="1145138293" notes="e.g. Burp, w3af" fromSubscription="false" enabled="true" mode="manual" selectedTabIndex="0" lastresort="false" animatedIcons="true" includeInCycle="false" color="#07753E" proxyDNS="true" noInternalIPs="false" autoconfMode="pac" clearCacheBeforeUse="true" disableCache="true" clearCookiesBeforeUse="false" rejectCookies="false"><matches/><autoconf url="" loadNotification="true" errorNotification="true" autoReload="false" reloadFreqMins="60" disableOnBadPAC="true"/><autoconf url="http://wpad/wpad.dat" loadNotification="true" errorNotification="true" autoReload="false" reloadFreqMins="60" disableOnBadPAC="true"/><manualconf host="127.0.0.1" port="8080" socksversion="5" isSocks="false" username="" password="" domain=""/></proxy>' >> "${file}"
  echo -ne '<proxy name="localhost:8081 (socket5)" id="212586674" notes="e.g. SSH" fromSubscription="false" enabled="true" mode="manual" selectedTabIndex="0" lastresort="false" animatedIcons="true" includeInCycle="false" color="#917504" proxyDNS="true" noInternalIPs="false" autoconfMode="pac" clearCacheBeforeUse="true" disableCache="true" clearCookiesBeforeUse="false" rejectCookies="false"><matches/><autoconf url="" loadNotification="true" errorNotification="true" autoReload="false" reloadFreqMins="60" disableOnBadPAC="true"/><autoconf url="http://wpad/wpad.dat" loadNotification="true" errorNotification="true" autoReload="false" reloadFreqMins="60" disableOnBadPAC="true"/><manualconf host="127.0.0.1" port="8081" socksversion="5" isSocks="true" username="" password="" domain=""/></proxy>' >> "${file}"
  echo -ne '<proxy name="No Caching" id="3884644610" notes="" fromSubscription="false" enabled="true" mode="system" selectedTabIndex="0" lastresort="false" animatedIcons="true" includeInCycle="false" color="#990DA6" proxyDNS="true" noInternalIPs="false" autoconfMode="pac" clearCacheBeforeUse="true" disableCache="true" clearCookiesBeforeUse="false" rejectCookies="false"><matches/><autoconf url="" loadNotification="true" errorNotification="true" autoReload="false" reloadFreqMins="60" disableOnBadPAC="true"/><autoconf url="http://wpad/wpad.dat" loadNotification="true" errorNotification="true" autoReload="false" reloadFreqMins="60" disableOnBadPAC="true"/><manualconf host="" port="" socksversion="5" isSocks="false" username="" password="" domain=""/></proxy>' >> "${file}"
  echo -ne '<proxy name="Default" id="3377581719" notes="" fromSubscription="false" enabled="true" mode="direct" selectedTabIndex="0" lastresort="true" animatedIcons="false" includeInCycle="true" color="#0055E5" proxyDNS="true" noInternalIPs="false" autoconfMode="pac" clearCacheBeforeUse="false" disableCache="false" clearCookiesBeforeUse="false" rejectCookies="false"><matches><match enabled="true" name="All" pattern="*" isRegEx="false" isBlackList="false" isMultiLine="false" caseSensitive="false" fromSubscription="false"/></matches><autoconf url="" loadNotification="true" errorNotification="true" autoReload="false" reloadFreqMins="60" disableOnBadPAC="true"/><autoconf url="http://wpad/wpad.dat" loadNotification="true" errorNotification="true" autoReload="false" reloadFreqMins="60" disableOnBadPAC="true"/><manualconf host="" port="" socksversion="5" isSocks="false" username="" password=""/></proxy>' >> "${file}"
  echo -e '</proxies></foxyproxy>' >> "${file}"
fi


##### Install conky
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}conky${RESET} ~ GUI desktop monitor"
export DISPLAY=:0.0
apt -y -qq install conky \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
#--- Configure conky
file=~/.conkyrc; [ -e "${file}" ] && cp -n $file{,.bkup}
if [[ -f "${file}" ]]; then
  echo -e ' '${RED}'[!]'${RESET}" ${file} detected. Skipping..." 1>&2
else
  cat <<EOF > "${file}"
--# Useful: http://forums.opensuse.org/english/get-technical-help-here/how-faq-forums/unreviewed-how-faq/464737-easy-configuring-conky-conkyconf.html
conky.config = {
    background = false,

    font = 'monospace:size=8:weight=bold',
    use_xft = true,

    update_interval = 2.0,

    own_window = true,
    own_window_type = 'normal',
    own_window_transparent = true,
    own_window_class = 'conky-semi',
    own_window_argb_visual = false,
    own_window_colour = 'brown',
    own_window_hints = 'undecorated,below,sticky,skip_taskbar,skip_pager',

    double_buffer = true,
    maximum_width = 260,

    draw_shades = true,
    draw_outline = false,
    draw_borders = false,

    stippled_borders = 3,
    border_inner_margin = 9,
    border_width = 10,

    default_color = 'grey',

    alignment = 'bottom_right',
    gap_x = 5,
    gap_y = 0,

    uppercase = false,
    use_spacer = 'right',
};

conky.text = [[
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
ip addr show eth1 &>/dev/null \
  && cat <<EOF >> "${file}"
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
]]
EOF
fi
#--- Create start script
mkdir -p /usr/local/bin/
file=/usr/local/bin/start-conky; [ -e "${file}" ] && cp -n $file{,.bkup}
cat <<EOF > "${file}" \
  || echo -e ' '${RED}'[!] Issue with writing file'${RESET} 1>&2
#!/bin/bash

[[ -z \${DISPLAY} ]] && export DISPLAY=:0.0

$(which timeout) 10 $(which killall) -9 -q -w conky
$(which sleep) 20s
$(which conky) &
EOF
chmod -f 0500 "${file}"
#--- Run now
bash /usr/local/bin/start-conky >/dev/null 2>&1 &
#--- Add to startup (each login)
mkdir -p ~/.config/autostart/
file=~/.config/autostart/conkyscript.desktop; [ -e "${file}" ] && cp -n $file{,.bkup}
cat <<EOF > "${file}" \
  || echo -e ' '${RED}'[!] Issue with writing file'${RESET} 1>&2
[Desktop Entry]
Name=conky
Exec=/usr/local/bin/start-conky
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Type=Application
Comment=
EOF
#--- Add keyboard shortcut (CTRL+r) to run the conky refresh script
file=~/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml   #; [ -e "${file}" ] && cp -n $file{,.bkup}
if [ -e "${file}" ]; then
  grep -q '<property name="&lt;Primary&gt;r" type="string" value="/usr/local/bin/start-conky"/>' "${file}" \
    || sed -i 's#<property name="\&lt;Alt\&gt;F2" type="string" value="xfrun4"/>#<property name="\&lt;Alt\&gt;F2" type="string" value="xfrun4"/>\n      <property name="\&lt;Primary\&gt;r" type="string" value="/usr/local/bin/start-conky"/>#' "${file}"
fi


##### Install metasploit ~ http://docs.kali.org/general-use/starting-metasploit-framework-in-kali
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}metasploit${RESET} ~ exploit framework"
apt -y -qq install metasploit-framework \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
mkdir -p ~/.msf4/modules/{auxiliary,exploits,payloads,post}/
#--- ASCII art
#export GOCOW=1   # Always a cow logo ;)   Others: THISISHALLOWEEN (Halloween), APRILFOOLSPONIES (My Little Pony)
#file=~/.bashrc; [ -e "${file}" ] && cp -n $file{,.bkup}
#([[ -e "${file}" && "$(tail -c 1 ${file})" != "" ]]) && echo >> "${file}"
#grep -q '^GOCOW' "${file}" 2>/dev/null || echo 'GOCOW=1' >> "${file}"
#--- Fix any port issues
file=$(find /etc/postgresql/*/main/ -maxdepth 1 -type f -name postgresql.conf -print -quit);
[ -e "${file}" ] && cp -n $file{,.bkup}
sed -i 's/port = .* #/port = 5432 /' "${file}"
#--- Fix permissions - 'could not translate host name "localhost", service "5432" to address: Name or service not known'
chmod 0644 /etc/hosts
#--- Start services
systemctl stop postgresql
systemctl start postgresql
msfdb reinit
sleep 5s
#--- Autorun Metasploit commands each startup
file=~/.msf4/msf_autorunscript.rc; [ -e "${file}" ] && cp -n $file{,.bkup}
if [[ -f "${file}" ]]; then
  echo -e ' '${RED}'[!]'${RESET}" ${file} detected. Skipping..." 1>&2
else
  cat <<EOF > "${file}"
#run post/windows/escalate/getsystem

#run migrate -f -k
#run migrate -n "explorer.exe" -k    # Can trigger AV alerts by touching explorer.exe...

#run post/windows/manage/smart_migrate
#run post/windows/gather/smart_hashdump
EOF
fi
file=~/.msf4/msfconsole.rc; [ -e "${file}" ] && cp -n $file{,.bkup}
if [[ -f "${file}" ]]; then
  echo -e ' '${RED}'[!]'${RESET}" ${file} detected. Skipping..." 1>&2
else
  cat <<EOF > "${file}"
load auto_add_route

load alias
alias del rm
alias handler use exploit/multi/handler

load sounds

setg TimestampOutput true
setg VERBOSE true

setg ExitOnSession false
setg EnableStageEncoding true
setg LHOST 0.0.0.0
setg LPORT 443
EOF
#use exploit/multi/handler
#setg AutoRunScript 'multi_console_command -rc "~/.msf4/msf_autorunscript.rc"'
#set PAYLOAD windows/meterpreter/reverse_https
fi
#--- Aliases time
file=~/.bash_aliases; [ -e "${file}" ] && cp -n $file{,.bkup}   #/etc/bash.bash_aliases
([[ -e "${file}" && "$(tail -c 1 ${file})" != "" ]]) && echo >> "${file}"
#--- Aliases for console
grep -q '^alias msfc=' "${file}" 2>/dev/null \
  || echo -e 'alias msfc="systemctl start postgresql; msfdb start; msfconsole -q \"\$@\""' >> "${file}"
grep -q '^alias msfconsole=' "${file}" 2>/dev/null \
  || echo -e 'alias msfconsole="systemctl start postgresql; msfdb start; msfconsole \"\$@\""\n' >> "${file}"
#--- Aliases to speed up msfvenom (create static output)
grep -q "^alias msfvenom-list-all" "${file}" 2>/dev/null \
  || echo "alias msfvenom-list-all='cat ~/.msf4/msfvenom/all'" >> "${file}"
grep -q "^alias msfvenom-list-nops" "${file}" 2>/dev/null \
  || echo "alias msfvenom-list-nops='cat ~/.msf4/msfvenom/nops'" >> "${file}"
grep -q "^alias msfvenom-list-payloads" "${file}" 2>/dev/null \
  || echo "alias msfvenom-list-payloads='cat ~/.msf4/msfvenom/payloads'" >> "${file}"
grep -q "^alias msfvenom-list-encoders" "${file}" 2>/dev/null \
  || echo "alias msfvenom-list-encoders='cat ~/.msf4/msfvenom/encoders'" >> "${file}"
grep -q "^alias msfvenom-list-formats" "${file}" 2>/dev/null \
  || echo "alias msfvenom-list-formats='cat ~/.msf4/msfvenom/formats'" >> "${file}"
grep -q "^alias msfvenom-list-generate" "${file}" 2>/dev/null \
  || echo "alias msfvenom-list-generate='_msfvenom-list-generate'" >> "${file}"
grep -q "^function _msfvenom-list-generate" "${file}" 2>/dev/null \
  || cat <<EOF >> "${file}" \
    || echo -e ' '${RED}'[!] Issue with writing file'${RESET} 1>&2
function _msfvenom-list-generate {
  mkdir -p ~/.msf4/msfvenom/
  msfvenom --list > ~/.msf4/msfvenom/all
  msfvenom --list nops > ~/.msf4/msfvenom/nops
  msfvenom --list payloads > ~/.msf4/msfvenom/payloads
  msfvenom --list encoders > ~/.msf4/msfvenom/encoders
  msfvenom --help-formats 2> ~/.msf4/msfvenom/formats
}
EOF
#--- Apply new aliases
source "${file}" || source ~/.zshrc
#--- Generate (Can't call alias)
mkdir -p ~/.msf4/msfvenom/
msfvenom --list > ~/.msf4/msfvenom/all
msfvenom --list nops > ~/.msf4/msfvenom/nops
msfvenom --list payloads > ~/.msf4/msfvenom/payloads
msfvenom --list encoders > ~/.msf4/msfvenom/encoders
msfvenom --help-formats 2> ~/.msf4/msfvenom/formats
#--- First time run with Metasploit
(( STAGE++ )); echo -e " ${GREEN}[i]${RESET} (${STAGE}/${TOTAL}) ${GREEN}Starting Metasploit for the first time${RESET} ~ this ${BOLD}will take a ~350 seconds${RESET} (~6 mintues)"
echo "Started at: $(date)"
systemctl start postgresql
msfdb start
msfconsole -q -x 'version;db_status;sleep 310;exit'


##### Configuring armitage
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Configuring ${GREEN}armitage${RESET} ~ GUI Metasploit UI"
export MSF_DATABASE_CONFIG=/usr/share/metasploit-framework/config/database.yml
for file in /etc/bash.bashrc ~/.zshrc; do     #~/.bashrc
  [ ! -e "${file}" ] && continue
  [ -e "${file}" ] && cp -n $file{,.bkup}
  ([[ -e "${file}" && "$(tail -c 1 ${file})" != "" ]]) && echo >> "${file}"
  grep -q 'MSF_DATABASE_CONFIG' "${file}" 2>/dev/null \
    || echo -e 'MSF_DATABASE_CONFIG=/usr/share/metasploit-framework/config/database.yml\n' >> "${file}"
done
#--- Test
#msfrpcd -U msf -P test -f -S -a 127.0.0.1


##### Install exe2hex
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}exe2hex${RESET} ~ Inline file transfer"
apt -y -qq install exe2hexbat \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2


##### Install MPC
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}MPC${RESET} ~ Msfvenom Payload Creator"
apt -y -qq install msfpc \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2


##### Configuring Gedit
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Configuring ${GREEN}Gedit${RESET} ~ GUI text editor"
#--- Install Gedit
apt -y -qq install gedit \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
#--- Configure Gedit
dconf write /org/gnome/gedit/preferences/editor/wrap-last-split-mode "'word'"
dconf write /org/gnome/gedit/preferences/ui/statusbar-visible true
dconf write /org/gnome/gedit/preferences/editor/display-line-numbers true
dconf write /org/gnome/gedit/preferences/editor/highlight-current-line true
dconf write /org/gnome/gedit/preferences/editor/bracket-matching true
dconf write /org/gnome/gedit/preferences/editor/insert-spaces true
dconf write /org/gnome/gedit/preferences/editor/auto-indent true
for plugin in modelines sort externaltools docinfo filebrowser quickopen time spell; do
  loaded=$( dconf read /org/gnome/gedit/plugins/active-plugins )
  echo ${loaded} | grep -q "'${plugin}'" \
    && continue
  new=$( echo "${loaded} '${plugin}']" | sed "s/'] /', /" )
  dconf write /org/gnome/gedit/plugins/active-plugins "${new}"
done


##### Install PyCharm (Community Edition)
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}PyCharm (Community Edition)${RESET} ~ Python IDE"
timeout 300 curl --progress -k -L -f "https://download.jetbrains.com/python/pycharm-community-2016.2.3.tar.gz" > /tmp/pycharms-community.tar.gz \
  || echo -e ' '${RED}'[!]'${RESET}" Issue downloading pycharms-community.tar.gz" 1>&2       #***!!! hardcoded version!
if [ -e /tmp/pycharms-community.tar.gz ]; then
  tar -xf /tmp/pycharms-community.tar.gz -C /tmp/
  rm -rf /opt/pycharms/
  mv -f /tmp/pycharm-community-*/ /opt/pycharms
  mkdir -p /usr/local/bin/
  ln -sf /opt/pycharms/bin/pycharm.sh /usr/local/bin/pycharms
fi


##### Install wdiff
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}wdiff${RESET} ~ Compares two files word by word"
apt -y -qq install wdiff wdiff-doc \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2


##### Install meld
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}meld${RESET} ~ GUI text compare"
apt -y -qq install meld \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
#--- Configure meld
gconftool-2 -t bool -s /apps/meld/show_line_numbers true
gconftool-2 -t bool -s /apps/meld/show_whitespace true
gconftool-2 -t bool -s /apps/meld/use_syntax_highlighting true
gconftool-2 -t int -s /apps/meld/edit_wrap_lines 2


##### Install vbindiff
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}vbindiff${RESET} ~ visually compare binary files"
apt -y -qq install vbindiff \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2


##### Install OpenVAS
if [[ "${openVAS}" != "false" ]]; then
  (( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}OpenVAS${RESET} ~ vulnerability scanner"
  apt -y -qq install openvas \
    || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
  openvas-setup
  #--- Bug fix (target credentials creation)
  mkdir -p /var/lib/openvas/gnupg/
  #--- Bug fix (keys)
  curl --progress -k -L -f "http://www.openvas.org/OpenVAS_TI.asc" | gpg --import - \
    || echo -e ' '${RED}'[!]'${RESET}" Issue downloading OpenVAS_TI.asc" 1>&2
  #--- Make sure all services are correct
  openvas-start
  #--- User control
  username="root"
  password="toor"
  (openvasmd --get-users | grep -q ^admin$) \
    && echo -n 'admin user: ' \
    && openvasmd --delete-user=admin
  (openvasmd --get-users | grep -q "^${username}$") \
    || (echo -n "${username} user: "; openvasmd --create-user="${username}"; openvasmd --user="${username}" --new-password="${password}" >/dev/null)
  echo -e " ${YELLOW}[i]${RESET} OpenVAS username: ${username}"
  echo -e " ${YELLOW}[i]${RESET} OpenVAS password: ${password}   ***${BOLD}CHANGE THIS ASAP${RESET}***"
  echo -e " ${YELLOW}[i]${RESET} Run: # openvasmd --user=root --new-password='<NEW_PASSWORD>'"
  sleep 3s
  openvas-check-setup
  #--- Remove from start up
  systemctl disable openvas-manager
  systemctl disable openvas-scanner
  systemctl disable greenbone-security-assistant
  #--- Setup alias
  file=~/.bash_aliases; [ -e "${file}" ] && cp -n $file{,.bkup}   #/etc/bash.bash_aliases
  grep -q '^## openvas' "${file}" 2>/dev/null \
    || echo -e '## openvas\nalias openvas="openvas-stop; openvas-start; sleep 3s; xdg-open https://127.0.0.1:9392/ >/dev/null 2>&1"\n' >> "${file}"
  source "${file}" || source ~/.zshrc
else
  echo -e "\n\n ${YELLOW}[i]${RESET} ${YELLOW}Skipping OpenVAS${RESET} (missing: '$0 ${BOLD}--openvas${RESET}')..." 1>&2
fi


##### Install vFeed
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}vFeed${RESET} ~ vulnerability database"
apt -y -qq install vfeed \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2


##### Install Burp Suite
if [[ "${burpFree}" != "false" ]]; then
  (( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}Burp Suite (Community Edition)${RESET} ~ web application proxy"
  apt -y -qq install burpsuite curl \
    || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
  mkdir -p ~/.java/.userPrefs/burp/
  file=~/.java/.userPrefs/burp/prefs.xml;   #[ -e "${file}" ] && cp -n $file{,.bkup}
  [ -e "${file}" ] \
    || cat <<EOF > "${file}"
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<!DOCTYPE map SYSTEM "http://java.sun.com/dtd/preferences.dtd" >
<map MAP_XML_VERSION="1.0">
  <entry key="eulafree" value="2"/>
  <entry key="free.suite.feedbackReportingEnabled" value="false"/>
</map>
EOF
  #--- Extract CA
  find /tmp/ -maxdepth 1 -name 'burp*.tmp' -delete
  export DISPLAY=:0.0
  timeout 120 burpsuite >/dev/null 2>&1 &
  PID=$!
  sleep 15s
  #echo "-----BEGIN CERTIFICATE-----" > /tmp/PortSwiggerCA \
  #  && awk -F '"' '/caCert/ {print $4}' ~/.java/.userPrefs/burp/prefs.xml | fold -w 64 >> /tmp/PortSwiggerCA \
  #  && echo "-----END CERTIFICATE-----" >> /tmp/PortSwiggerCA
  export http_proxy="http://127.0.0.1:8080"
  rm -f /tmp/burp.crt
  while test -d /proc/${PID}; do
    sleep 1s
    curl --progress -k -L -f "http://burp/cert" -o /tmp/burp.crt 2>/dev/null      # || echo -e ' '${RED}'[!]'${RESET}" Issue downloading burp.crt" 1>&2
    [ -f /tmp/burp.crt ] && break
  done
  timeout 5 kill ${PID} 2>/dev/null \
    || echo -e ' '${RED}'[!]'${RESET}" Failed to kill ${RED}burpsuite${RESET}"
  unset http_proxy
  #--- Installing CA
  if [[ -f /tmp/burp.crt ]]; then
    apt -y -qq install libnss3-tools \
      || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
    folder=$(find ~/.mozilla/firefox/ -maxdepth 1 -type d -name '*.default' -print -quit)
    certutil -A -n Burp -t "CT,c,c" -d "${folder}" -i /tmp/burp.crt
    timeout 15 firefox >/dev/null 2>&1
    timeout 5 killall -9 -q -w firefox-esr >/dev/null
    #mkdir -p /usr/share/ca-certificates/burp/
    #cp -f /tmp/burp.crt /usr/share/ca-certificates/burp/
    #dpkg-reconfigure ca-certificates    # Not automated
    echo -e " ${YELLOW}[i]${RESET} Installed ${YELLOW}Burp Suite CA${RESET}"
  else
    echo -e ' '${RED}'[!]'${RESET}' Did not install Burp Suite Certificate Authority (CA)' 1>&2
    echo -e ' '${RED}'[!]'${RESET}' Skipping...' 1>&2
  fi
  #--- Remove old temp files
  sleep 2s
  find /tmp/ -maxdepth 1 -name 'burp*.tmp' -delete 2>/dev/null
  find ~/.mozilla/firefox/*.default*/ -maxdepth 1 -type f -name 'sessionstore.*' -delete
  unset http_proxy
else
  echo -e "\n\n ${YELLOW}[i]${RESET} ${YELLOW}Skipping Burp Suite${RESET} (missing: '$0 ${BOLD}--burp${RESET}')..." 1>&2
fi


##### Configure python console - all users
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Configuring ${GREEN}python console${RESET} ~ tab complete & history support"
export PYTHONSTARTUP=$HOME/.pythonstartup
file=/etc/bash.bashrc; [ -e "${file}" ] && cp -n $file{,.bkup}   #~/.bashrc
grep -q PYTHONSTARTUP "${file}" \
  || echo 'export PYTHONSTARTUP=$HOME/.pythonstartup' >> "${file}"
#--- Python start up file
cat <<EOF > ~/.pythonstartup \
  || echo -e ' '${RED}'[!] Issue with writing file'${RESET} 1>&2
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
#--- Apply new configs
source "${file}" || source ~/.zshrc


##### Install virtualenvwrapper
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}virtualenvwrapper${RESET} ~ virtual environment wrapper"
apt -y -qq install virtualenvwrapper \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2


##### Install go
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}go${RESET} ~ programming language"
apt -y -qq install golang \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2


##### Install gitg
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}gitg${RESET} ~ GUI git client"
apt -y -qq install gitg \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2


##### Install sparta
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}sparta${RESET} ~ GUI automatic wrapper"
apt -y -qq install sparta \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2


##### Install wireshark
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}Wireshark${RESET} ~ GUI network protocol analyzer"
#--- Hide running as root warning
mkdir -p ~/.wireshark/
file=~/.wireshark/recent_common;   #[ -e "${file}" ] && cp -n $file{,.bkup}
[ -e "${file}" ] \
  || echo "privs.warn_if_elevated: FALSE" > "${file}"
#--- Disable lua warning
[ -e "/usr/share/wireshark/init.lua" ] \
  && mv -f /usr/share/wireshark/init.lua{,.disabled}


##### Install silver searcher
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}silver searcher${RESET} ~ code searching"
apt -y -qq install silversearcher-ag \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2


##### Install rips
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}rips${RESET} ~ source code scanner"
apt -y -qq install apache2 php git \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
git clone -q -b master https://github.com/ripsscanner/rips.git /opt/rips-git/ \
  || echo -e ' '${RED}'[!] Issue when git cloning'${RESET} 1>&2
pushd /opt/rips-git/ >/dev/null
git pull -q
popd >/dev/null
#--- Add to path
file=/etc/apache2/conf-available/rips.conf
[ -e "${file}" ] \
  || cat <<EOF > "${file}"
Alias /rips /opt/rips-git

<Directory /opt/rips-git/ >
  Options FollowSymLinks
  AllowOverride None
  Order deny,allow
  Deny from all
  Allow from 127.0.0.0/255.0.0.0 ::1/128
</Directory>
EOF
ln -sf /etc/apache2/conf-available/rips.conf /etc/apache2/conf-enabled/rips.conf
systemctl restart apache2


##### Install graudit
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}graudit${RESET} ~ source code auditing"
apt -y -qq install git \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
git clone -q -b master https://github.com/wireghoul/graudit.git /opt/graudit-git/ \
  || echo -e ' '${RED}'[!] Issue when git cloning'${RESET} 1>&2
pushd /opt/graudit-git/ >/dev/null
git pull -q
popd >/dev/null
#--- Add to path
mkdir -p /usr/local/bin/
file=/usr/local/bin/graudit-git
cat <<EOF > "${file}" \
  || echo -e ' '${RED}'[!] Issue with writing file'${RESET} 1>&2
#!/bin/bash

cd /opt/graudit-git/ && bash graudit.sh "\$@"
EOF
chmod +x "${file}"


##### Install libreoffice
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}LibreOffice${RESET} ~ GUI office suite"
apt -y -qq install libreoffice \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2


##### Install ipcalc & sipcalc
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}ipcalc${RESET} & ${GREEN}sipcalc${RESET} ~ CLI subnet calculators"
apt -y -qq install ipcalc sipcalc \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2


##### Install asciinema
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}asciinema${RESET} ~ CLI terminal recorder"
curl -s -L https://asciinema.org/install | sh


##### Install shutter
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}shutter${RESET} ~ GUI static screen capture"
apt -y -qq install shutter \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2


##### Install psmisc ~ allows for 'killall command' to be used
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}psmisc${RESET} ~ suite to help with running processes"
apt -y -qq install psmisc \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2


###### Setup pipe viewer
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}pipe viewer${RESET} ~ CLI progress bar"
apt -y -qq install pv \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2


###### Setup pwgen
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}pwgen${RESET} ~ password generator"
apt -y -qq install pwgen \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2


##### Install htop
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}htop${RESET} ~ CLI process viewer"
apt -y -qq install htop \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2


##### Install powertop
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}powertop${RESET} ~ CLI power consumption viewer"
apt -y -qq install powertop \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2


##### Install iotop
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}iotop${RESET} ~ CLI I/O usage"
apt -y -qq install iotop \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2


##### Install ca-certificates
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}ca-certificates${RESET} ~ HTTPS/SSL/TLS"
apt -y -qq install ca-certificates \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2


##### Install testssl
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}testssl${RESET} ~ Testing TLS/SSL encryption"
apt -y -qq install testssl.sh \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2


##### Install UACScript
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}UACScript${RESET} ~ UAC Bypass for Windows 7"
apt -y -qq install git windows-binaries \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
git clone -q -b master https://github.com/Vozzie/uacscript.git /opt/uacscript-git/ \
  || echo -e ' '${RED}'[!] Issue when git cloning'${RESET} 1>&2
pushd /opt/uacscript-git/ >/dev/null
git pull -q
popd >/dev/null
ln -sf /usr/share/windows-binaries/uac-win7 /opt/uacscript-git/


##### Install MiniReverse_Shell_With_Parameters
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}MiniReverse_Shell_With_Parameters${RESET} ~ Generate shellcode for a reverse shell"
apt -y -qq install git windows-binaries \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
git clone -q -b master https://github.com/xillwillx/MiniReverse_Shell_With_Parameters.git /opt/minireverse-shell-with-parameters-git/ \
  || echo -e ' '${RED}'[!] Issue when git cloning'${RESET} 1>&2
pushd /opt/minireverse-shell-with-parameters-git/ >/dev/null
git pull -q
popd >/dev/null
ln -sf /usr/share/windows-binaries/MiniReverse /opt/minireverse-shell-with-parameters-git/


##### Install axel
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}axel${RESET} ~ CLI download manager"
apt -y -qq install axel \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
#--- Setup alias
file=~/.bash_aliases; [ -e "${file}" ] && cp -n $file{,.bkup}   #/etc/bash.bash_aliases
([[ -e "${file}" && "$(tail -c 1 ${file})" != "" ]]) && echo >> "${file}"
grep -q '^alias axel' "${file}" 2>/dev/null \
  || echo -e '## axel\nalias axel="axel -a"\n' >> "${file}"
#--- Apply new alias
source "${file}" || source ~/.zshrc


##### Install html2text
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}html2text${RESET} ~ CLI html rendering"
apt -y -qq install html2text \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2


##### Install tmux2html
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}tmux2html${RESET} ~ Render tmux as HTML"
apt -y -qq install git python python-pip \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
pip install tmux2html


##### Install gparted
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}GParted${RESET} ~ GUI partition manager"
apt -y -qq install gparted \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2


##### Install daemonfs
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}daemonfs${RESET} ~ GUI file monitor"
apt -y -qq install daemonfs \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2


##### Install filezilla
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}FileZilla${RESET} ~ GUI file transfer"
apt -y -qq install filezilla \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
#--- Configure filezilla
export DISPLAY=:0.0
timeout 5 filezilla >/dev/null 2>&1     # Start and kill. Files needed for first time run
mkdir -p ~/.config/filezilla/
file=~/.config/filezilla/filezilla.xml; [ -e "${file}" ] && cp -n $file{,.bkup}
[ ! -e "${file}" ] && cat <<EOF> "${file}"
<?xml version="1.0" encoding="UTF-8"?>
<FileZilla3 version="3.15.0.2" platform="*nix">
  <Settings>
    <Setting name="Default editor">0</Setting>
    <Setting name="Always use default editor">0</Setting>
  </Settings>
</FileZilla3>
fi
EOF
sed -i 's#^.*"Default editor".*#\t<Setting name="Default editor">2/usr/bin/gedit</Setting>#' "${file}"
[ -e /usr/bin/atom ] && sed -i 's#^.*"Default editor".*#\t<Setting name="Default editor">2/usr/bin/atom</Setting>#' "${file}"
sed -i 's#^.*"Always use default editor".*#\t<Setting name="Always use default editor">1</Setting>#' "${file}"


##### Install ncftp
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}ncftp${RESET} ~ CLI FTP client"
apt -y -qq install ncftp \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2


##### Install p7zip
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}p7zip${RESET} ~ CLI file extractor"
apt -y -qq install p7zip-full \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2


##### Install zip & unzip
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}zip${RESET} & ${GREEN}unzip${RESET} ~ CLI file extractors"
apt -y -qq install zip unzip \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2


##### Install file roller
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}file roller${RESET} ~ GUI file extractor"
apt -y -qq install file-roller \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
apt -y -qq install unace unrar rar unzip zip p7zip p7zip-full p7zip-rar \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2


##### Install VPN support
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}VPN${RESET} support for Network-Manager"
for FILE in network-manager-openvpn network-manager-pptp network-manager-vpnc network-manager-openconnect network-manager-iodine; do
  apt -y -qq install "${FILE}" \
    || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
done


##### Install hashid
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}hashid${RESET} ~ identify hash types"
apt -y -qq install hashid \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2


##### Install httprint
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}httprint${RESET} ~ GUI web server fingerprint"
apt -y -qq install httprint \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2


##### Install lbd
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}lbd${RESET} ~ load balancing detector"
apt -y -qq install lbd \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2


##### Install wafw00f
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}wafw00f${RESET} ~ WAF detector"
apt -y -qq install wafw00f \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2


##### Install aircrack-ng
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}Aircrack-ng${RESET} ~ Wi-Fi cracking suite"
apt -y -qq install aircrack-ng curl \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
#--- Setup hardware database
mkdir -p /etc/aircrack-ng/
(timeout 600 airodump-ng-oui-update 2>/dev/null) \
  || timeout 600 curl --progress -k -L -f "http://standards-oui.ieee.org/oui/oui.txt" > /etc/aircrack-ng/oui.txt
[ -e /etc/aircrack-ng/oui.txt ] \
  && (\grep "(hex)" /etc/aircrack-ng/oui.txt | sed 's/^[ \t]*//g;s/[ \t]*$//g' > /etc/aircrack-ng/airodump-ng-oui.txt)
[[ ! -f /etc/aircrack-ng/airodump-ng-oui.txt ]] \
  && echo -e ' '${RED}'[!]'${RESET}" Issue downloading oui.txt" 1>&2
#--- Setup alias
file=~/.bash_aliases; [ -e "${file}" ] && cp -n $file{,.bkup}   #/etc/bash.bash_aliases
([[ -e "${file}" && "$(tail -c 1 ${file})" != "" ]]) && echo >> "${file}"
grep -q '^## aircrack-ng' "${file}" 2>/dev/null \
  || echo -e '## aircrack-ng\nalias aircrack-ng="aircrack-ng -z"\n' >> "${file}"
grep -q '^## airodump-ng' "${file}" 2>/dev/null \
  || echo -e '## airodump-ng \nalias airodump-ng="airodump-ng --manufacturer --wps --uptime"\n' >> "${file}"    # aircrack-ng 1.2 rc2
#--- Apply new alias
source "${file}" || source ~/.zshrc


##### Install reaver (community fork)
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}reaver (community fork)${RESET} ~ WPS pin brute force + Pixie Attack"
apt -y -qq install reaver pixiewps \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2


##### Install bully
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}bully${RESET} ~ WPS pin brute force"
apt -y -qq install bully \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2


##### Install wifite
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}wifite${RESET} ~ automated Wi-Fi tool"
apt -y -qq install wifite \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2


##### Install vulscan script for nmap
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}vulscan script for nmap${RESET} ~ vulnerability scanner add-on"
apt -y -qq install nmap curl \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
mkdir -p /usr/share/nmap/scripts/vulscan/
timeout 300 curl --progress -k -L -f "http://www.computec.ch/projekte/vulscan/download/nmap_nse_vulscan-2.0.tar.gz" > /tmp/nmap_nse_vulscan.tar.gz \
  || echo -e ' '${RED}'[!]'${RESET}" Issue downloading file" 1>&2      #***!!! hardcoded version! Need to manually check for updates
gunzip /tmp/nmap_nse_vulscan.tar.gz
tar -xf /tmp/nmap_nse_vulscan.tar -C /usr/share/nmap/scripts/
#--- Fix permissions (by default its 0777)
chmod -R 0755 /usr/share/nmap/scripts/; find /usr/share/nmap/scripts/ -type f -exec chmod 0644 {} \;


##### Install unicornscan
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}unicornscan${RESET} ~ fast port scanner"
apt -y -qq install unicornscan \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2


##### Install onetwopunch
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}onetwopunch${RESET} ~ unicornscan & nmap wrapper"
apt -y -qq install git nmap unicornscan \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
git clone -q -b master https://github.com/superkojiman/onetwopunch.git /opt/onetwopunch-git/ \
  || echo -e ' '${RED}'[!] Issue when git cloning'${RESET} 1>&2
pushd /opt/onetwopunch-git/ >/dev/null
git pull -q
popd >/dev/null
#--- Add to path
mkdir -p /usr/local/bin/
file=/usr/local/bin/onetwopunch-git
cat <<EOF > "${file}" \
  || echo -e ' '${RED}'[!] Issue with writing file'${RESET} 1>&2
#!/bin/bash

cd /opt/onetwopunch-git/ && bash onetwopunch.sh "\$@"
EOF
chmod +x "${file}"


##### Install Gnmap-Parser (fork)
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}Gnmap-Parser (fork)${RESET} ~ Parse Nmap exports into various plain-text formats"
apt -y -qq install git \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
git clone -q -b master https://github.com/nullmode/gnmap-parser.git /opt/gnmap-parser-git/ \
  || echo -e ' '${RED}'[!] Issue when git cloning'${RESET} 1>&2
pushd /opt/gnmap-parser-git/ >/dev/null
git pull -q
popd >/dev/null
#--- Add to path
chmod +x /opt/gnmap-parser-git/gnmap-parser.sh
mkdir -p /usr/local/bin/
ln -sf /opt/gnmap-parser-git/gnmap-parser.sh /usr/local/bin/gnmap-parser-git


##### Install udp-proto-scanner
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}udp-proto-scanner${RESET} ~ common UDP port scanner"
apt -y -qq install curl \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
timeout 300 curl --progress -k -L -f "https://labs.portcullis.co.uk/download/udp-proto-scanner-1.1.tar.gz" -o /tmp/udp-proto-scanner.tar.gz \
  || echo -e ' '${RED}'[!]'${RESET}" Issue downloading udp-proto-scanner.tar.gz" 1>&2
gunzip /tmp/udp-proto-scanner.tar.gz
tar -xf /tmp/udp-proto-scanner.tar -C /opt/
mv -f /opt/udp-proto-scanner{-1.1,}
#--- Add to path
mkdir -p /usr/local/bin/
file=/usr/local/bin/udp-proto-scanner
cat <<EOF > "${file}" \
  || echo -e ' '${RED}'[!] Issue with writing file'${RESET} 1>&2
#!/bin/bash

cd /opt/udp-proto-scanner/ && perl udp-proto-scanner.pl "\$@"
EOF
chmod +x "${file}"


##### Install clusterd
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}clusterd${RESET} ~ clustered attack toolkit (JBoss, ColdFusion, WebLogic, Tomcat etc)"
apt -y -qq install clusterd \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2


##### Install webhandler
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}webhandler${RESET} ~ shell TTY handler"
apt -y -qq install webhandler \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
#--- Add to path
mkdir -p /usr/local/bin/
ln -sf /usr/bin/webhandler /usr/local/bin/wh


##### Install azazel
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}azazel${RESET} ~ Linux userland rootkit"
apt -y -qq install git \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
git clone -q -b master https://github.com/chokepoint/azazel.git /opt/azazel-git/ \
  || echo -e ' '${RED}'[!] Issue when git cloning'${RESET} 1>&2
pushd /opt/azazel-git/ >/dev/null
git pull -q
popd >/dev/null


##### Install Babadook
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}Babadook${RESET} ~ connection-less powershell backdoor"
apt -y -qq install git \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
git clone -q -b master https://github.com/jseidl/Babadook.git /opt/babadook-git/ \
  || echo -e ' '${RED}'[!] Issue when git cloning'${RESET} 1>&2
pushd /opt/babadook-git/ >/dev/null
git pull -q
popd >/dev/null


##### Install pupy
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}pupy${RESET} ~ Remote Administration Tool"
apt -y -qq install git \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
git clone -q -b master https://github.com/n1nj4sec/pupy.git /opt/pupy-git/ \
  || echo -e ' '${RED}'[!] Issue when git cloning'${RESET} 1>&2
pushd /opt/pupy-git/ >/dev/null
git pull -q
popd >/dev/null


##### Install gobuster
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}gobuster${RESET} ~ Directory/File/DNS busting tool"
apt -y -qq install git gobuster \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2


##### Install reGeorg
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}reGeorg${RESET} ~ pivot via web shells"
git clone -q -b master https://github.com/sensepost/reGeorg.git /opt/regeorg-git \
  || echo -e ' '${RED}'[!] Issue when git cloning'${RESET} 1>&2
pushd /opt/regeorg-git/ >/dev/null
git pull -q
popd >/dev/null
#--- Link to others
apt -y -qq install webshells \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
ln -sf /opt/reGeorg-git /usr/share/webshells/reGeorg


##### Install b374k (https://bugs.kali.org/view.php?id=1097)
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}b374k${RESET} ~ (PHP) web shell"
apt -y -qq install git php-cli \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
git clone -q -b master https://github.com/b374k/b374k.git /opt/b374k-git/ \
  || echo -e ' '${RED}'[!] Issue when git cloning'${RESET} 1>&2
pushd /opt/b374k-git/ >/dev/null
git pull -q
php index.php -o b374k.php -s
popd >/dev/null
#--- Link to others
apt -y -qq install webshells \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
ln -sf /opt/b374k-git /usr/share/webshells/php/b374k


##### Install adminer
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}adminer${RESET} ~ Database management in a single PHP file"
apt -y -qq install git \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
git clone -q -b master https://github.com/vrana/adminer.git /opt/adminer-git/ \
  || echo -e ' '${RED}'[!] Issue when git cloning'${RESET} 1>&2
pushd /opt/adminer-git/ >/dev/null
git pull -q
php compile.php 2>/dev/null
popd >/dev/null
#--- Link to others
apt -y -qq install webshells \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
file=$(find /opt/adminer-git/ -name adminer-*.php -type f -print -quit)
ln -sf "${file}" /usr/share/webshells/php/adminer.php


##### Install WeBaCoo
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}WeBaCoo${RESET} ~ Web backdoor cookie"
apt -y -qq install webacoo \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2


##### Install cmdsql
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}cmdsql${RESET} ~ (ASPX) web shell"
apt -y -qq install git \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
git clone -q -b master https://github.com/NetSPI/cmdsql.git /opt/cmdsql-git/ \
  || echo -e ' '${RED}'[!] Issue when git cloning'${RESET} 1>&2
pushd /opt/cmdsql-git/ >/dev/null
git pull -q
popd >/dev/null
#--- Link to others
apt -y -qq install webshells \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
ln -sf /opt/cmdsql-git /usr/share/webshells/aspx/cmdsql


##### Install JSP file browser
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}JSP file browser${RESET} ~ (JSP) web shell"
apt -y -qq install curl \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
mkdir -p /opt/jsp-filebrowser/
timeout 300 curl --progress -k -L -f "http://www.vonloesch.de/files/browser.zip" > /tmp/jsp.zip \
  || echo -e ' '${RED}'[!]'${RESET}" Issue downloading jsp.zip" 1>&2
unzip -q -o -d /opt/jsp-filebrowser/ /tmp/jsp.zip
#--- Link to others
apt -y -qq install webshells \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
ln -sf /opt/jsp-filebrowser /usr/share/webshells/jsp/jsp-filebrowser


##### Install htshells
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}htShells${RESET} ~ (htdocs/apache) web shells"
apt -y -qq install htshells \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2


##### Install python-pty-shells
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}python-pty-shells${RESET} ~ PTY shells"
apt -y -qq install git \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
git clone -q -b master https://github.com/infodox/python-pty-shells.git /opt/python-pty-shells-git/ \
  || echo -e ' '${RED}'[!] Issue when git cloning'${RESET} 1>&2
pushd /opt/python-pty-shells-git/ >/dev/null
git pull -q
popd >/dev/null


##### Install bridge-utils
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}bridge-utils${RESET} ~ Bridge network interfaces"
apt -y -qq install bridge-utils \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2


##### Install FruityWifi
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}FruityWifi${RESET} ~ Wireless network auditing tool"
apt -y -qq install fruitywifi \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
# URL: https://localhost:8443
if [[ -e /var/www/html/index.nginx-debian.html ]]; then
  grep -q '<title>Welcome to nginx on Debian!</title>' /var/www/html/index.nginx-debian.html \
    && echo 'Permission denied.' > /var/www/html/index.nginx-debian.html
fi


##### Install WPA2-HalfHandshake-Crack
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}WPA2-HalfHandshake-Crack${RESET} ~ Rogue AP for handshakes without a AP"
apt -y -qq install git \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
git clone -q -b master https://github.com/dxa4481/WPA2-HalfHandshake-Crack.git /opt/wpa2-halfhandshake-crack-git/ \
  || echo -e ' '${RED}'[!] Issue when git cloning'${RESET} 1>&2
pushd /opt/wpa2-halfhandshake-crack-git/ >/dev/null
git pull -q
popd >/dev/null


##### Install HT-WPS-Breaker
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}HT-WPS-Breaker${RESET} ~ Auto WPS tool"
apt -y -qq install git \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
git clone -q -b master https://github.com/SilentGhostX/HT-WPS-Breaker.git /opt/ht-wps-breaker-git/ \
  || echo -e ' '${RED}'[!] Issue when git cloning'${RESET} 1>&2
pushd /opt/ht-wps-breaker-git/ >/dev/null
git pull -q
popd >/dev/null


##### Install dot11decrypt
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}dot11decrypt${RESET} ~ On-the-fly WEP/WPA2 decrypter"
apt -y -qq install git \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
git clone -q -b master https://github.com/mfontanini/dot11decrypt.git /opt/dot11decrypt-git/ \
  || echo -e ' '${RED}'[!] Issue when git cloning'${RESET} 1>&2
pushd /opt/dot11decrypt-git/ >/dev/null
git pull -q
popd >/dev/null


##### Install mana toolkit
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}MANA toolkit${RESET} ~ Rogue AP for MITM Wi-Fi"
apt -y -qq install mana-toolkit \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
#--- Disable profile
a2dissite 000-mana-toolkit; a2ensite 000-default
#--- Setup alias
file=~/.bash_aliases; [ -e "${file}" ] && cp -n $file{,.bkup}   #/etc/bash.bash_aliases
([[ -e "${file}" && "$(tail -c 1 ${file})" != "" ]]) && echo >> "${file}"
grep -q '^## mana-toolkit' "${file}" 2>/dev/null \
  || (echo -e '## mana-toolkit\nalias mana-toolkit-start="a2ensite 000-mana-toolkit;a2dissite 000-default; systemctl restart apache2"' >> "${file}" \
    && echo -e 'alias mana-toolkit-stop="a2dissite 000-mana-toolkit; a2ensite 000-default; systemctl restart apache2"\n' >> "${file}" )
#--- Apply new alias
source "${file}" || source ~/.zshrc


##### Install wifiphisher
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}wifiphisher${RESET} ~ Automated Wi-Fi phishing"
apt -y -qq install git \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
git clone -q -b master https://github.com/sophron/wifiphisher.git /opt/wifiphisher-git/ \
  || echo -e ' '${RED}'[!] Issue when git cloning'${RESET} 1>&2
pushd /opt/wifiphisher-git/ >/dev/null
git pull -q
popd >/dev/null
#--- Add to path
mkdir -p /usr/local/bin/
file=/usr/local/bin/wifiphisher-git
cat <<EOF > "${file}" \
  || echo -e ' '${RED}'[!] Issue with writing file'${RESET} 1>&2
#!/bin/bash

cd /opt/wifiphisher-git/ && python wifiphisher.py "\$@"
EOF
chmod +x "${file}"


##### Install hostapd-wpe-extended
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}hostapd-wpe-extended${RESET} ~ Rogue AP for WPA-Enterprise"
apt -y -qq install git \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
git clone -q -b master https://github.com/NerdyProjects/hostapd-wpe-extended.git /opt/hostapd-wpe-extended-git/ \
  || echo -e ' '${RED}'[!] Issue when git cloning'${RESET} 1>&2
pushd /opt/hostapd-wpe-extended-git/ >/dev/null
git pull -q
popd >/dev/null


##### Install proxychains-ng (https://bugs.kali.org/view.php?id=2037)
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}proxychains-ng${RESET} ~ Proxifier"
apt -y -qq install git gcc \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
git clone -q -b master https://github.com/rofl0r/proxychains-ng.git /opt/proxychains-ng-git/ \
  || echo -e ' '${RED}'[!] Issue when git cloning'${RESET} 1>&2
pushd /opt/proxychains-ng-git/ >/dev/null
git pull -q
make -s clean
./configure --prefix=/usr --sysconfdir=/etc >/dev/null
make -s 2>/dev/null && make -s install   # bad, but it gives errors which might be confusing (still builds)
popd >/dev/null
#--- Add to path (with a 'better' name)
mkdir -p /usr/local/bin/
ln -sf /usr/bin/proxychains4 /usr/local/bin/proxychains-ng


##### Install httptunnel
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}httptunnel${RESET} ~ Tunnels data streams in HTTP requests"
apt -y -qq install http-tunnel \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2


##### Install sshuttle
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}sshuttle${RESET} ~ VPN over SSH"
apt -y -qq install sshuttle \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
#--- Example
#sshuttle --dns --remote root@123.9.9.9 0/0 -vv


##### Install pfi
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}pfi${RESET} ~ Port Forwarding Interceptor"
apt -y -qq install git \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
git clone -q -b master https://github.com/s7ephen/pfi.git /opt/pfi-git/ \
  || echo -e ' '${RED}'[!] Issue when git cloning'${RESET} 1>&2
pushd /opt/pfi-git/ >/dev/null
git pull -q
popd >/dev/null


##### Install icmpsh
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}icmpsh${RESET} ~ Reverse ICMP shell"
apt -y -qq install git \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
git clone -q -b master https://github.com/inquisb/icmpsh.git /opt/icmpsh-git/ \
  || echo -e ' '${RED}'[!] Issue when git cloning'${RESET} 1>&2
pushd /opt/icmpsh-git/ >/dev/null
git pull -q
popd >/dev/null


##### Install dnsftp
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}dnsftp${RESET} ~ Transfer files over DNS"
apt -y -qq install git \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
git clone -q -b master https://github.com/breenmachine/dnsftp.git /opt/dnsftp-git/ \
  || echo -e ' '${RED}'[!] Issue when git cloning'${RESET} 1>&2
pushd /opt/dnsftp-git/ >/dev/null
git pull -q
popd >/dev/null


##### Install iodine
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}iodine${RESET} ~ DNS tunnelling (IP over DNS)"
apt -y -qq install iodine \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
#iodined -f -P password1 10.0.0.1 dns.mydomain.com
#iodine -f -P password1 123.9.9.9 dns.mydomain.com; ssh -C -D 8081 root@10.0.0.1


##### Install dns2tcp
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}dns2tcp${RESET} ~ DNS tunnelling (TCP over DNS)"
apt -y -qq install dns2tcp \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
#--- Daemon
file=/etc/dns2tcpd.conf; [ -e "${file}" ] && cp -n $file{,.bkup};
cat <<EOF > "${file}" \
  || echo -e ' '${RED}'[!] Issue with writing file'${RESET} 1>&2
listen = 0.0.0.0
port = 53
user = nobody
chroot = /tmp
domain = dnstunnel.mydomain.com
key = password1
ressources = ssh:127.0.0.1:22
EOF
#--- Client
file=/etc/dns2tcpc.conf; [ -e "${file}" ] && cp -n $file{,.bkup};
cat <<EOF > "${file}" \
  || echo -e ' '${RED}'[!] Issue with writing file'${RESET} 1>&2
domain = dnstunnel.mydomain.com
key = password1
resources = ssh
local_port = 8000
debug_level=1
EOF
#--- Example
#dns2tcpd -F -d 1 -f /etc/dns2tcpd.conf
#dns2tcpc -f /etc/dns2tcpc.conf 178.62.206.227; ssh -C -D 8081 -p 8000 root@127.0.0.1


##### Install ptunnel
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}ptunnel${RESET} ~ ICMP tunnelling"
apt -y -qq install ptunnel \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
#--- Example
#ptunnel -x password1
#ptunnel -x password1 -p 123.9.9.9 -lp 8000 -da 127.0.0.1 -dp 22; ssh -C -D 8081 -p 8000 root@127.0.0.1


##### Install stunnel
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}stunnel${RESET} ~ SSL wrapper"
apt -y -qq install stunnel \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
#--- Remove from start up
systemctl disable stunnel4


##### Install zerofree
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}zerofree${RESET} ~ CLI nulls free blocks on a HDD"
apt -y -qq install zerofree \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
#--- Example
#fdisk -l
#zerofree -v /dev/sda1
#for i in $(mount | grep sda | grep ext | cut -b 9); do  mount -o remount,ro /dev/sda${i} && zerofree -v /dev/sda${i} && mount -o remount,rw /dev/sda${i}; done


##### Install gcc & multilib
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}gcc${RESET} & ${GREEN}multilibc${RESET} ~ compiling libraries"
for FILE in cc gcc g++ gcc-multilib make automake libc6 libc6-dev libc6-amd64 libc6-dev-amd64 libc6-i386 libc6-dev-i386 libc6-i686 libc6-dev-i686 build-essential dpkg-dev; do
  apt -y -qq install "${FILE}" 2>/dev/null
done


##### Install MinGW ~ cross compiling suite
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}MinGW${RESET} ~ cross compiling suite"
for FILE in mingw-w64 binutils-mingw-w64 gcc-mingw-w64 cmake   mingw-w64-dev mingw-w64-tools   gcc-mingw-w64-i686 gcc-mingw-w64-x86-64   mingw32; do
  apt -y -qq install "${FILE}" 2>/dev/null
done


##### Install WINE
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}WINE${RESET} ~ run Windows programs on *nix"
apt -y -qq install wine winetricks \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
#--- Using x64?
if [[ "$(uname -m)" == 'x86_64' ]]; then
  (( STAGE++ )); echo -e " ${GREEN}[i]${RESET} (${STAGE}/${TOTAL}) Configuring ${GREEN}WINE (x64)${RESET}"
  dpkg --add-architecture i386
  apt -qq update
  apt -y -qq install wine32 \
    || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
fi
#--- Run WINE for the first time
[ -e /usr/share/windows-binaries/whoami.exe ] && wine /usr/share/windows-binaries/whoami.exe &>/dev/null
#--- Setup default file association for .exe
file=~/.local/share/applications/mimeapps.list; [ -e "${file}" ] && cp -n $file{,.bkup}
([[ -e "${file}" && "$(tail -c 1 ${file})" != "" ]]) && echo >> "${file}"
echo -e 'application/x-ms-dos-executable=wine.desktop' >> "${file}"


##### Install MinGW (Windows) ~ cross compiling suite
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}MinGW (Windows)${RESET} ~ cross compiling suite"
apt -y -qq install wine curl unzip \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
timeout 300 curl --progress -k -L -f "http://sourceforge.net/projects/mingw/files/Installer/mingw-get/mingw-get-0.6.2-beta-20131004-1/mingw-get-0.6.2-mingw32-beta-20131004-1-bin.zip/download" > /tmp/mingw-get.zip \
  || echo -e ' '${RED}'[!]'${RESET}" Issue downloading mingw-get.zip" 1>&2       #***!!! hardcoded path!
mkdir -p ~/.wine/drive_c/MinGW/bin/
unzip -q -o -d ~/.wine/drive_c/MinGW/ /tmp/mingw-get.zip
pushd ~/.wine/drive_c/MinGW/ >/dev/null
for FILE in mingw32-base mingw32-gcc-g++ mingw32-gcc-objc; do   #msys-base
  wine ./bin/mingw-get.exe install "${FILE}" 2>&1 | grep -v 'If something goes wrong, please rerun with\|for more detailed debugging output'
done
popd >/dev/null
#--- Add to windows path
grep -q '^"PATH"=.*C:\\\\MinGW\\\\bin' ~/.wine/system.reg \
  || sed -i '/^"PATH"=/ s_"$_;C:\\\\MinGW\\\\bin"_' ~/.wine/system.reg


##### Downloading AccessChk.exe
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Downloading ${GREEN}AccessChk.exe${RESET} ~ Windows environment tester"
apt -y -qq install curl windows-binaries unzip \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
echo -n '[1/2]'; timeout 300 curl --progress -k -L -f "https://web.archive.org/web/20080530012252/http://live.sysinternals.com/accesschk.exe" > /usr/share/windows-binaries/accesschk_v5.02.exe \
  || echo -e ' '${RED}'[!]'${RESET}" Issue downloading accesschk_v5.02.exe" 1>&2   #***!!! hardcoded path!
echo -n '[2/2]'; timeout 300 curl --progress -k -L -f "https://download.sysinternals.com/files/AccessChk.zip" > /usr/share/windows-binaries/AccessChk.zip \
  || echo -e ' '${RED}'[!]'${RESET}" Issue downloading AccessChk.zip" 1>&2
unzip -q -o -d /usr/share/windows-binaries/ /usr/share/windows-binaries/AccessChk.zip
rm -f /usr/share/windows-binaries/{AccessChk.zip,Eula.txt}


##### Downloading PsExec.exe
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Downloading ${GREEN}PsExec.exe${RESET} ~ Pass The Hash 'phun'"
apt -y -qq install curl windows-binaries unzip unrar \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
echo -n '[1/2]'; timeout 300 curl --progress -k -L -f "https://download.sysinternals.com/files/PSTools.zip" > /tmp/pstools.zip \
  || echo -e ' '${RED}'[!]'${RESET}" Issue downloading pstools.zip" 1>&2
echo -n '[2/2]'; timeout 300 curl --progress -k -L -f "http://www.coresecurity.com/system/files/pshtoolkit_v1.4.rar" > /tmp/pshtoolkit.rar \
  || echo -e ' '${RED}'[!]'${RESET}" Issue downloading pshtoolkit.rar" 1>&2  #***!!! hardcoded path!
unzip -q -o -d /usr/share/windows-binaries/pstools/ /tmp/pstools.zip
unrar x -y /tmp/pshtoolkit.rar /usr/share/windows-binaries/ >/dev/null


##### Install Python (Windows via WINE)
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}Python (Windows)${RESET}"
echo -n '[1/2]'; timeout 300 curl --progress -k -L -f "https://www.python.org/ftp/python/2.7.9/python-2.7.9.msi" > /tmp/python.msi \
  || echo -e ' '${RED}'[!]'${RESET}" Issue downloading python.msi" 1>&2       #***!!! hardcoded path!
echo -n '[2/2]'; timeout 300 curl --progress -k -L -f "http://sourceforge.net/projects/pywin32/files/pywin32/Build%20219/pywin32-219.win32-py2.7.exe/download" > /tmp/pywin32.exe \
  || echo -e ' '${RED}'[!]'${RESET}" Issue downloading pywin32.exe" 1>&2      #***!!! hardcoded path!
wine msiexec /i /tmp/python.msi /qb 2>&1 | grep -v 'If something goes wrong, please rerun with\|for more detailed debugging output'
pushd /tmp/ >/dev/null
rm -rf "PLATLIB/" "SCRIPTS/"
unzip -q -o /tmp/pywin32.exe
cp -rf PLATLIB/* ~/.wine/drive_c/Python27/Lib/site-packages/
cp -rf SCRIPTS/* ~/.wine/drive_c/Python27/Scripts/
rm -rf "PLATLIB/" "SCRIPTS/"
popd >/dev/null


##### Install veil framework
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}veil-evasion framework${RESET} ~ bypassing anti-virus"
apt -y -qq install veil-evasion \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
#bash /usr/share/veil-evasion/setup/setup.sh --silent
mkdir -p /var/lib/veil-evasion/go/bin/
touch /etc/veil/settings.py
sed -i 's/TERMINAL_CLEAR=".*"/TERMINAL_CLEAR="false"/' /etc/veil/settings.py


##### Install OP packers
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}OP packers${RESET} ~ bypassing anti-virus"
apt -y -qq install upx-ucl curl \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
mkdir -p /opt/packers/
echo -n '[1/3]'; timeout 300 curl --progress -k -L -f "http://www.eskimo.com/~scottlu/win/cexe.exe" > /opt/packers/cexe.exe \
  || echo -e ' '${RED}'[!]'${RESET}" Issue downloading cexe.exe" 1>&2            #***!!! hardcoded version! Need to manually check for updates
echo -n '[2/3]'; timeout 300 curl --progress -k -L -f "http://www.farbrausch.de/~fg/kkrunchy/kkrunchy_023a2.zip" > /opt/packers/kkrunchy.zip \
  && unzip -q -o -d /opt/packers/ /opt/packers/kkrunchy.zip \
  || echo -e ' '${RED}'[!]'${RESET}" Issue downloading kkrunchy.zip" 1>&2        #***!!! hardcoded version! Need to manually check for updates
echo -n '[3/3]'; timeout 300 curl --progress -k -L -f "https://github.com/Veil-Framework/Veil-Evasion/blob/master/tools/pescrambler/PEScrambler.exe" > /opt/packers/PEScrambler \
  || echo -e ' '${RED}'[!]'${RESET}" Issue downloading PEScrambler.exe" 1>&2     #***!!! hardcoded version! Need to manually check for updates
#*** ??????? Need to make a bash script like hyperion...
#--- Link to others
apt -y -qq install windows-binaries \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
ln -sf /opt/packers/ /usr/share/windows-binaries/packers


##### Install hyperion
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}hyperion${RESET} ~ bypassing anti-virus"
apt -y -qq install unzip windows-binaries \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
unzip -q -o -d /usr/share/windows-binaries/ $(find /usr/share/windows-binaries/ -name "Hyperion-*.zip" -type f -print -quit)
#--- Compile
i686-w64-mingw32-g++ -static-libgcc -static-libstdc++ \
  /usr/share/windows-binaries/Hyperion-1.0/Src/Crypter/*.cpp \
  -o /usr/share/windows-binaries/Hyperion-1.0/Src/Crypter/bin/crypter.exe
ln -sf /usr/share/windows-binaries/Hyperion-1.0/Src/Crypter/bin/crypter.exe /usr/share/windows-binaries/Hyperion-1.0/crypter.exe                                                            #***!!! hardcoded path!
wine ~/.wine/drive_c/MinGW/bin/g++.exe /usr/share/windows-binaries/Hyperion-1.0/Src/Crypter/*.cpp \
  -o /usr/share/windows-binaries/hyperion.exe 2>&1 \
  | grep -v 'If something goes wrong, please rerun with\|for more detailed debugging output'
#--- Add to path
mkdir -p /usr/local/bin/
file=/usr/local/bin/hyperion
cat <<EOF > "${file}" \
  || echo -e ' '${RED}'[!] Issue with writing file'${RESET} 1>&2
#!/bin/bash

## Note: This is far from perfect...

CWD=\$(pwd)/
BWD="?"

## Using full path?
[ -e "/\${1}" ] && BWD=""

## Using relative path?
[ -e "./\${1}" ] && BWD="\${CWD}"

## Can't find input file!
[[ "\${BWD}" == "?" ]] && echo -e ' '${RED}'[!]'${RESET}' Cant find \$1. Quitting...' && exit

## The magic!
cd /usr/share/windows-binaries/Hyperion-1.0/
$(which wine) ./Src/Crypter/bin/crypter.exe \${BWD}\${1} output.exe

## Restore our path
cd \${CWD}/
sleep 1s

## Move the output file
mv -f /usr/share/windows-binaries/Hyperion-1.0/output.exe \${2}

## Generate file hashes
for FILE in \${1} \${2}; do
  echo "[i] \$(md5sum \${FILE})"
done
EOF
chmod +x "${file}"


##### Install shellter
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}shellter${RESET} ~ dynamic shellcode injector"
apt -y -qq install shellter \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2


##### Install the backdoor factory
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}Backdoor Factory${RESET} ~ bypassing anti-virus"
apt -y -qq install backdoor-factory \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2


##### Install Backdoor Factory Proxy (BDFProxy)
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}Backdoor Factory Proxy (BDFProxy)${RESET} ~ patches binaries files during a MITM"
apt -y -qq install bdfproxy \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2


##### Install BetterCap
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}BetterCap${RESET} ~ MITM framework"
apt -y -qq install git ruby-dev libpcap-dev \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
git clone -q -b master https://github.com/evilsocket/bettercap.git /opt/bettercap-git/ \
  || echo -e ' '${RED}'[!] Issue when git cloning'${RESET} 1>&2
pushd /opt/bettercap-git/ >/dev/null
git pull -q
gem build bettercap.gemspec
gem install bettercap*.gem
popd >/dev/null


##### Install mitmf
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}MITMf${RESET} ~ framework for MITM attacks"
apt -y -qq install mitmf \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2


##### Install responder
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}Responder${RESET} ~ rogue server"
apt -y -qq install responder \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2


##### Install seclist
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}seclist${RESET} ~ multiple types of (word)lists (and similar things)"
apt -y -qq install seclists \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
#--- Link to others
apt -y -qq install wordlists \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
[ -e /usr/share/seclists ] \
  && ln -sf /usr/share/seclists /usr/share/wordlists/seclists

#  https://github.com/fuzzdb-project/fuzzdb


##### Update wordlists
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Updating ${GREEN}wordlists${RESET} ~ collection of wordlists"
apt -y -qq install wordlists curl \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
#--- Extract rockyou wordlist
[ -e /usr/share/wordlists/rockyou.txt.gz ] \
  && gzip -dc < /usr/share/wordlists/rockyou.txt.gz > /usr/share/wordlists/rockyou.txt
#--- Add 10,000 Top/Worst/Common Passwords
mkdir -p /usr/share/wordlists/
(curl --progress -k -L -f "http://xato.net/files/10k most common.zip" > /tmp/10kcommon.zip 2>/dev/null \
  || curl --progress -k -L -f "http://download.g0tmi1k.com/wordlists/common-10k_most_common.zip" > /tmp/10kcommon.zip 2>/dev/null) \
  || echo -e ' '${RED}'[!]'${RESET}" Issue downloading 10kcommon.zip" 1>&2
unzip -q -o -d /usr/share/wordlists/ /tmp/10kcommon.zip 2>/dev/null   #***!!! hardcoded version! Need to manually check for updates
mv -f /usr/share/wordlists/10k{\ most\ ,_most_}common.txt
#--- Linking to more - folders
[ -e /usr/share/dirb/wordlists ] \
  && ln -sf /usr/share/dirb/wordlists /usr/share/wordlists/dirb
#--- Extract sqlmap wordlist
unzip -o -d /usr/share/sqlmap/txt/ /usr/share/sqlmap/txt/wordlist.zip
ln -sf /usr/share/sqlmap/txt/wordlist.txt /usr/share/wordlists/sqlmap.txt
#--- Not enough? Want more? Check below!
#apt search wordlist
#find / \( -iname '*wordlist*' -or -iname '*passwords*' \) #-exec ls -l {} \;


##### Install apt-file
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}apt-file${RESET} ~ which package includes a specific file"
apt -y -qq install apt-file \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
apt-file update


##### Install apt-show-versions
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}apt-show-versions${RESET} ~ which package version in repo"
apt -y -qq install apt-show-versions \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2


##### Install Babel scripts
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}Babel scripts${RESET} ~ post exploitation scripts"
apt -y -qq install git \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
git clone -q -b master https://github.com/attackdebris/babel-sf.git /opt/babel-sf-git/ \
  || echo -e ' '${RED}'[!] Issue when git cloning'${RESET} 1>&2
pushd /opt/babel-sf-git/ >/dev/null
git pull -q
popd >/dev/null


##### Install checksec
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}checksec${RESET} ~ check *nix OS for security features"
apt -y -qq install curl \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
mkdir -p /usr/share/checksec/
file=/usr/share/checksec/checksec.sh
timeout 300 curl --progress -k -L -f "http://www.trapkit.de/tools/checksec.sh" > "${file}" \
  || echo -e ' '${RED}'[!]'${RESET}" Issue downloading checksec.sh" 1>&2     #***!!! hardcoded patch
chmod +x "${file}"


##### Install shellconv
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}shellconv${RESET} ~ shellcode disassembler"
apt -y -qq install git \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
git clone -q -b master https://github.com/hasherezade/shellconv.git /opt/shellconv-git/ \
  || echo -e ' '${RED}'[!] Issue when git cloning'${RESET} 1>&2
pushd /opt/shellconv-git/ >/dev/null
git pull -q
popd >/dev/null
#--- Add to path
mkdir -p /usr/local/bin/
file=/usr/local/bin/shellconv-git
cat <<EOF > "${file}" \
  || echo -e ' '${RED}'[!] Issue with writing file'${RESET} 1>&2
#!/bin/bash

cd /opt/shellconv-git/ && python shellconv.py "\$@"
EOF
chmod +x "${file}"


##### Install bless
#(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}bless${RESET} ~ GUI hex editor"
#apt -y -qq install bless \
#  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2


##### Install dhex
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}dhex${RESET} ~ CLI hex compare"
apt -y -qq install dhex \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2


##### Install firmware-mod-kit
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}firmware-mod-kit${RESET} ~ customize firmware"
apt -y -qq install firmware-mod-kit \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2


##### Install lnav
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}lnav${RESET} ~ CLI log veiwer"
apt -y -qq install lnav \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2


##### Install commix
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}commix${RESET} ~ automatic command injection"
apt -y -qq install commix \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2


##### Install fimap
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}fimap${RESET} ~ automatic LFI/RFI tool"
apt -y -qq install fimap \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2


##### Install smbmap
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}smbmap${RESET} ~ SMB enumeration tool"
apt -y -qq install smbmap \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2


##### Install smbspider
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}smbspider${RESET} ~ search network shares"
apt -y -qq install git \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
git clone -q -b master https://github.com/T-S-A/smbspider.git /opt/smbspider-git/ \
  || echo -e ' '${RED}'[!] Issue when git cloning'${RESET} 1>&2
pushd /opt/smbspider-git/ >/dev/null
git pull -q
popd >/dev/null


##### Install CrackMapExec
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}CrackMapExec${RESET} ~ Swiss army knife for Windows environments"
apt -y -qq install git \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
git clone -q -b master https://github.com/byt3bl33d3r/CrackMapExec.git /opt/crackmapexec-git/ \
  || echo -e ' '${RED}'[!] Issue when git cloning'${RESET} 1>&2
pushd /opt/crackmapexec-git/ >/dev/null
git pull -q
popd >/dev/null


##### Install credcrack
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}credcrack${RESET} ~ credential harvester via Samba"
apt -y -qq install git \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
git clone -q -b master https://github.com/gojhonny/CredCrack.git /opt/credcrack-git/ \
  || echo -e ' '${RED}'[!] Issue when git cloning'${RESET} 1>&2
pushd /opt/credcrack-git/ >/dev/null
git pull -q
popd >/dev/null


##### Install Empire
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}Empire${RESET} ~ PowerShell post-exploitation"
apt -y -qq install git \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
git clone -q -b master https://github.com/PowerShellEmpire/Empire.git /opt/empire-git/ \
  || echo -e ' '${RED}'[!] Issue when git cloning'${RESET} 1>&2
pushd /opt/empire-git/ >/dev/null
git pull -q
popd >/dev/null


##### Install wig (https://bugs.kali.org/view.php?id=1932)
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}wig${RESET} ~ web application detection"
apt -y -qq install git \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
git clone -q -b master https://github.com/jekyc/wig.git /opt/wig-git/ \
  || echo -e ' '${RED}'[!] Issue when git cloning'${RESET} 1>&2
pushd /opt/wig-git/ >/dev/null
git pull -q
popd >/dev/null
#--- Add to path
mkdir -p /usr/local/bin/
file=/usr/local/bin/wig-git
cat <<EOF > "${file}" \
  || echo -e ' '${RED}'[!] Issue with writing file'${RESET} 1>&2
#!/bin/bash

cd /opt/wig-git/ && python wig.py "\$@"
EOF
chmod +x "${file}"


##### Install CMSmap
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}CMSmap${RESET} ~ CMS detection"
apt -y -qq install git \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
git clone -q -b master https://github.com/Dionach/CMSmap.git /opt/cmsmap-git/ \
  || echo -e ' '${RED}'[!] Issue when git cloning'${RESET} 1>&2
pushd /opt/cmsmap-git/ >/dev/null
git pull -q
popd >/dev/null
#--- Add to path
mkdir -p /usr/local/bin/
file=/usr/local/bin/cmsmap-git
cat <<EOF > "${file}" \
  || echo -e ' '${RED}'[!] Issue with writing file'${RESET} 1>&2
#!/bin/bash

cd /opt/cmsmap-git/ && python cmsmap.py "\$@"
EOF
chmod +x "${file}"


##### Install droopescan
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}DroopeScan${RESET} ~ Drupal vulnerability scanner"
apt -y -qq install git \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
git clone -q -b master https://github.com/droope/droopescan.git /opt/droopescan-git/ \
  || echo -e ' '${RED}'[!] Issue when git cloning'${RESET} 1>&2
pushd /opt/droopescan-git/ >/dev/null
git pull -q
popd >/dev/null
#--- Add to path
mkdir -p /usr/local/bin/
file=/usr/local/bin/droopescan-git
cat <<EOF > "${file}" \
  || echo -e ' '${RED}'[!] Issue with writing file'${RESET} 1>&2
#!/bin/bash

cd /opt/droopescan-git/ && python droopescan "\$@"
EOF
chmod +x "${file}"


##### Install BeEF XSS
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}BeEF XSS${RESET} ~ XSS framework"
apt -y -qq install beef-xss \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
#--- Configure beef
file=/usr/share/beef-xss/config.yaml; [ -e "${file}" ] && cp -n $file{,.bkup}
username="root"
password="toor"
sed -i 's/user:.*".*"/user:   "'${username}'"/' "${file}"
sed -i 's/passwd:.*".*"/passwd:  "'${password}'"/'  "${file}"
echo -e " ${YELLOW}[i]${RESET} BeEF username: ${username}"
echo -e " ${YELLOW}[i]${RESET} BeEF password: ${password}   ***${BOLD}CHANGE THIS ASAP${RESET}***"
echo -e " ${YELLOW}[i]${RESET} Edit: /usr/share/beef-xss/config.yaml"
#--- Example
#<script src="http://192.168.155.175:3000/hook.js" type="text/javascript"></script>


##### Install patator (GIT)
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}patator${RESET} (GIT) ~ brute force"
apt -y -qq install git \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
git clone -q -b master https://github.com/lanjelot/patator.git /opt/patator-git/ \
  || echo -e ' '${RED}'[!] Issue when git cloning'${RESET} 1>&2
pushd /opt/patator-git/ >/dev/null
git pull -q
popd >/dev/null
#--- Add to path
mkdir -p /usr/local/bin/
file=/usr/local/bin/patator-git
cat <<EOF > "${file}" \
  || echo -e ' '${RED}'[!] Issue with writing file'${RESET} 1>&2
#!/bin/bash

cd /opt/patator-git/ && python patator.py "\$@"
EOF
chmod +x "${file}"


##### Install crowbar
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}crowbar${RESET} ~ brute force"
apt -y -qq install git openvpn freerdp-x11 vncviewer \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
git clone -q -b master https://github.com/galkan/crowbar.git /opt/crowbar-git/ \
  || echo -e ' '${RED}'[!] Issue when git cloning'${RESET} 1>&2
pushd /opt/crowbar-git/ >/dev/null
git pull -q
popd >/dev/null
#--- Add to path
mkdir -p /usr/local/bin/
file=/usr/local/bin/crowbar-git
cat <<EOF > "${file}" \
  || echo -e ' '${RED}'[!] Issue with writing file'${RESET} 1>&2
#!/bin/bash

cd /opt/crowbar-git/ && python crowbar.py "\$@"
EOF
chmod +x "${file}"


##### Install xprobe
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}xprobe${RESET} ~ OS fingerprinting"
apt -y -qq install xprobe \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2


##### Install p0f
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}p0f${RESET} ~ OS fingerprinting"
apt -y -qq install p0f \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
#p0f -i eth0 -p & curl 192.168.0.1


##### Install nbtscan ~ http://unixwiz.net/tools/nbtscan.html vs http://inetcat.org/software/nbtscan.html (see http://sectools.org/tool/nbtscan/)
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}nbtscan${RESET} (${GREEN}inetcat${RESET} & ${GREEN}unixwiz${RESET}) ~ netbios scanner"
#--- inetcat - 1.5.x
apt -y -qq install nbtscan \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
#--- Examples
#nbtscan -r 192.168.0.1/24
#nbtscan -r 192.168.0.1/24 -v
#--- unixwiz - 1.0.x
mkdir -p /usr/local/src/nbtscan-unixwiz/
timeout 300 curl --progress -k -L -f "http://unixwiz.net/tools/nbtscan-source-1.0.35.tgz" > /usr/local/src/nbtscan-unixwiz/nbtscan.tgz \
  || echo -e ' '${RED}'[!]'${RESET}" Issue downloading nbtscan.tgz" 1>&2    #***!!! hardcoded version! Need to manually check for updates
tar -zxf /usr/local/src/nbtscan-unixwiz/nbtscan.tgz -C /usr/local/src/nbtscan-unixwiz/
pushd /usr/local/src/nbtscan-unixwiz/ >/dev/null
make -s clean;
make -s 2>/dev/null    # bad, I know
popd >/dev/null
#--- Add to path
mkdir -p /usr/local/bin/
ln -sf /usr/local/src/nbtscan-unixwiz/nbtscan /usr/local/bin/nbtscan-uw
#--- Examples
#nbtscan-uw -f 192.168.0.1/24


##### Setup tftp client & server
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Setting up ${GREEN}tftp client${RESET} & ${GREEN}server${RESET} ~ file transfer methods"
apt -y -qq install tftp atftpd \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
#--- Configure atftpd
file=/etc/default/atftpd; [ -e "${file}" ] && cp -n $file{,.bkup}
echo -e 'USE_INETD=false\nOPTIONS="--tftpd-timeout 300 --retry-timeout 5 --maxthread 100 --verbose=5 --daemon --port 69 /var/tftp"' > "${file}"
mkdir -p /var/tftp/
chown -R nobody\:root /var/tftp/
chmod -R 0755 /var/tftp/
#--- Setup alias
file=~/.bash_aliases; [ -e "${file}" ] && cp -n $file{,.bkup}   #/etc/bash.bash_aliases
([[ -e "${file}" && "$(tail -c 1 ${file})" != "" ]]) && echo >> "${file}"
grep -q '^## tftp' "${file}" 2>/dev/null \
  || echo -e '## tftp\nalias tftproot="cd /var/tftp/"\n' >> "${file}"
#--- Apply new alias
source "${file}" || source ~/.zshrc
#--- Remove from start up
systemctl disable atftpd
#--- Disabling IPv6 can help
#echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6
#echo 1 > /proc/sys/net/ipv6/conf/default/disable_ipv6


##### Install Pure-FTPd
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}Pure-FTPd${RESET} ~ FTP server/file transfer method"
apt -y -qq install pure-ftpd \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
#--- Setup pure-ftpd
mkdir -p /var/ftp/
groupdel ftpgroup 2>/dev/null;
groupadd ftpgroup
userdel ftp 2>/dev/null;
useradd -r -M -d /var/ftp/ -s /bin/false -c "FTP user" -g ftpgroup ftp
chown -R ftp\:ftpgroup /var/ftp/
chmod -R 0755 /var/ftp/
pure-pw userdel ftp 2>/dev/null;
echo -e '\n' | pure-pw useradd ftp -u ftp -d /var/ftp/
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
echo "30768 31768" > /etc/pure-ftpd/conf/PassivePortRange              #cat /proc/sys/net/ipv4/ip_local_port_range
echo "/etc/pure-ftpd/welcome.msg" > /etc/pure-ftpd/conf/FortunesFile   #/etc/motd
echo "FTP" > /etc/pure-ftpd/welcome.msg
ln -sf /etc/pure-ftpd/conf/PureDB /etc/pure-ftpd/auth/50pure
#--- 'Better' MOTD
apt -y -qq install cowsay \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
echo "moo" | /usr/games/cowsay > /etc/pure-ftpd/welcome.msg
echo -e " ${YELLOW}[i]${RESET} Pure-FTPd username: anonymous"
echo -e " ${YELLOW}[i]${RESET} Pure-FTPd password: anonymous"
#--- Apply settings
systemctl restart pure-ftpd
#--- Setup alias
file=~/.bash_aliases; [ -e "${file}" ] && cp -n $file{,.bkup}   #/etc/bash.bash_aliases
([[ -e "${file}" && "$(tail -c 1 ${file})" != "" ]]) && echo >> "${file}"
grep -q '^## ftp' "${file}" 2>/dev/null \
  || echo -e '## ftp\nalias ftproot="cd /var/ftp/"\n' >> "${file}"
#--- Apply new alias
source "${file}" || source ~/.zshrc
#--- Remove from start up
systemctl disable pure-ftpd


##### Install samba
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}samba${RESET} ~ file transfer method"
#--- Installing samba
apt -y -qq install samba \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
apt -y -qq install cifs-utils \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
#--- Create samba user
groupdel smbgroup 2>/dev/null;
groupadd smbgroup
userdel samba 2>/dev/null;
useradd -r -M -d /nonexistent -s /bin/false -c "Samba user" -g smbgroup samba
#--- Use the samba user
file=/etc/samba/smb.conf; [ -e "${file}" ] && cp -n $file{,.bkup}
sed -i 's/guest account = .*/guest account = samba/' "${file}" 2>/dev/null
grep -q 'guest account' "${file}" 2>/dev/null \
  || sed -i 's#\[global\]#\[global\]\n   guest account = samba#' "${file}"
#--- Setup samba paths
grep -q '^\[shared\]' "${file}" 2>/dev/null \
  || cat <<EOF >> "${file}"

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
chmod -R 0755 /var/samba/
#--- Bug fix
touch /etc/printcap
#--- Check
#systemctl restart samba
#smbclient -L \\127.0.0.1 -N
#mount -t cifs -o guest //127.0.0.1/share /mnt/smb     mkdir -p /mnt/smb
#--- Disable samba at startup
systemctl stop samba
systemctl disable samba
echo -e " ${YELLOW}[i]${RESET} Samba username: guest"
echo -e " ${YELLOW}[i]${RESET} Samba password: <blank>"
#--- Setup alias
file=~/.bash_aliases; [ -e "${file}" ] && cp -n $file{,.bkup}   #/etc/bash.bash_aliases
([[ -e "${file}" && "$(tail -c 1 ${file})" != "" ]]) && echo >> "${file}"
grep -q '^## smb' "${file}" 2>/dev/null \
  || echo -e '## smb\nalias smb="cd /var/samba/"\n#alias smbroot="cd /var/samba/"\n' >> "${file}"
#--- Apply new alias
source "${file}" || source ~/.zshrc


##### Install apache2 & php
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}apache2${RESET} & ${GREEN}php${RESET} ~ web server"
apt -y -qq install apache2 php php-cli php-curl \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
touch /var/www/html/favicon.ico
grep -q '<title>Apache2 Debian Default Page: It works</title>' /var/www/html/index.html 2>/dev/null \
  && rm -f /var/www/html/index.html \
  && echo '<?php echo "Access denied for " . $_SERVER["REMOTE_ADDR"]; ?>' > /var/www/html/index.php \
  && echo -e 'User-agent: *n\Disallow: /\n' > /var/www/html/robots.txt
#--- Setup alias
file=~/.bash_aliases; [ -e "${file}" ] && cp -n $file{,.bkup}   #/etc/bash.bash_aliases
([[ -e "${file}" && "$(tail -c 1 ${file})" != "" ]]) && echo >> "${file}"
grep -q '^## www' "${file}" 2>/dev/null \
  || echo -e '## www\nalias wwwroot="cd /var/www/html/"\n' >> "${file}"
#--- Apply new alias
source "${file}" || source ~/.zshrc


##### Install mysql
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}MySQL${RESET} ~ database"
apt -y -qq install mysql-server \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
echo -e " ${YELLOW}[i]${RESET} MySQL username: root"
echo -e " ${YELLOW}[i]${RESET} MySQL password: <blank>   ***${BOLD}CHANGE THIS ASAP${RESET}***"
[[ -e ~/.my.cnf ]] \
  || cat <<EOF > ~/.my.cnf
[client]
user=root
host=localhost
password=
EOF


##### Install rsh-client
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}rsh-client${RESET} ~ remote shell connections"
apt -y -qq install rsh-client \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2


##### Install sshpass
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}sshpass${RESET} ~ automating SSH connections"
apt -y -qq install sshpass \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2


##### Install DBeaver
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}DBeaver${RESET} ~ GUI DB manager"
apt -y -qq install curl \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
arch="i386"
[[ "$(uname -m)" == "x86_64" ]] && arch="amd64"
timeout 300 curl --progress -k -L -f "http://dbeaver.jkiss.org/files/dbeaver-ce_latest_${arch}.deb" > /tmp/dbeaver.deb \
  || echo -e ' '${RED}'[!]'${RESET}" Issue downloading dbeaver.deb" 1>&2   #***!!! hardcoded version! Need to manually check for updates
if [ -e /tmp/dbeaver.deb ]; then
  dpkg -i /tmp/dbeaver.deb
  #--- Add to path
  mkdir -p /usr/local/bin/
  ln -sf /usr/share/dbeaver/dbeaver /usr/local/bin/dbeaver
fi


##### Install ashttp
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}ashttp${RESET} ~ terminal via the web"
apt -y -qq install git \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
git clone -q -b master https://github.com/JulienPalard/ashttp.git /opt/ashttp-git/ \
  || echo -e ' '${RED}'[!] Issue when git cloning'${RESET} 1>&2
pushd /opt/ashttp-git/ >/dev/null
git pull -q
popd >/dev/null


##### Install gotty
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Installing ${GREEN}gotty${RESET} ~ terminal via the web"
apt -y -qq install git \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
git clone -q -b master https://github.com/yudai/gotty.git /opt/gotty-git/ \
  || echo -e ' '${RED}'[!] Issue when git cloning'${RESET} 1>&2
pushd /opt/gotty-git/ >/dev/null
git pull -q
popd >/dev/null


##### Preparing a jail ~ http://allanfeid.com/content/creating-chroot-jail-ssh-access // http://www.cyberciti.biz/files/lighttpd/l2chroot.txt
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Preparing up a ${GREEN}jail${RESET} ~ testing environment"
apt -y -qq install debootstrap curl \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2


##### Setup SSH
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) Setting up ${GREEN}SSH${RESET} ~ CLI access"
apt -y -qq install openssh-server \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
#--- Wipe current keys
rm -f /etc/ssh/ssh_host_*
find ~/.ssh/ -type f ! -name authorized_keys -delete 2>/dev/null
#--- Generate new keys
ssh-keygen -b 4096 -t rsa1 -f /etc/ssh/ssh_host_key -P "" >/dev/null
ssh-keygen -b 4096 -t rsa -f /etc/ssh/ssh_host_rsa_key -P "" >/dev/null
ssh-keygen -b 1024 -t dsa -f /etc/ssh/ssh_host_dsa_key -P "" >/dev/null
ssh-keygen -b 521 -t ecdsa -f /etc/ssh/ssh_host_ecdsa_key -P "" >/dev/null
ssh-keygen -b 4096 -t rsa -f ~/.ssh/id_rsa -P "" >/dev/null
#--- Change MOTD
apt -y -qq install cowsay \
  || echo -e ' '${RED}'[!] Issue with apt install'${RESET} 1>&2
echo "Moo" | /usr/games/cowsay > /etc/motd
#--- Change SSH settings
file=/etc/ssh/sshd_config; [ -e "${file}" ] && cp -n $file{,.bkup}
sed -i 's/^PermitRootLogin .*/PermitRootLogin yes/g' "${file}"      # Accept password login (overwrite Debian 8+'s more secure default option...)
sed -i 's/^#AuthorizedKeysFile /AuthorizedKeysFile /g' "${file}"    # Allow for key based login
#sed -i 's/^Port .*/Port 2222/g' "${file}"
#--- Enable ssh at startup
#systemctl enable ssh
#--- Setup alias (handy for 'zsh: correct 'ssh' to '.ssh' [nyae]? n')
file=~/.bash_aliases; [ -e "${file}" ] && cp -n $file{,.bkup}   #/etc/bash.bash_aliases
([[ -e "${file}" && "$(tail -c 1 ${file})" != "" ]]) && echo >> "${file}"
grep -q '^## ssh' "${file}" 2>/dev/null \
  || echo -e '## ssh\nalias ssh-start="systemctl restart ssh"\nalias ssh-stop="systemctl stop ssh"\n' >> "${file}"
#--- Apply new alias
source "${file}" || source ~/.zshrc



##### Custom insert point



##### Clean the system
(( STAGE++ )); echo -e "\n\n ${GREEN}[+]${RESET} (${STAGE}/${TOTAL}) ${GREEN}Cleaning${RESET} the system"
#--- Clean package manager
for FILE in clean autoremove; do apt -y -qq "${FILE}"; done
apt -y -qq purge $(dpkg -l | tail -n +6 | egrep -v '^(h|i)i' | awk '{print $2}')   # Purged packages
#--- Update slocate database
updatedb
#--- Reset folder location
cd ~/ &>/dev/null
#--- Remove any history files (as they could contain sensitive info)
history -cw 2>/dev/null
for i in $(cut -d: -f6 /etc/passwd | sort -u); do
  [ -e "${i}" ] && find "${i}" -type f -name '.*_history' -delete
done


##### Time taken
finish_time=$(date +%s)
echo -e "\n\n ${YELLOW}[i]${RESET} Time (roughly) taken: ${YELLOW}$(( $(( finish_time - start_time )) / 60 )) minutes${RESET}"
echo -e " ${YELLOW}[i]${RESET} Stages skipped: $(( TOTAL-STAGE ))"


#-Done-----------------------------------------------------------------#


##### Done!
echo -e "\n ${YELLOW}[i]${RESET} Don't forget to:"
echo -e " ${YELLOW}[i]${RESET} + Check the above output (Did everything install? Any errors? (${RED}HINT: What's in RED${RESET}?)"
echo -e " ${YELLOW}[i]${RESET} + Manually install: Nessus, Nexpose, and/or Metasploit Community"
echo -e " ${YELLOW}[i]${RESET} + Agree/Accept to: Maltego, OWASP ZAP, w3af, PyCharm, etc"
echo -e " ${YELLOW}[i]${RESET} + Setup git:   ${YELLOW}git config --global user.name <name>;git config --global user.email <email>${RESET}"
echo -e " ${YELLOW}[i]${RESET} + ${BOLD}Change default passwords${RESET}: PostgreSQL/MSF, MySQL, OpenVAS, BeEF XSS, etc"
echo -e " ${YELLOW}[i]${RESET} + ${YELLOW}Reboot${RESET}"
(dmidecode | grep -iq virtual) \
  && echo -e " ${YELLOW}[i]${RESET} + Take a snapshot   (Virtual machine detected)"

echo -e '\n'${BLUE}'[*]'${RESET}' '${BOLD}'Done!'${RESET}'\n\a'
exit 0
