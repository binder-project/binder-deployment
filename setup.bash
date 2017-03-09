#!/bin/bash
# Install packages we care about
sudo apt-get install --yes npm nodejs-legacy

adduser --disabled-password --disabled-login --system --gecos "Binder system user" --home /var/lib/binder binder
sudo -u binder git clone --recursive https://github.com/yuvipanda/binder-deployment.git /var/lib/binder/deploy
