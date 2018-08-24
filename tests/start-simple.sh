#!/usr/bin/env bash
sudo dcos package install percona-mongo --options=../templates/psmdb-dcos-11-config.json

sudo dcos percona-mongo endpoints mongo-port

sudo dcos percona-mongo pod list
