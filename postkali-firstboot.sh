#!/bin/sh

# grab our firstboot script
/usr/bin/wget -qO- http://bit.ly/postKali-netti2 > /root/postkali
chmod +x /root/postkali

# create a service that will run our firstboot script
cat > /etc/init.d/postkali <<EOF
### BEGIN INIT INFO
# Provides:        postkali
# Required-Start:  $networking
# Required-Stop:   $networking
# Default-Start:   2 3 4 5
# Default-Stop:    0 1 6
# Short-Description: A script that runs once
# Description: A script that runs once
### END INIT INFO

cd /root ; /usr/bin/nohup sh -x /root/postkali &


EOF

# install the firstboot service
chmod +x /etc/init.d/postkali
update-rc.d postkali defaults

echo "finished postinst of kali"