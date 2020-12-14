#!/bin/bash
#yum -y install httpd php php-mysql php-gd php-xml php-mbstring
yum -y install http://rpms.remirepo.net/enterprise/remi-release-7.rpm
yum -y install yum-utils
yum-config-manager --enable remi-php74
yum -y update php
systemctl start httpd
systemctl enable httpd
sed -i '119s/html//' /etc/httpd/conf/httpd.conf
sed -i '164s/index.html/index.html index.html.var index.php/' /etc/httpd/conf/httpd.conf
cd /var/www
ln -s mediawiki-1.35.0/ mediawiki
chown -R apache:apache /var/www/mediawiki-1.35.0
chown -R apache:apache /var/www/mediawiki
systemctl restart httpd
firewall-cmd --permanent --zone=public --add-service=http
firewall-cmd --permanent --zone=public --add-service=https
firewall-cmd --reload
