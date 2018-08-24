#!/usr/bin/env bash

source ../CONFIG

dcos cluster remove --all || true

[ -d /usr/local/bin ] || sudo mkdir -p /usr/local/bin && 
curl https://downloads.dcos.io/binaries/cli/linux/x86-64/dcos-${DCOS_TEST_VER}/dcos -o dcos && 
sudo mv dcos /usr/local/bin && 
sudo chmod +x /usr/local/bin/dcos && 
dcos cluster setup ${CLUSTER_URL} && 
dcos

dcos package install tunnel-cli --cli
