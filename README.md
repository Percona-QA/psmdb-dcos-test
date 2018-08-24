# psmdb-dcos-test
PSMDB Mesosphere DCOS test repo

How to use:
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
