#!/usr/bin/env bash

source ../CONFIG

if [ "${DCOS_TEST_VER}" = "1.11" ]; then
  TEMPLATE="../templates/psmdb-dcos-11-config.json"
else
  TEMPLATE="../templates/psmdb-dcos-10-config.json"
fi
dcos package install percona-mongo --options=${TEMPLATE} --yes

sleep 30
dcos percona-mongo endpoints mongo-port

dcos percona-mongo pod list
