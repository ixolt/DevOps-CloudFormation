#!/bin/bash

apt-get update
apt-get -y install nginx
apt-get -y install varnish

# get varnish to listen on port 80
sed -i -- 's/:6081/:80/g' /lib/systemd/system/varnish.service

systemctl daemon-reload
service varnish restart
