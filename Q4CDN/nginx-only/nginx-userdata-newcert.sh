#!/bin/bash
# line below goes into user-data
# curl -sL https://raw.githubusercontent.com/q4mobile/DevOps-CloudFormation/master/Q4CDN/nginx-varnish-userdata.sh | bash -s --

sudo apt-get update
sudo apt-get -y install nginx

# cert needed for nginx
sudo mkdir -p /etc/nginx/ssl/
sudo curl -o /etc/nginx/ssl/barrick.crt https://raw.githubusercontent.com/q4mobile/DevOps-CloudFormation/master/Q4CDN/chicagotest_q4preview_com.crt
sudo curl -o /etc/nginx/ssl/barrick.key https://raw.githubusercontent.com/q4mobile/DevOps-CloudFormation/master/Q4CDN/chicagotest_q4preview_com.key

sudo mkdir -p /data/nginx/cache/

# nginx config
sudo curl -o /etc/nginx/sites-enabled/default https://raw.githubusercontent.com/q4mobile/DevOps-CloudFormation/master/Q4CDN/nginx-only/default

sudo service nginx restart