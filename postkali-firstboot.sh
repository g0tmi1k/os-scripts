#!/bin/sh

# grab our firstboot script
/usr/bin/curl -o /root/firstboot http://bit.ly/postKali-firstboot
chmod +x /root/postkali-firstboot

# create a service that will run our firstboot script
cat > /etc/init.d/postkali-firstboot <<EOF
### BEGIN INIT INFO
# Provides:        postkali-firstboot
# Required-Start:  $networking
# Required-Stop:   $networking
# Default-Start:   2 3 4 5
# Default-Stop:    0 1 6
# Short-Description: A script that runs once
# Description: A script that runs once
### END INIT INFO

cd /root ; /usr/bin/nohup sh -x /root/postkali-firstboot &


EOF

# install the firstboot service
chmod +x /etc/init.d/postkali-firstboot
update-rc.d postkali-firstboot defaults

echo "finished postinst"