#!/usr/bin/env bats
# This is a test for DCOS percona-mongo command line interface
load common-func

@test "create new service" {
  run ${DCOS_CLI_BIN} package install ${PACKAGE_NAME} --options=${TEMPLATE} --yes
  [ "$status" -eq 0 ]

  sleep 90
  [ "$(get_nr_nodes ${SERVICE_NAME})" -eq ${RS_SIZE} ]
  [ "$(get_dcos_service_active_status ${SERVICE_NAME})" = "True" ]
  [ "$(get_dcos_service_nr_tasks ${SERVICE_NAME})" -eq $((${RS_SIZE} + 1)) ]
}

@test "setup and check connection to mongo" {
  run bash -c "${MONGO_BIN} '$(get_rs_address ${SERVICE_NAME} ${RS_SIZE})' --username useradmin --password test123456 --eval \"db.getSiblingDB('admin').createUser({ user: '${MONGODB_TEST_USER}', pwd: '${MONGODB_TEST_PASS}', roles: [ 'readWrite', 'dbAdmin', 'root' ] })\""
  [ "$status" -eq 0 ]

  run bash -c "${MONGO_BIN} '$(get_rs_address ${SERVICE_NAME} ${RS_SIZE})' --username clusteradmin --password test123456 --eval 'rs.status()'"
  [ "$status" -eq 0 ]

  run bash -c "${MONGO_BIN} '$(get_rs_address_test ${SERVICE_NAME} ${RS_SIZE})' --eval 'db.getCollectionInfos()'"
  [ "$status" -eq 0 ]
}

#TODO
#- scale up/down (probably better add in durability)
#- debug pod pause/resume
#- describe
#- plan list/start/stop/pause/resume
#- pod list/info
#- update start with options file (durability)
#- backup run/stop
#- restore run/stop
#- user add/remove/update

@test "test adding a user" { 
  skip "Issue: https://github.com/mesosphere/dcos-mongo/issues/257"
  run ${DCOS_CLI_BIN} ${SERVICE_NAME} user add admin ../templates/test-user.json
  [ "$status" -eq 0 ]
}

@test "test deleting a user" {
  skip "Not implemented yet."
}

@test "destroy service" {
  skip "Disabled because of https://github.com/mesosphere/dcos-mongo/issues/249"
  run ${DCOS_CLI_BIN} package uninstall percona-mongo --yes
  [ "$status" -eq 0 ]

  #TODO: Add check that all parts are actually destroyed
}
