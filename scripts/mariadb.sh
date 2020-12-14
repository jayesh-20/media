#!/bin/bash
yum install epel-release -y
sed -i 's/enforcing/permissive/g' /etc/selinux/config
setenforce permissive
systemctl start firewalld
systemctl enable firewalld

yum -y install mariadb-server mariadb
systemctl enable mariadb
systemctl start mariadb
mysql_secure_installation <<EOF

y
secret
secret
y
y
y
y
EOF
mysql -psecret  -e "CREATE USER 'wiki'@'localhost' IDENTIFIED BY 'media'"
mysql -psecret -e "CREATE DATABASE wikidatabase"
mysql -psecret -e "GRANT ALL PRIVILEGES ON wikidatabase.* TO 'wiki'@'localhost'"
mysql -psecret -e "FLUSH PRIVILEGES"
mysql -psecret -e "SHOW DATABASES"
mysql -psecret -e "SHOW GRANTS FOR 'wiki'@'localhost'"
