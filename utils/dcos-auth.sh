#!/usr/bin/env bash
# http://blog.originate.com/blog/2017/04/27/continuous-delivery-to-dcos-from-circleci/

set -euo pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Check that all required variables are set
for NAME in GH_USERNAME GH_PASSWORD; do
  eval VALUE=\$$NAME
  if [[ -z ${VALUE+x} ]]; then
    echo "$NAME is not set, moving on"
    exit 0
  fi
done

if [[ ! -z ${VERBOSE+x} ]]; then
  set -x
fi

CLUSTER_URL="$1"

# Setup the DC/OS CLI
## Point it to the DC/OS cluster. CLUSTER_URL is the URL of the admin dashboard
dcos config set core.dcos_url "$CLUSTER_URL"

## Set the ACS token. dcos-login reads GH_USERNAME and GH_PASSWORD from the environment automatically
dcos config set core.dcos_acs_token "$(dcos-login --cluster-url "$CLUSTER_URL")"
