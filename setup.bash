#!/bin/bash
BINDER_HOME="/var/lib/binder"
GIT_DIR="${BINDER_HOME}/deploy"
HOME="/var/lib/binder"

apt-get install --yes npm nodejs-legacy nginx

sudo wget https://storage.googleapis.com/kubernetes-release/release/v1.5.2/bin/linux/amd64/kubectl -O /usr/local/bin/kubectl
sudo chmod +x /usr/local/bin/kubectl

adduser --disabled-password --disabled-login --system --gecos "Binder system user" --home ${BINDER_HOME} binder
sudo -u binder git clone --recursive https://github.com/yuvipanda/binder-deployment.git ${GIT_DIR}

sudo -u binder gcloud container clusters get-credentials binder-cluster-dev --zone=us-central1-b
# Run npm install

cd ${GIT_DIR}/web/kubernetes
sudo -u binder npm install

cd ${GIT_DIR}/web/web
sudo -u binder npm install

rm -rf ${BINDER_HOME}/.binder
ln -s ${GIT_DIR}/config ${BINDER_HOME}/.binder

ln -s ${GIT_DIR}/web/binder-kubernetes.service /etc/systemd/system/binder-kubernetes.service
ln -s ${GIT_DIR}/web/kubectl-proxy.service /etc/systemd/system/kubectl-proxy.service
ln -s ${GIT_DIR}/web/binder-web.service /etc/systemd/system/binder-web.service

sudo systemctl start binder-web

sudo ln -s ${GIT_DIR}/web/proxy.nginx.conf /etc/nginx/sites-enabled/proxy.conf
sudo systemctl nginx restart
