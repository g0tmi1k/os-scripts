#!/bin/bash
#-Operating System--------------------------------------------------#
#   Designed for: Kali Linux [1.0.5 x86]                            #
#   Last Updated: 2013-11-22                                        #
#-Author------------------------------------------------------------#
#  g0tmilk ~ https://blog.g0tmi1k.com/                              #
#-Notes-------------------------------------------------------------#
#   Tested used Kali Linux (x86/x64) as the base OS                 #
#                                                                   #
#   Useful reading:                                                 #
#     http://docs.kali.org/downloading/live-build-a-custom-kali-iso #
#-------------------------------------------------------------------#


##### Select architecture
echo -e '\e[01;32m[+]\e[00m Select architecture'
arch="i386"
echo -e 'Which architecture to build?\n1.) x86\n2.) x64'
while true; do
  echo -n "Select either 1 or 2 > "; read input
  if [[ $input == "1" ]] || [[ $input ==  "2" ]]; then
    [[ $input == "2" ]] && arch="amd64"
    break
  fi
done


##### Getting Ready
echo -e '\e[01;32m[+]\e[00m Getting Ready'
apt-get -y -qq install live-build cdebootstrap git kali-archive-keyring
cd /var/tmp/
git clone git://git.kali.org/live-build-config.git
cd live-build-config/
lb clean --purge
lb config


##### Configuring the Kali ISO Build
echo -e '\e[01;32m[+]\e[00m Configuring the Kali ISO Build'
file=config/package-lists/kali.list.chroot; [ -e $file ] && cp -n $file{,.bkup}
#--- Remove GNOME 3
sed -i 's/^gnome/# gnome/g' $file
#--- Install KDE
sed -i '/ KDE DESKTOP /,+2{/ KDE DESKTOP /!s/^# //}' $file


##### Building the ISO
echo -e '\e[01;32m[+]\e[00m Building the ISO'
#--- Allow building x64 on x86
if [[ $arch == "amd64" ]] && [[ $(uname -m) != "amd64" ]]; then
  dpkg --add-architecture amd64
  apt-get update
fi
#--- Setup caching (Enable if you wish todo a lot of custom ISOs)
apt-get -y -qq install apt-cacher-ng
service apt-cacher-ng start
export http_proxy=http://localhost:3142/
#--- Remove PAE from kernel
#sed -i 's/686-pae/486/g' auto/config
#lb clean
#--- Set architecture
lb config --architecture $arch
lb build


##### Post Build
echo -e '\e[01;32m[+]\e[00m Post Build'
[[ ! -e binary.hybrid.iso ]] && echo -e '\e[01;31m[!]\e[00m Failed to create ISO' && exit
echo -e '\e[01;32m[+]\e[00m Kali KDE ISO was successully created!'
#--- Move file somewhere that will 'last'
filename="kali-kde_$arch_$(date +%Y-%m-%d).iso"
mv -f binary.hybrid.iso ~/$filename
echo -e "\e[01;32m[+]\e[00m File: ~/$filename"
#--- Generate checksums
sha1=$(sha1sum ~/$filename | awk '{print $1}')
echo -e "\e[01;32m[+]\e[00m SHA1: $sha1"
