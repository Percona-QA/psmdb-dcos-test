#
source ../CONFIG

if [ "${DCOS_TEST_VER}" = "1.11" ]; then
  TEMPLATE="../templates/psmdb-dcos-11-config.json"
else
  TEMPLATE="../templates/psmdb-dcos-10-config.json"
fi

get_nr_nodes() {
  local FUN_DCOS_SERVICE_NAME="$1"
  ${DCOS_CLI_BIN} ${FUN_DCOS_SERVICE_NAME} endpoints mongo-port|jq .dns|grep -c "${MONGODB_PORT}\""
}

get_node_address() {
  local FUN_DCOS_SERVICE_NAME="$1"
  local FUN_NODE_NUMBER="$2"
  ${DCOS_CLI_BIN} ${FUN_DCOS_SERVICE_NAME} endpoints mongo-port|jq -r .dns[${FUN_NODE_NUMBER}]
}

get_node_address_full() {
  local FUN_DCOS_SERVICE_NAME="$1"
  local FUN_NODE_NUMBER="$2"
  local FUN_NODE_ADDRESS=$(${DCOS_CLI_BIN} ${FUN_DCOS_SERVICE_NAME} endpoints mongo-port|jq -r .dns[${FUN_NODE_NUMBER}])
  echo "mongodb://${FUN_NODE_ADDRESS}/?authSource=admin"
}

get_rs_address() {
  local FUN_DCOS_SERVICE_NAME="$1"
  local FUN_NODE1_ADDRESS=$(get_node_address ${FUN_DCOS_SERVICE_NAME} "0")
  local FUN_NODE2_ADDRESS=$(get_node_address ${FUN_DCOS_SERVICE_NAME} "1")
  local FUN_NODE3_ADDRESS=$(get_node_address ${FUN_DCOS_SERVICE_NAME} "2")
  echo "mongodb://${FUN_NODE1_ADDRESS},${FUN_NODE2_ADDRESS},${FUN_NODE3_ADDRESS}/?replicaSet=${RS_NAME}&authSource=admin"
}

get_rs_address_test() {
  local FUN_DCOS_SERVICE_NAME="$1"
  local FUN_NODE1_ADDRESS=$(get_node_address ${FUN_DCOS_SERVICE_NAME} "0")
  local FUN_NODE2_ADDRESS=$(get_node_address ${FUN_DCOS_SERVICE_NAME} "1")
  local FUN_NODE3_ADDRESS=$(get_node_address ${FUN_DCOS_SERVICE_NAME} "2")
  echo "mongodb://${MONGODB_TEST_USER}:${MONGODB_TEST_PASS}@${FUN_NODE1_ADDRESS},${FUN_NODE2_ADDRESS},${FUN_NODE3_ADDRESS}/${MONGODB_TEST_DB}?replicaSet=${RS_NAME}&authSource=admin"
}

get_dcos_service_id() {
  local FUN_DCOS_SERVICE_NAME="$1"
  echo $(${DCOS_CLI_BIN} service|grep "${FUN_DCOS_SERVICE_NAME}"|awk -F' ' '{print $7}')
}

get_dcos_service_active_status() {
  local FUN_DCOS_SERVICE_NAME="$1"
  echo $(${DCOS_CLI_BIN} service|grep "${FUN_DCOS_SERVICE_NAME}"|awk -F' ' '{print $2}')
}

get_dcos_service_nr_tasks() {
  local FUN_DCOS_SERVICE_NAME="$1"
  echo $(${DCOS_CLI_BIN} service|grep "${FUN_DCOS_SERVICE_NAME}"|awk -F' ' '{print $3}')
}

get_master_pod() {
  local FUN_DCOS_SERVICE_NAME="$1"
  ${MONGO_BIN} "$(get_rs_address_test ${FUN_DCOS_SERVICE_NAME})" --eval 'db.isMaster().primary' | tail -n1 | awk -F'-' '{print $1"-"$2"-"$3}'
}

