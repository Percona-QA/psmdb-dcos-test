#!/usr/bin/env bash

source ../CONFIG

if [ "${DCOS_TEST_VER}" = "1.11" ]; then
  TEMPLATE="../templates/psmdb-dcos-11-config.json"
else
  TEMPLATE="../templates/psmdb-dcos-10-config.json"
fi
${DCOS_CLI_BIN} package install percona-mongo --options=${TEMPLATE} --yes

sleep 30
${DCOS_CLI_BIN} percona-mongo endpoints mongo-port

${DCOS_CLI_BIN} percona-mongo pod list
