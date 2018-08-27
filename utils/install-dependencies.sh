#/usr/bin/env bash
# works only on ubuntu
pushd ~
sudo apt-get update
sudo apt-get install bats jq default-jre

# PSMDB
wget https://www.percona.com/downloads/percona-server-mongodb-LATEST/percona-server-mongodb-3.6.6-1.4/binary/tarball/percona-server-mongodb-3.6.6-1.4-xenial-x86_64.tar.gz
tar xf percona-server-mongodb-3.6.6-1.4-xenial-x86_64.tar.gz
rm -f percona-server-mongodb-3.6.6-1.4-xenial-x86_64.tar.gz

# YCSB
wget https://github.com/brianfrankcooper/YCSB/releases/download/0.15.0/ycsb-mongodb-binding-0.15.0.tar.gz
tar xf ycsb-mongodb-binding-0.15.0.tar.gz
rm -f ycsb-mongodb-binding-0.15.0.tar.gz
popd
