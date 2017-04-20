#!/bin/bash
set -e
BINDER_HOME="/var/lib/binder"
GIT_DIR="${BINDER_HOME}/deploy"
HOME="/var/lib/binder"
apt-get install --yes npm nodejs-legacy nginx mongodb pwgen apt-transport-https openjdk-8-jdk

wget -qO - https://download.docker.com/linux/ubuntu/gpg | apt-key add -
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -

add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

echo "deb https://artifacts.elastic.co/logstash/2.1/debian stable main" | sudo tee -a /etc/apt/sources.list.d/logstash-2.x.list
echo "deb https://artifacts.elastic.co/packages/5.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-5.x.list

apt-get update
apt-get install --yes docker-ce logstash elasticsearch kibana

/opt/logstash/bin/plugin install logstash-input-tcp
/opt/logstash/bin/plugin install logstash-output-elasticsearch
/opt/logstash/bin/plugin install logstash-output-websocket_topics

wget https://storage.googleapis.com/kubernetes-release/release/v1.5.2/bin/linux/amd64/kubectl -O /usr/local/bin/kubectl
chmod +x /usr/local/bin/kubectl

adduser --disabled-password --disabled-login --system --gecos "Binder system user" --home ${BINDER_HOME} binder
if [ -d ${GIT_DIR} ]; then
    cd /var/lib/binder/deploy && sudo -u binder git fetch && sudo -u binder git reset --hard origin/master & sudo -u binder git submodule update --init
else
    sudo -u binder git clone --recursive https://github.com/yuvipanda/binder-deployment.git ${GIT_DIR}
fi

if [ ! -f ${BINDER_HOME}/apikey ]; then
    echo "BINDER_API_KEY=$(pwgen -s 64 1)" > ${BINDER_HOME}/apikey
fi

sudo -u binder gcloud container clusters get-credentials binder-cluster-dev --zone=us-central1-a
# Run npm install

cd ${GIT_DIR}/web/kubernetes
sudo -u binder npm install

cd ${GIT_DIR}/web/web
sudo -u binder npm install

cd ${GIT_DIR}/web/healthz
sudo -u binder npm install

cd ${GIT_DIR}/web/build
sudo -u binder npm install

cd ${GIT_DIR}/web/logging
sudo -u binder npm install

rm -rf ${BINDER_HOME}/.binder
ln -s ${GIT_DIR}/config ${BINDER_HOME}/.binder

ln -s ${GIT_DIR}/web/binder-kubernetes.service /etc/systemd/system/binder-kubernetes.service
ln -s ${GIT_DIR}/web/kubectl-proxy.service /etc/systemd/system/kubectl-proxy.service
ln -s ${GIT_DIR}/web/binder-web.service /etc/systemd/system/binder-web.service
ln -s ${GIT_DIR}/web/binder-healthz.service /etc/systemd/system/binder-healthz.service
ln -s ${GIT_DIR}/web/binder-build.service /etc/systemd/system/binder-build.service

ln -sf ${GIT_DIR}/services/kibana.yml /etc/kibana/kibana.yml
ln -sf ${GIT_DIR}/services/logstash.conf /etc/logstash/conf.d/logstash.conf

sudo systemctl start binder-web binder-healthz logstash elasticsearch kibana

sudo ln -s ${GIT_DIR}/web/proxy.nginx.conf /etc/nginx/sites-enabled/proxy.conf
sudo rm -f /etc/nginx/sites-enabled/default
sudo systemctl restart nginx

cd ${GIT_DIR}/web/logging
sudo -u binder npm run configure
