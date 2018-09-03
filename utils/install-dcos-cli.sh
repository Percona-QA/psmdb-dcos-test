#!/usr/bin/env bash

source ../CONFIG

if [ ${DCOS_TEST_VER#*-} = "ee" ]; then
  CREDENTIALS="--username=bootstrapuser --password=deleteme"
else
  CREDENTIALS=""
fi

${DCOS_CLI_BIN} cluster remove --all || true

[ -d /usr/local/bin ] || sudo mkdir -p /usr/local/bin && 
curl https://downloads.dcos.io/binaries/cli/linux/x86-64/dcos-${DCOS_TEST_VER%-*}/dcos -o dcos && 
sudo mv dcos /usr/local/bin && 
sudo chmod +x /usr/local/bin/dcos && 
${DCOS_CLI_BIN} cluster setup ${CLUSTER_URL} --no-check ${CREDENTIALS} && 
${DCOS_CLI_BIN}

${DCOS_CLI_BIN} package install tunnel-cli --cli --yes
