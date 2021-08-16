#!/bin/bash
yum install httpd -y
echo "<h2> Maruthi App </h2>" > /var/www/html/index.html
service httpd restart
chkconfig httpd on