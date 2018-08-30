#!/usr/bin/env bats

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
  run bash -c "${MONGO_BIN} '$(get_rs_address ${SERVICE_NAME})' --username useradmin --password test123456 --eval \"db.getSiblingDB('admin').createUser({ user: '${MONGODB_TEST_USER}', pwd: '${MONGODB_TEST_PASS}', roles: [ 'readWrite', 'dbAdmin', 'root' ] })\""
  [ "$status" -eq 0 ]

  run bash -c "${MONGO_BIN} '$(get_rs_address ${SERVICE_NAME})' --username clusteradmin --password test123456 --eval 'rs.status()'"
  [ "$status" -eq 0 ]

  run bash -c "${MONGO_BIN} '$(get_rs_address_test ${SERVICE_NAME})' --eval 'db.getCollectionInfos()'"
  [ "$status" -eq 0 ]
}

@test "load some data in usertable1" {
  load_data ${SERVICE_NAME} usertable1
  load_check_hash ${SERVICE_NAME}
}

@test "check master pod redeploy" {
  local MASTER_POD=$(get_master_pod ${SERVICE_NAME})
  local MASTER_POD_AGENT=$(get_pod_agent ${SERVICE_NAME} ${MASTER_POD})
  run bash -c "${DCOS_CLI_BIN} ${SERVICE_NAME} pod replace ${MASTER_POD}"
  [ "$status" -eq 0 ]
  
  sleep 45
  # new mongo master should be elected
  local MASTER_POD_NEW=$(get_master_pod ${SERVICE_NAME})
  [ "${MASTER_POD}" != "${MASTER_POD_NEW}" ]

  # new pod should be created on the new agent
  local MASTER_POD_AGENT_NEW=$(get_pod_agent ${SERVICE_NAME} ${MASTER_POD})
  [ "${MASTER_POD_AGENT}" != "${MASTER_POD_AGENT_NEW}" ]

  load_check_hash ${SERVICE_NAME}
}

@test "load some data in usertable2" {
  load_data ${SERVICE_NAME} usertable2
  load_check_hash ${SERVICE_NAME}
}

@test "check slave pod redeploy" {
  local SLAVE_POD=$(get_slave_pod ${SERVICE_NAME})
  local SLAVE_POD_AGENT=$(get_pod_agent ${SERVICE_NAME} ${SLAVE_POD})
  run bash -c "${DCOS_CLI_BIN} ${SERVICE_NAME} pod replace ${SLAVE_POD}"
  [ "$status" -eq 0 ]
  
  sleep 45
  # new pod should be created on the NEW agent
  local SLAVE_POD_AGENT_NEW=$(get_pod_agent ${SERVICE_NAME} ${SLAVE_POD})
  [ "${SLAVE_POD_AGENT}" != "${SLAVE_POD_AGENT_NEW}" ]

  load_check_hash ${SERVICE_NAME}
}

@test "load some data in usertable3" {
  load_data ${SERVICE_NAME} usertable3
  load_check_hash ${SERVICE_NAME}
}

@test "check master pod restart" {
  local MASTER_POD=$(get_master_pod ${SERVICE_NAME})
  local MASTER_POD_AGENT=$(get_pod_agent ${SERVICE_NAME} ${MASTER_POD})
  run bash -c "${DCOS_CLI_BIN} ${SERVICE_NAME} pod restart ${MASTER_POD}"
  [ "$status" -eq 0 ]
  
  sleep 45
  # new mongo master should be elected
  local MASTER_POD_NEW=$(get_master_pod ${SERVICE_NAME})
  [ "${MASTER_POD}" != "${MASTER_POD_NEW}" ]

  # new pod should be created on the SAME agent
  local MASTER_POD_AGENT_NEW=$(get_pod_agent ${SERVICE_NAME} ${MASTER_POD})
  [ "${MASTER_POD_AGENT}" = "${MASTER_POD_AGENT_NEW}" ]

  load_check_hash ${SERVICE_NAME}
}

@test "load some data in usertable4" {
  load_data ${SERVICE_NAME} usertable4
  load_check_hash ${SERVICE_NAME}
}

@test "check slave pod restart" {
  local SLAVE_POD=$(get_slave_pod ${SERVICE_NAME})
  local SLAVE_POD_AGENT=$(get_pod_agent ${SERVICE_NAME} ${SLAVE_POD})
  run bash -c "${DCOS_CLI_BIN} ${SERVICE_NAME} pod restart ${SLAVE_POD}"
  [ "$status" -eq 0 ]
  
  sleep 45
  # new pod should be created on the SAME agent
  local SLAVE_POD_AGENT_NEW=$(get_pod_agent ${SERVICE_NAME} ${SLAVE_POD})
  [ "${SLAVE_POD_AGENT}" = "${SLAVE_POD_AGENT_NEW}" ]

  load_check_hash ${SERVICE_NAME}
}

@test "load some data in usertable5" {
  load_data ${SERVICE_NAME} usertable5
  load_check_hash ${SERVICE_NAME}
}

@test "check issuing kill -9 on master" {
  # sudo dcos task exec --interactive --tty mongo-rs-1-mongod__ac3d4e16-2e33-4c9d-b559-3cfdd4142de3 /bin/bash
  #TODO: Kill -9 mongod process on master pod
  #TODO: Check that the node was recreated
  #TODO: Check that the data loaded in previous test is the same in all nodes
}

@test "do some ycsb load" {
  #TODO: Run some more ycsb load to see that writes are working
  #TODO: Save dbHash for this table on every node
  #Something like:
  #./bin/ycsb.sh run mongodb -s -P workloads/workloadb -p recordcount=100000 -p operationcount=10000000 -threads 4 -p mongodb.url="mongodb://localhost:${MONGODB_PORT}/ycsb_test" -p mongodb.auth="false"
}

@test "check issuing kill -9 on slave" {
  # sudo dcos task exec --interactive --tty mongo-rs-1-mongod__ac3d4e16-2e33-4c9d-b559-3cfdd4142de3 /bin/bash
  #TODO: Kill -9 mongod process on slave pod
  #TODO: Check that the node was recreated
  #TODO: Check that the data loaded in previous test is the same in all nodes
}

@test "do some ycsb load" {
  #TODO: Run some more ycsb load to see that writes are working
  #TODO: Save dbHash for this table on every node
  #Something like:
  #./bin/ycsb.sh run mongodb -s -P workloads/workloadb -p recordcount=100000 -p operationcount=10000000 -threads 4 -p mongodb.url="mongodb://localhost:${MONGODB_PORT}/ycsb_test" -p mongodb.auth="false"
}

@test "check updating configuration" {
  #dcos percona-mongo update start --options=options.json
  #TODO: Check that the config update was applied
  #TODO: Check that the data loaded in previous test is the same in all nodes
}

@test "do some ycsb load" {
  #TODO: Run some more ycsb load to see that writes are working
  #TODO: Save dbHash for this table on every node
  #Something like:
  #./bin/ycsb.sh run mongodb -s -P workloads/workloadb -p recordcount=100000 -p operationcount=10000000 -threads 4 -p mongodb.url="mongodb://localhost:${MONGODB_PORT}/ycsb_test" -p mongodb.auth="false"
}

# Disabled because of https://github.com/mesosphere/dcos-mongo/issues/249
#@test "destroy service" {
#  run ${DCOS_CLI_BIN} package uninstall percona-mongo --yes
#  [ "$status" -eq 0 ]
#
#  TODO: Add check that all parts are actually destroyed
#}
