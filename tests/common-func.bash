#
source ../CONFIG

if [ "${DCOS_TEST_VER}" = "1.11" ]; then
  TEMPLATE="../templates/psmdb-dcos-11-config.json"
else
  TEMPLATE="../templates/psmdb-dcos-10-config.json"
fi

get_nr_nodes() {
  local FUN_DCOS_SERVICE_NAME="$1"
  ${DCOS_CLI_BIN} ${FUN_DCOS_SERVICE_NAME} endpoints mongo-port|jq .address|grep -c "27017\""
}

get_node_address() {
  local FUN_DCOS_SERVICE_NAME="$1"
  local FUN_NODE_NUMBER="$2"
  ${DCOS_CLI_BIN} ${FUN_DCOS_SERVICE_NAME} endpoints mongo-port|jq -r .address[${FUN_NODE_NUMBER}]
}

get_node_address_full() {
  local FUN_DCOS_SERVICE_NAME="$1"
  local FUN_NODE_NUMBER="$2"
  local FUN_NODE_ADDRESS=$(${DCOS_CLI_BIN} ${FUN_DCOS_SERVICE_NAME} endpoints mongo-port|jq -r .address[${FUN_NODE_NUMBER}])
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

