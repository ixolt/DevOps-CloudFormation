apt-get -y install python-pip

pip install https://s3.amazonaws.com/cloudformation-examples/aws-cfn-bootstrap-latest.tar.gz

cp /usr/local/init/ubuntu/cfn-hup /etc/init.d/cfn-hup
chmod +x /etc/init.d/cfn-hup
update-rc.d cfn-hup defaults
service cfn-hup start