#!/bin/bash
BASE="/var/lib/binder/deploy/web"

cd ${BASE}
git pull origin master && git submodule update --init

cd ${BASE}/kubernetes
npm install

cd ${BASE}/web
npm install
