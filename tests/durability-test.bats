#!/usr/bin/env bats
# This test tries to stop/start nodes in different ways and checks
# if data will persist and replica set remain operational
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
  run ${DCOS_CLI_BIN} ${SERVICE_NAME} user add admin ../templates/test-user.json
  [ "$status" -eq 0 ]

#  run bash -c "${MONGO_BIN} '$(get_rs_address ${SERVICE_NAME} ${RS_SIZE})' --username useradmin --password test123456 --eval \"db.getSiblingDB('admin').createUser({ user: '${MONGODB_TEST_USER}', pwd: '${MONGODB_TEST_PASS}', roles: [ 'readWrite', 'dbAdmin', 'root' ] })\""
#  [ "$status" -eq 0 ]

  run bash -c "${MONGO_BIN} '$(get_rs_address ${SERVICE_NAME} ${RS_SIZE})' --username clusteradmin --password test123456 --eval 'rs.status()'"
  [ "$status" -eq 0 ]

  run bash -c "${MONGO_BIN} '$(get_rs_address_test ${SERVICE_NAME} ${RS_SIZE})' --eval 'db.getCollectionInfos()'"
  [ "$status" -eq 0 ]
}

@test "load data in usertable1" {
  load_data ${SERVICE_NAME} ${RS_SIZE} usertable1
  load_check_hash ${SERVICE_NAME} ${RS_SIZE}
  check_rs_health ${SERVICE_NAME} ${RS_SIZE}
}

@test "check master pod redeploy" {
  local MASTER_POD=$(get_master_pod ${SERVICE_NAME} ${RS_SIZE})
  local MASTER_POD_AGENT=$(get_pod_agent ${SERVICE_NAME} ${MASTER_POD})
  run bash -c "${DCOS_CLI_BIN} ${SERVICE_NAME} pod replace ${MASTER_POD}"
  [ "$status" -eq 0 ]
  
  sleep 60
  # new mongo master should be elected
  local MASTER_POD_NEW=$(get_master_pod ${SERVICE_NAME} ${RS_SIZE})
  [ "${MASTER_POD}" != "${MASTER_POD_NEW}" ]

  # new pod should be created on the new agent
  local MASTER_POD_AGENT_NEW=$(get_pod_agent ${SERVICE_NAME} ${MASTER_POD})
  [ "${MASTER_POD_AGENT}" != "${MASTER_POD_AGENT_NEW}" ]

  load_check_hash ${SERVICE_NAME} ${RS_SIZE}
  check_rs_health ${SERVICE_NAME} ${RS_SIZE}
}

@test "load data in usertable2" {
  load_data ${SERVICE_NAME} ${RS_SIZE} usertable2
  load_check_hash ${SERVICE_NAME} ${RS_SIZE}
  check_rs_health ${SERVICE_NAME} ${RS_SIZE}
}

@test "check slave pod redeploy" {
  local SLAVE_POD=$(get_slave_pod ${SERVICE_NAME})
  local SLAVE_POD_AGENT=$(get_pod_agent ${SERVICE_NAME} ${SLAVE_POD})
  run bash -c "${DCOS_CLI_BIN} ${SERVICE_NAME} pod replace ${SLAVE_POD}"
  [ "$status" -eq 0 ]
  
  sleep 60
  # new pod should be created on the NEW agent
  local SLAVE_POD_AGENT_NEW=$(get_pod_agent ${SERVICE_NAME} ${SLAVE_POD})
  [ "${SLAVE_POD_AGENT}" != "${SLAVE_POD_AGENT_NEW}" ]

  load_check_hash ${SERVICE_NAME} ${RS_SIZE}
  check_rs_health ${SERVICE_NAME} ${RS_SIZE}
}

@test "load data in usertable3" {
  load_data ${SERVICE_NAME} ${RS_SIZE} usertable3
  load_check_hash ${SERVICE_NAME} ${RS_SIZE}
  check_rs_health ${SERVICE_NAME} ${RS_SIZE}
}

@test "check master pod restart" {
  local MASTER_POD=$(get_master_pod ${SERVICE_NAME} ${RS_SIZE})
  local MASTER_POD_AGENT=$(get_pod_agent ${SERVICE_NAME} ${MASTER_POD})
  run bash -c "${DCOS_CLI_BIN} ${SERVICE_NAME} pod restart ${MASTER_POD}"
  [ "$status" -eq 0 ]
  
  sleep 60
  # new mongo master should be elected
  local MASTER_POD_NEW=$(get_master_pod ${SERVICE_NAME} ${RS_SIZE})
  [ "${MASTER_POD}" != "${MASTER_POD_NEW}" ]

  # new pod should be created on the SAME agent
  local MASTER_POD_AGENT_NEW=$(get_pod_agent ${SERVICE_NAME} ${MASTER_POD})
  [ "${MASTER_POD_AGENT}" = "${MASTER_POD_AGENT_NEW}" ]

  load_check_hash ${SERVICE_NAME} ${RS_SIZE}
  check_rs_health ${SERVICE_NAME} ${RS_SIZE}
}

@test "load data in usertable4" {
  load_data ${SERVICE_NAME} ${RS_SIZE} usertable4
  load_check_hash ${SERVICE_NAME} ${RS_SIZE}
  check_rs_health ${SERVICE_NAME} ${RS_SIZE}
}

