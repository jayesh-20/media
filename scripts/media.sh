#!/bin/bash
cd /home/centosad
wget https://releases.wikimedia.org/mediawiki/1.35/mediawiki-1.35.0.tar.gz
cd /var/www
tar -zxf /home/centosad/mediawiki-1.35.0.tar.gz
ln -s mediawiki-1.35.0/ mediawiki
chown -R apache:apache /var/www/mediawiki-1.35.0
chown -R apache:apache /var/www/mediawiki
