#!/usr/bin/env bats

load common-func

@test "create new service" {
  run ${DCOS_CLI_BIN} package install ${PACKAGE_NAME} --options=${TEMPLATE} --yes
  [ "$status" -eq 0 ]

  sleep 30
  [ "$(get_nr_nodes ${SERVICE_NAME})" -eq 3 ]
  [ "$(get_dcos_service_active_status ${SERVICE_NAME})" = "True" ]
  [ "$(get_dcos_service_nr_tasks ${SERVICE_NAME})" -eq 4 ]
}

@test "check connection to mongo" {
  run bash -c "${MONGO_BIN} $(get_rs_address ${SERVICE_NAME}) --username clusteradmin --password test123456 --authenticationDatabase admin --eval 'rs.status()'"
  [ "$status" -eq 0 ]
}

@test "load data with ycsb" {
  #TODO: Load at least 2Gb of data into a table with ycsb
  #TODO: Save dbHash for this table on every node
  #Something like:
  #./bin/ycsb load mongodb -s -P workloads/workloada -p recordcount=2000000 -threads 4 -p mongodb.url="mongodb://user:pwd@localhost:27017/ycsb_test" -p mongodb.auth="true"
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
  #./bin/ycsb.sh run mongodb -s -P workloads/workloadb -p recordcount=100000 -p operationcount=10000000 -threads 4 -p mongodb.url="mongodb://localhost:27017/ycsb_test" -p mongodb.auth="false"
}

@test "check master pod redeploy" {
  #dcos percona-mongo pod replace mongo-rs-1
  #TODO: Redeploy master node, check that the new master was elected
  #TODO: Check that the data loaded in previous test is the same in all nodes
}

@test "do some ycsb load" {
  #TODO: Run some more ycsb load to see that writes are working
  #TODO: Save dbHash for this table on every node
  #Something like:
  #./bin/ycsb.sh run mongodb -s -P workloads/workloadb -p recordcount=100000 -p operationcount=10000000 -threads 4 -p mongodb.url="mongodb://localhost:27017/ycsb_test" -p mongodb.auth="false"
}

@test "check slave pod redeploy" {
  #dcos percona-mongo pod replace mongo-rs-1
  #TODO: Redeploy slave node, check that it was redeployed and not the same as before the test
  #TODO: Check that the data loaded in previous test is the same in all nodes
}

@test "do some ycsb load" {
  #TODO: Run some more ycsb load to see that writes are working
  #TODO: Save dbHash for this table on every node
  #Something like:
  #./bin/ycsb.sh run mongodb -s -P workloads/workloadb -p recordcount=100000 -p operationcount=10000000 -threads 4 -p mongodb.url="mongodb://localhost:27017/ycsb_test" -p mongodb.auth="false"
}

@test "check master pod restart" {
  #dcos percona-mongo pod restart mongo-rs-1
  #TODO: Restart master node, check that it was restarted and not the same as before the test
  #TODO: Check that the data loaded in previous test is the same in all nodes
}

@test "do some ycsb load" {
  #TODO: Run some more ycsb load to see that writes are working
  #TODO: Save dbHash for this table on every node
  #Something like:
  #./bin/ycsb.sh run mongodb -s -P workloads/workloadb -p recordcount=100000 -p operationcount=10000000 -threads 4 -p mongodb.url="mongodb://localhost:27017/ycsb_test" -p mongodb.auth="false"
}

@test "check slave pod restart" {
  #dcos percona-mongo pod restart mongo-rs-1
  #TODO: Restart slave node, check that it was restarted and not the same as before the test
  #TODO: Check that the data loaded in previous test is the same in all nodes
}

@test "do some ycsb load" {
  #TODO: Run some more ycsb load to see that writes are working
  #TODO: Save dbHash for this table on every node
  #Something like:
  #./bin/ycsb.sh run mongodb -s -P workloads/workloadb -p recordcount=100000 -p operationcount=10000000 -threads 4 -p mongodb.url="mongodb://localhost:27017/ycsb_test" -p mongodb.auth="false"
}

@test "check issuing kill -9 on master" {
  #TODO: Kill -9 mongod process on master pod
  #TODO: Check that the node was recreated
  #TODO: Check that the data loaded in previous test is the same in all nodes
}

@test "do some ycsb load" {
  #TODO: Run some more ycsb load to see that writes are working
  #TODO: Save dbHash for this table on every node
  #Something like:
  #./bin/ycsb.sh run mongodb -s -P workloads/workloadb -p recordcount=100000 -p operationcount=10000000 -threads 4 -p mongodb.url="mongodb://localhost:27017/ycsb_test" -p mongodb.auth="false"
}

@test "check issuing kill -9 on slave" {
  #TODO: Kill -9 mongod process on slave pod
  #TODO: Check that the node was recreated
  #TODO: Check that the data loaded in previous test is the same in all nodes
}

@test "do some ycsb load" {
  #TODO: Run some more ycsb load to see that writes are working
  #TODO: Save dbHash for this table on every node
  #Something like:
  #./bin/ycsb.sh run mongodb -s -P workloads/workloadb -p recordcount=100000 -p operationcount=10000000 -threads 4 -p mongodb.url="mongodb://localhost:27017/ycsb_test" -p mongodb.auth="false"
}

# Disabled because of https://github.com/mesosphere/dcos-mongo/issues/249
#@test "destroy service" {
#  run ${DCOS_CLI_BIN} package uninstall percona-mongo --yes
#  [ "$status" -eq 0 ]
#
#  TODO: Add check that all parts are actually destroyed
#}
