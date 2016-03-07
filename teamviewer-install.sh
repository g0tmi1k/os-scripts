#!/bin/bash
##### (Cosmetic) Colour output
RED="\033[01;31m"      # Issues/Errors
GREEN="\033[01;32m"    # Success
YELLOW="\033[01;33m"   # Warnings/Information
BLUE="\033[01;34m"     # Heading
BOLD="\033[01;01m"     # Highlight
RESET="\033[00m"       # Normal

##### Check Internet access
echo -e "\n ${GREEN}[+]${RESET} Checking ${GREEN}Internet access${RESET}"
for i in {1..10}; do ping -c 1 -W ${i} www.google.com &>/dev/null && break; done
if [[ "$?" -ne 0 ]]; then
  echo -e ' '${RED}'[!]'${RESET}" ${RED}Possible DNS issues${RESET}(?). Trying DHCP 'fix'" 1>&2
  chattr -i /etc/resolv.conf 2>/dev/null
  dhclient -r
  route delete default gw 192.168.155.1 2>/dev/null
  dhclient
  sleep 15s
  _TMP=true
  _CMD="$(ping -c 1 8.8.8.8 &>/dev/null)"
  if [[ "$?" -ne 0 && "$_TMP" == true ]]; then
    _TMP=false
    echo -e ' '${RED}'[!]'${RESET}" ${RED}No Internet access${RESET}. Manually fix the issue & re-run the script" 1>&2
  fi
  _CMD="$(ping -c 1 www.google.com &>/dev/null)"
  if [[ "$?" -ne 0 && "$_TMP" == true ]]; then
    _TMP=false
    echo -e ' '${RED}'[!]'${RESET}" ${RED}Possible DNS issues${RESET}(?). Manually fix the issue & re-run the script" 1>&2
  fi
  if [[ "$_TMP" == false ]]; then
    (dmidecode | grep -iq -e vmware -e virtualbox -e qemu -e xen -e microsoft) && echo -e " ${YELLOW}[i]${RESET} VM Detected. ${YELLOW}Try switching network adapter mode${RESET} (NAT/Bridged)"
    echo -e ' '${RED}'[!]'${RESET}" Quitting..." 1>&2
    exit 1
  fi
fi

##### Install Teamviewer as a service
echo -e "\\n\\e[01;32m[+]\\e[00m Installing TeamviewerPro as a service"
# Creating the password
 apt-get install -y -qq pwgen  || echo -e ' '${RED}'[!] Issue with apt-get'${RESET} 1>&2
 tvpwd_len=`shuf -i 8-12 -n 1`
 tvpwd=`pwgen -scn $tvpwd_len 1`
 #--- Download TeamViewer and dependencies
 dpkg --add-architecture i386
 apt-get update || echo -e ' '${RED}'[!] Issue with adding i386 architecture'${RESET} 1>&2
 apt-get -y -qq install libc6:i386 libgcc1:i386 libasound2:i386 libdbus-1-3:i386 libexpat1:i386 libfontconfig1:i386 libfreetype6:i386 libjpeg62:i386 libpng12-0:i386 libsm6:i386 libxdamage1:i386 libxext6:i386 libxfixes3:i386 libxinerama1:i386 libxrandr2:i386 libxrender1:i386 libxtst6:i386 zlib1g:i386 || echo -e ' '${RED}'[!] Issue installing TeamViewer dependencies'${RESET} 1>&2
 wget http://download.teamviewer.com/download/teamviewer_i386.deb || echo -e ' '${RED}'[!] Issue downloading TeamViewer - check internet access'${RESET} 1>&2
 dpkg -i teamviewer_i386.deb
 #--- Configure TeamViewer
 echo -e "\\n\\e[01;32m[+]\\e[00m Setting Random Password"
 teamviewer passwd $tvpwd 1>&2
 echo -e "\\n\\e[01;32m[+]\\e[00m Please accept license when prompted....."
 teamviewer license accept 1>&2
 echo -e "\\n\\e[01;32m[+]\\e[00m Stopping TeamViewer (for good measure)"
 teamviewer --daemon disable 1>&2
 echo -e "\\n\\e[01;32m[+]\\e[00m Starting TeamViewer...this will take 1-2mins"
 teamviewer --daemon enable 1>&2
 sleep 10
 tvid=`teamviewer info |awk '/ID:/{print $5}'`
echo -e "\\n\\e[01;32m[+] Done!\\e[00m  Please send ID and Password to your Account Manager"
echo -e "\\n\\e[01;32m[+]\\e[00m Teamviewer ID: ${YELLOW}$tvid${RESET} Teamviewer Password: ${YELLOW}$tvpwd${RESET}"
exit 0