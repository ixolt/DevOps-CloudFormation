#!/bin/bash

sudo apt-get update
sudo apt-get install -y nginx

sed -i -- 's/:6081/:80/g' /lib/systemd/system/varnish.service

systemctl daemon-reload
service varnish restart

sudo apt-get install -y varnish