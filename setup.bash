#!/bin/bash
BINDER_HOME="/var/lib/binder"
GIT_DIR="${BINDER_HOME}/deploy"
HOME="/var/lib/binder"

apt-get install --yes npm nodejs-legacy nginx mongodb pwgen

sudo wget https://storage.googleapis.com/kubernetes-release/release/v1.5.2/bin/linux/amd64/kubectl -O /usr/local/bin/kubectl
sudo chmod +x /usr/local/bin/kubectl

adduser --disabled-password --disabled-login --system --gecos "Binder system user" --home ${BINDER_HOME} binder
if [ -d ${GIT_DIR} ]; then
    cd /var/lib/binder/deploy && sudo -u binder git fetch && sudo -u binder git reset --hard origin/master & sudo -u binder git submodule update --init
else
    sudo -u binder git clone --recursive https://github.com/yuvipanda/binder-deployment.git ${GIT_DIR}
fi

if [ ! -f ${BINDER_HOME}/apikey ]; then
    echo "BINDER_API_KEY=$(pwgen -s 64 1)" > ${BINDER_HOME}/apikey
fi

sudo -u binder gcloud container clusters get-credentials binder-cluster-dev --zone=us-central1-b
# Run npm install

cd ${GIT_DIR}/web/kubernetes
sudo -u binder npm install

cd ${GIT_DIR}/web/web
sudo -u binder npm install

cd ${GIT_DIR}/web/healthz
sudo -u binder npm install

cd ${GIT_DIR}/web/binder
sudo -u binder npm install

rm -rf ${BINDER_HOME}/.binder
ln -s ${GIT_DIR}/config ${BINDER_HOME}/.binder

ln -s ${GIT_DIR}/web/binder-kubernetes.service /etc/systemd/system/binder-kubernetes.service
ln -s ${GIT_DIR}/web/kubectl-proxy.service /etc/systemd/system/kubectl-proxy.service
ln -s ${GIT_DIR}/web/binder-web.service /etc/systemd/system/binder-web.service
ln -s ${GIT_DIR}/web/binder-healthz.service /etc/systemd/system/binder-healthz.service
ln -s ${GIT_DIR}/web/binder-build.service /etc/systemd/system/binder-build.service

sudo systemctl start binder-web binder-healthz

sudo ln -s ${GIT_DIR}/web/proxy.nginx.conf /etc/nginx/sites-enabled/proxy.conf
sudo rm -f /etc/nginx/sites-enabled/default
sudo systemctl restart nginx
