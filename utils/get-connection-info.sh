#!/usr/bin/env bash
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "$DIR/../tests/common-func.bash"

echo "GENERAL URI:"
echo -e "$(get_rs_address ${SERVICE_NAME} ${RS_SIZE})\n"

echo "URI WITH MONGO COMMAND:"
echo -e "${MONGO_BIN} '$(get_rs_address ${SERVICE_NAME} ${RS_SIZE})'\n"

echo "COMMAND TO ADD TEST USER:"
echo -e "${MONGO_BIN} '$(get_rs_address ${SERVICE_NAME} ${RS_SIZE})' --username useradmin --password test123456 --eval \"db.getSiblingDB('admin').createUser({ user: '${MONGODB_TEST_USER}', pwd: '${MONGODB_TEST_PASS}', roles: [ 'readWrite', 'dbAdmin', 'root' ] })\"\n"

echo "URI WITH TEST USER:"
echo -e "$(get_rs_address_test ${SERVICE_NAME} ${RS_SIZE})\n"

echo "URI WITH TEST USER AND MONGO COMMAND:"
echo -e "${MONGO_BIN} '$(get_rs_address_test ${SERVICE_NAME} ${RS_SIZE})'\n"
