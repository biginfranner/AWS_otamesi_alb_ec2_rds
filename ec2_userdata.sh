#!/bin/bash
dnf update -y
dnf install -y httpd mariadb105
systemctl start httpd
systemctl enable httpd
echo "Hello from $(hostname)" > /var/www/html/index.html
