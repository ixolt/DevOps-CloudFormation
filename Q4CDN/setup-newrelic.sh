echo "license_key: 894e0b6d7be105df460accd4dedcae7b3629c927" | sudo tee -a /etc/newrelic-infra.yml

curl https://download.newrelic.com/infrastructure_agent/gpg/newrelic-infra.gpg | sudo apt-key add -
printf "deb [arch=amd64] https://download.newrelic.com/infrastructure_agent/linux/apt xenial main" | sudo tee -a /etc/apt/sources.list.d/newrelic-infra.list

sudo apt-get update
sudo apt-get install newrelic-infra -y