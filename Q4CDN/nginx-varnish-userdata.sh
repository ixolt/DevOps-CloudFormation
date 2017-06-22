#!/bin/bash
# line below goes into user-data
# curl -sL https://raw.githubusercontent.com/q4mobile/DevOps-CloudFormation/master/Q4CDN/nginx-varnish-userdata.sh | bash -s --

sudo apt-get update
sudo apt-get -y install nginx
sudo apt-get -y install varnish

# cert needed for nginx
sudo mkdir /etc/nginx/ssl/
sudo curl -o /etc/nginx/ssl/barrick.crt https://raw.githubusercontent.com/q4mobile/DevOps-CloudFormation/master/Q4CDN/barrick.crt
sudo curl -o /etc/nginx/ssl/barrick.key https://raw.githubusercontent.com/q4mobile/DevOps-CloudFormation/master/Q4CDN/barrick.key

# nginx config
sudo curl -o /etc/nginx/sites-enabled/default https://raw.githubusercontent.com/q4mobile/DevOps-CloudFormation/master/Q4CDN/default

sudo service nginx restart

# get varnish to listen on port 80
sudo sed -i -- 's/:6081/:80/g' /lib/systemd/system/varnish.service

# default config file for varnish
sudo curl -o /etc/varnish/default.vcl https://raw.githubusercontent.com/q4mobile/DevOps-CloudFormation/master/Q4CDN/default.vcl 

# restart varnish
sudo systemctl daemon-reload
sudo service varnish restart
