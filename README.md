# PSMDB Mesosphere DCOS test repo

**How to use:**
1. Create DCOS AWS stack via cli or web interface
2. Update CONFIG file with all needed info for the cluster that is currently under test
3. Install dcos cli command via `utils/install-dcos-cli.sh`
4. Run ssh-agent:
```
$ ssh-agent
SSH_AUTH_SOCK=/tmp/ssh-7fwywErizl/agent.25571; export SSH_AUTH_SOCK;
SSH_AGENT_PID=21432; export SSH_AGENT_PID;
echo Agent pid 12518;
```
5. Add AWS key to ssh-agent:
```
$ ssh-add .ssh/tomislav-percona-aws-ireland.pem
```
6. Start DCOS vpn tunnel:
```
sudo SSH_AUTH_SOCK=/tmp/ssh-7fwywErizl/agent.25571 dcos tunnel vpn
```
7. Add vpn DNS servers (198.51.100.1 198.51.100.2 198.51.100.3) to /etc/systemd/resolved.conf as DNS and FallbackDNS
8. Run tests and play around

**Test run might look something like this:**
```
~/psmdb-dcos-test/tests$ ./durability-test.bats
 - create new service (skipped)
 - setup and check connection to mongo (skipped)
 ✓ load data in usertable1
 ✓ check master pod redeploy
 ✓ load data in usertable2
 ✓ check slave pod redeploy
 ✓ load data in usertable3
 ✓ check master pod restart
 ✓ load data in usertable4
 ✓ check slave pod restart
 ✓ load data in usertable5
 - check issuing kill -9 on master (skipped: Not implemented yet.)
 ✓ load data in usertable6
 - check issuing kill -9 on slave (skipped: Not implemented yet.)
 ✓ load data in usertable7
 - check updating configuration (skipped: Not implemented yet.)
 ✓ load data in usertable8
 - check scaling up to 5 instances (skipped: Issue: https://github.com/mesosphere/dcos-mongo/issues/258)
 ✓ load data in usertable9
 - check scaling down to 3 instances (skipped: Issue: https://github.com/mesosphere/dcos-mongo/issues/258)
 - destroy service (skipped: Disabled because of https://github.com/mesosphere/dcos-mongo/issues/249)
 ✓ env cleanup

22 tests, 0 failures, 8 skipped
```
