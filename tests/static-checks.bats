#!/usr/bin/env bats

load common-func

@test "create new service" {
#  run ${DCOS_CLI_BIN} package install ${PACKAGE_NAME} --options=${TEMPLATE} --yes
#  [ "$status" -eq 0 ]

#  sleep 30
  [ "$(get_nr_nodes ${SERVICE_NAME})" -eq 3 ]
  [ "$(get_dcos_service_active_status ${SERVICE_NAME})" = "True" ]
  [ "$(get_dcos_service_nr_tasks ${SERVICE_NAME})" -eq 4 ]
}

@test "check connection to mongo" {
  run bash -c "${MONGO_BIN} $(get_rs_address ${SERVICE_NAME}) --username clusteradmin --password test123456 --authenticationDatabase admin --eval 'rs.status()'"
  [ "$status" -eq 0 ]
}

# Disabled because of https://github.com/mesosphere/dcos-mongo/issues/249
#@test "destroy service" {
#  run ${DCOS_CLI_BIN} package uninstall percona-mongo --yes
#  [ "$status" -eq 0 ]
#
#  TODO: Add check that all parts are actually destroyed
#}
