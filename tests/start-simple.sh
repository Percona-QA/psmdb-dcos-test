#!/usr/bin/env bash

source ../CONFIG

TEMPLATE="../templates/mongodb-credentials.json"
#if [ "${DCOS_TEST_VER%-*}" = "1.11" ]; then
#  TEMPLATE="../templates/psmdb-dcos-11-config.json"
#else
#  TEMPLATE="../templates/psmdb-dcos-10-config.json"
#fi
${DCOS_CLI_BIN} package install ${PACKAGE_NAME} --options=${TEMPLATE} --yes

sleep 60
${DCOS_CLI_BIN} ${PACKAGE_NAME} endpoints mongo-port

${DCOS_CLI_BIN} ${PACKAGE_NAME} pod list
