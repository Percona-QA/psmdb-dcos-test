#
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "$DIR/../CONFIG"

if [ "${DCOS_TEST_VER%-*}" = "1.11" ]; then
  TEMPLATE="../templates/psmdb-dcos-11-config.json"
else
  TEMPLATE="../templates/psmdb-dcos-10-config.json"
fi

get_nr_nodes() {
  local FUN_DCOS_SERVICE_NAME="$1"
  ${DCOS_CLI_BIN} ${FUN_DCOS_SERVICE_NAME} endpoints mongo-port|jq -r .dns|grep -c "${MONGODB_PORT}"
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
  local FUN_MONGO_RS_SIZE=$(($2-1))
  local ADDRESS=""
  
  for node in `seq 0 $FUN_MONGO_RS_SIZE`; do
    ADDRESS="${ADDRESS},$(get_node_address ${FUN_DCOS_SERVICE_NAME} "${node}")"
  done
  ADDRESS=${ADDRESS#","}
  echo "mongodb://${ADDRESS}/?replicaSet=${RS_NAME}&authSource=admin"
}

get_rs_address_test() {
  local FUN_DCOS_SERVICE_NAME="$1"
  local FUN_MONGO_RS_SIZE=$(($2-1))
  local ADDRESS=""
  
  for node in `seq 0 $FUN_MONGO_RS_SIZE`; do
    ADDRESS="${ADDRESS},$(get_node_address ${FUN_DCOS_SERVICE_NAME} "${node}")"
  done
  ADDRESS=${ADDRESS#","}
  echo "mongodb://${MONGODB_TEST_USER}:${MONGODB_TEST_PASS}@${ADDRESS}/${MONGODB_TEST_DB}?replicaSet=${RS_NAME}&authSource=admin"
}

get_dcos_service_id() {
  local FUN_DCOS_SERVICE_NAME="$1"
  echo $(${DCOS_CLI_BIN} service|grep "${FUN_DCOS_SERVICE_NAME}"|awk -F' ' '{print $7}')
}

get_dcos_service_active_status() {
  local FUN_DCOS_SERVICE_NAME="$1"
  if [ "${DCOS_TEST_VER%-*}" = "1.10" ]; then
    echo $(${DCOS_CLI_BIN} service|grep "${FUN_DCOS_SERVICE_NAME}"|awk -F' ' '{print $3}')
  else
    echo $(${DCOS_CLI_BIN} service|grep "${FUN_DCOS_SERVICE_NAME}"|awk -F' ' '{print $2}')
  fi
}

get_dcos_service_nr_tasks() {
  local FUN_DCOS_SERVICE_NAME="$1"
  if [ "${DCOS_TEST_VER%-*}" = "1.10" ]; then
    echo $(${DCOS_CLI_BIN} service|grep "${FUN_DCOS_SERVICE_NAME}"|awk -F' ' '{print $4}')
  else
    echo $(${DCOS_CLI_BIN} service|grep "${FUN_DCOS_SERVICE_NAME}"|awk -F' ' '{print $3}')
  fi
}

get_master_pod() {
  local FUN_DCOS_SERVICE_NAME="$1"
  local FUN_MONGO_RS_SIZE="$2"
  ${MONGO_BIN} "$(get_rs_address_test ${FUN_DCOS_SERVICE_NAME} ${FUN_MONGO_RS_SIZE})" --eval 'db.isMaster().primary' | tail -n1 | awk -F'-' '{print $1"-"$2"-"$3}'
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

get_task_id() {
  local FUN_DCOS_SERVICE_NAME="$1"
  local FUN_DCOS_POD_NAME="$2"
  ${DCOS_CLI_BIN} ${FUN_DCOS_SERVICE_NAME} pod info ${FUN_DCOS_POD_NAME} | jq -r ".[] | select(.info.name == \"${FUN_DCOS_POD_NAME}-mongod\") | .info.taskId.value"
}

load_data() {
  local FUN_DCOS_SERVICE_NAME="$1"
  local FUN_MONGO_RS_SIZE="$2"
  local FUN_TABLE_NAME="$3"
  local RECORD_COUNT="10000"

  run bash -c "${MONGO_BIN} '$(get_rs_address_test ${FUN_DCOS_SERVICE_NAME} ${FUN_MONGO_RS_SIZE})' --eval \"db.${FUN_TABLE_NAME}.drop()\""
  [ "$status" -eq 0 ]

  run bash -c "${YCSB_BIN} load mongodb -s -P ${YCSB_BASE_DIR}/workloads/workloada -p recordcount=${RECORD_COUNT} -p table=\"${FUN_TABLE_NAME}\" -threads 64 -p mongodb.url=\"$(get_rs_address_test ${FUN_DCOS_SERVICE_NAME} ${FUN_MONGO_RS_SIZE})\" -p mongodb.auth=\"true\""
  [ "$status" -eq 0 ]

  run bash -c "${MONGO_BIN} '$(get_rs_address_test ${FUN_DCOS_SERVICE_NAME} ${FUN_MONGO_RS_SIZE})' --eval \"db.${FUN_TABLE_NAME}.count()\" | tail -n1"
  [ "$output" = "${RECORD_COUNT}" ]

  rm -f testdb-md5-${FUN_DCOS_SERVICE_NAME}.tmp
  run bash -c "${MONGO_BIN} '$(get_node_address_full ${FUN_DCOS_SERVICE_NAME} 0)' --username ${MONGODB_TEST_USER} --password ${MONGODB_TEST_PASS} --eval 'db.runCommand({ dbHash: 1 }).md5' | tail -n1 > testdb-md5-${FUN_DCOS_SERVICE_NAME}.tmp"
}

load_check_hash() {
  local FUN_DCOS_SERVICE_NAME="$1"
  local FUN_MONGO_RS_SIZE=$(($2-1))
  local TESTDB_MD5=$(cat testdb-md5-${FUN_DCOS_SERVICE_NAME}.tmp)

  for node in `seq 0 $FUN_MONGO_RS_SIZE`; do
    run bash -c "${MONGO_BIN} '$(get_node_address_full ${FUN_DCOS_SERVICE_NAME} ${node})' --username ${MONGODB_TEST_USER} --password ${MONGODB_TEST_PASS} --eval 'db.runCommand({ dbHash: 1 }).md5' | tail -n1"
    [ "$output" = "${TESTDB_MD5}" ]
  done
}

check_rs_health() {
  local FUN_DCOS_SERVICE_NAME="$1"
  local FUN_MONGO_RS_SIZE=$(($2-1))
  local NR_NODES=0
  local NODE_STATE=0
  
  local RS_STATUS=$(${MONGO_BIN} "$(get_rs_address_test ${FUN_DCOS_SERVICE_NAME} ${FUN_MONGO_RS_SIZE})" --eval 'JSON.stringify(rs.status())' | sed -n '/{/,$p')
  local NR_NODES=$(echo "${RS_STATUS}" | jq '.members | length')
  [ "$NR_NODES" = "$((${FUN_MONGO_RS_SIZE}+1))" ]

  for node in `seq 0 $FUN_MONGO_RS_SIZE`; do
    NODE_STATE=$(echo "${RS_STATUS}" | jq ".members[${node}].health")
    [ "$NODE_STATE" = "1" ]

    NODE_STATE=$(echo "${RS_STATUS}" | jq ".members[${node}].state")
    [ "$NODE_STATE" = "1" -o "$NODE_STATE" = "2" ]
  done
}