get_pod_names() {
  local FUN_DCOS_SERVICE_NAME="$1"
  ${DCOS_CLI_BIN} ${FUN_DCOS_SERVICE_NAME} pod list|grep "mongo"|sed 's/ //g'|sed 's/"//g'|sed 's/,//g'
}

get_slave_pod() {
  local FUN_DCOS_SERVICE_NAME="$1"
  local MASTER_POD="$(get_master_pod ${FUN_DCOS_SERVICE_NAME})"
  local ALL_PODS="$(get_pod_names ${FUN_DCOS_SERVICE_NAME})"
  for pod in ${ALL_PODS}; do
    if [ ${pod} != "${MASTER_POD}" ]; then
      echo "${pod}"
      break
    fi
  done
}

get_pod_agent() {
  local FUN_DCOS_SERVICE_NAME="$1"
  local FUN_DCOS_POD_NAME="$2"
  ${DCOS_CLI_BIN} ${FUN_DCOS_SERVICE_NAME} pod info ${FUN_DCOS_POD_NAME} | jq -r ".[] | select(.info.name == \"${FUN_DCOS_POD_NAME}-mongod\") | .info.slaveId.value"
}

load_data() {
  local FUN_DCOS_SERVICE_NAME="$1"
  local FUN_TABLE_NAME="$2"
  local RECORD_COUNT="10000"

  run bash -c "${MONGO_BIN} '$(get_rs_address_test ${FUN_DCOS_SERVICE_NAME})' --eval \"db.${FUN_TABLE_NAME}.drop()\""
  [ "$status" -eq 0 ]

  run bash -c "${YCSB_BIN} load mongodb -s -P ${YCSB_BASE_DIR}/workloads/workloada -p recordcount=${RECORD_COUNT} -p table=\"${FUN_TABLE_NAME}\" -threads 64 -p mongodb.url=\"$(get_rs_address_test ${FUN_DCOS_SERVICE_NAME})\" -p mongodb.auth=\"true\""
  [ "$status" -eq 0 ]

  run bash -c "${MONGO_BIN} '$(get_rs_address_test ${FUN_DCOS_SERVICE_NAME})' --eval \"db.${FUN_TABLE_NAME}.count()\" | tail -n1"
  [ "$output" = "${RECORD_COUNT}" ]

  rm -f testdb-md5-${FUN_DCOS_SERVICE_NAME}.tmp
  run bash -c "${MONGO_BIN} '$(get_node_address_full ${FUN_DCOS_SERVICE_NAME} 0)' --username ${MONGODB_TEST_USER} --password ${MONGODB_TEST_PASS} --eval 'db.runCommand({ dbHash: 1 }).md5' | tail -n1 > testdb-md5-${FUN_DCOS_SERVICE_NAME}.tmp"
}

load_check_hash() {
  local FUN_DCOS_SERVICE_NAME="$1"
  local TESTDB_MD5=$(cat testdb-md5-${FUN_DCOS_SERVICE_NAME}.tmp)

  run bash -c "${MONGO_BIN} '$(get_node_address_full ${FUN_DCOS_SERVICE_NAME} 0)' --username ${MONGODB_TEST_USER} --password ${MONGODB_TEST_PASS} --eval 'db.runCommand({ dbHash: 1 }).md5' | tail -n1"
  [ "$output" = "${TESTDB_MD5}" ]

  run bash -c "${MONGO_BIN} '$(get_node_address_full ${FUN_DCOS_SERVICE_NAME} 1)' --username ${MONGODB_TEST_USER} --password ${MONGODB_TEST_PASS} --eval 'db.runCommand({ dbHash: 1 }).md5' | tail -n1"
  [ "$output" = "${TESTDB_MD5}" ]

  run bash -c "${MONGO_BIN} '$(get_node_address_full ${FUN_DCOS_SERVICE_NAME} 2)' --username ${MONGODB_TEST_USER} --password ${MONGODB_TEST_PASS} --eval 'db.runCommand({ dbHash: 1 }).md5' | tail -n1"
  [ "$output" = "${TESTDB_MD5}" ]
}
