#!/bin/bash
echo -e "\\n\\e[01;32m[+]\\e[00m Installing TeamviewerPro"
# Creating the password
apt-get install -y -qq pwgen  || echo -e ' '${RED}'[!] Issue with apt-get'${RESET} 1>&2
buildpwd_len=`shuf -i 8-12 -n 1`
buildpwd=`pwgen -scn $buildpwd_len 1`

   dpkg --add-architecture i386
   apt-get update
   apt-get -y -qq install libc6:i386 libgcc1:i386 libasound2:i386 libdbus-1-3:i386 libexpat1:i386 libfontconfig1:i386 libfreetype6:i386 libjpeg62:i386 libpng12-0:i386 libsm6:i386 libxdamage1:i386 libxext6:i386 libxfixes3:i386 libxinerama1:i386 libxrandr2:i386 libxrender1:i386 libxtst6:i386 zlib1g:i386
   wget http://download.teamviewer.com/download/teamviewer_i386.deb
   dpkg -i teamviewer_i386.deb
   #--- Configure TeamViewer
    teamviewer passwd $tvpwd
    teamviewer license accept
    teamviewer --daemon stop
    tvid=`teamviewer info |awk '/ID:/{print $5}'`
echo -e "TeamviwerID: $tvid Teamviewer Password: $tvpwd"
   #--- Enable at boot
    cp /opt/teamviewer/tv_bin/script/teamviewerd.sysv /etc/init.d/
    chmod 755 /etc/init.d/teamviewerd.sysv
echo -e "\\n\\e[01;32m[+]\\e[00m Done! Please send ID and Password to your Accoutn Manager"