@test "check slave pod restart" {
  local SLAVE_POD=$(get_slave_pod ${SERVICE_NAME})
  local SLAVE_POD_AGENT=$(get_pod_agent ${SERVICE_NAME} ${SLAVE_POD})
  run bash -c "${DCOS_CLI_BIN} ${SERVICE_NAME} pod restart ${SLAVE_POD}"
  [ "$status" -eq 0 ]
  
  sleep 60
  # new pod should be created on the SAME agent
  local SLAVE_POD_AGENT_NEW=$(get_pod_agent ${SERVICE_NAME} ${SLAVE_POD})
  [ "${SLAVE_POD_AGENT}" = "${SLAVE_POD_AGENT_NEW}" ]

  load_check_hash ${SERVICE_NAME} ${RS_SIZE}
  check_rs_health ${SERVICE_NAME} ${RS_SIZE}
}

@test "load data in usertable5" {
  load_data ${SERVICE_NAME} ${RS_SIZE} usertable5
  load_check_hash ${SERVICE_NAME} ${RS_SIZE}
  check_rs_health ${SERVICE_NAME} ${RS_SIZE}
}

@test "check issuing kill -9 on master" {
  local MASTER_POD=$(get_master_pod ${SERVICE_NAME} ${RS_SIZE})
  local MASTER_POD_AGENT=$(get_pod_agent ${SERVICE_NAME} ${MASTER_POD})
  local MASTER_POD_TASK=$(get_task_id ${SERVICE_NAME} ${MASTER_POD})

  run ${DCOS_CLI_BIN} task exec ${MASTER_POD_TASK} bash -c "kill -9 \$(pidof mongod)"
  [ "$status" -eq 0 ]
  sleep 180

  local MASTER_POD_TASK_NEW=$(get_task_id ${SERVICE_NAME} ${MASTER_POD})
  [ "${MASTER_POD_TASK}" != "${MASTER_POD_TASK_NEW}" ]

  load_check_hash ${SERVICE_NAME} ${RS_SIZE}
  check_rs_health ${SERVICE_NAME} ${RS_SIZE}
}

@test "load data in usertable6" {
  load_data ${SERVICE_NAME} ${RS_SIZE} usertable6
  load_check_hash ${SERVICE_NAME} ${RS_SIZE}
  check_rs_health ${SERVICE_NAME} ${RS_SIZE}
}

@test "check issuing kill -9 on slave" {
  local SLAVE_POD=$(get_master_pod ${SERVICE_NAME} ${RS_SIZE})
  local SLAVE_POD_AGENT=$(get_pod_agent ${SERVICE_NAME} ${SLAVE_POD})
  local SLAVE_POD_TASK=$(get_task_id ${SERVICE_NAME} ${SLAVE_POD})

  run ${DCOS_CLI_BIN} task exec ${SLAVE_POD_TASK} bash -c "kill -9 \$(pidof mongod)"
  [ "$status" -eq 0 ]
  sleep 180

  local SLAVE_POD_TASK_NEW=$(get_task_id ${SERVICE_NAME} ${SLAVE_POD})
  [ "${SLAVE_POD_TASK}" != "${SLAVE_POD_TASK_NEW}" ]

  load_check_hash ${SERVICE_NAME} ${RS_SIZE}
  check_rs_health ${SERVICE_NAME} ${RS_SIZE}
}

@test "load data in usertable7" {
  load_data ${SERVICE_NAME} ${RS_SIZE} usertable7
  load_check_hash ${SERVICE_NAME} ${RS_SIZE}
  check_rs_health ${SERVICE_NAME} ${RS_SIZE}
}

@test "check updating configuration" {
  skip "Not implemented yet."
  #dcos percona-mongo update start --options=options.json
  #TODO: Check that the config update was applied
  #TODO: Check that the data loaded in previous test is the same in all nodes
}

@test "load data in usertable8" {
  load_data ${SERVICE_NAME} ${RS_SIZE} usertable8
  load_check_hash ${SERVICE_NAME} ${RS_SIZE}
  check_rs_health ${SERVICE_NAME} ${RS_SIZE}
}

@test "check scaling up to 5 instances" {
  #skip "Issue: https://github.com/mesosphere/dcos-mongo/issues/258"
  run ${DCOS_CLI_BIN} percona-mongo scale 5
  [ "$status" -eq 0 ]
  
  sleep 120
  load_check_hash ${SERVICE_NAME} 5
  check_rs_health ${SERVICE_NAME} 5
}

@test "load data in usertable9" {
  load_data ${SERVICE_NAME} ${RS_SIZE} usertable9
  load_check_hash ${SERVICE_NAME} ${RS_SIZE}
  check_rs_health ${SERVICE_NAME} ${RS_SIZE}
}

@test "check scaling down to 3 instances" {
  #skip "Issue: https://github.com/mesosphere/dcos-mongo/issues/258"
  run ${DCOS_CLI_BIN} percona-mongo scale 3
  [ "$status" -eq 0 ]
  
  sleep 120
  load_check_hash ${SERVICE_NAME} 3
  check_rs_health ${SERVICE_NAME} 3
}

@test "destroy service" {
  #skip "Disabled because of https://github.com/mesosphere/dcos-mongo/issues/249"
  run ${DCOS_CLI_BIN} package uninstall percona-mongo --yes
  [ "$status" -eq 0 ]

  sleep 60
  run bash -c "${DCOS_CLI_BIN} service | grep -c ${SERVICE_NAME}"
  [ "$output" = "0" ]

  run bash -c "${DCOS_CLI_BIN} marathon task list|grep -c ${SERVICE_NAME}"
  [ "$output" = "0" ]

  run bash -c "${DCOS_CLI_BIN} marathon app list|grep -c ${SERVICE_NAME}"
  [ "$output" = "0" ]
}

@test "env cleanup" {
  rm -f testdb-md5-${SERVICE_NAME}.tmp
}
