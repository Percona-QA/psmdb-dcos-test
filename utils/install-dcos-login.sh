#!/usr/bin/env bash
# http://blog.originate.com/blog/2017/04/27/continuous-delivery-to-dcos-from-circleci/

set -euo pipefail

if [[ ! -z ${VERBOSE+x} ]]; then
  set -x
fi

BINS="$HOME/.local/bin"

DCOS_LOGIN="$BINS/dcos-login"

# Returns the version of the currently installed dcos-login binary. e.g v0.24
installed_version() {
  dcos-login --version 2>&1
}

# Returns the version of the latest release of the dcos-login binary. e.g v0.24
latest_version() {
  curl -sSL https://api.github.com/repos/Originate/dcos-login/releases/latest | jq -r '.name'
}

# Downloads the latest version of the dcos-login binary for linux to the cache
install_dcos_login() {
  mkdir -p "$BINS"

  LATEST_RELEASE="$(curl -sSL https://api.github.com/repos/Originate/dcos-login/releases/latest)"
  DOWNLOAD_URL=$(jq -r '.assets[] | select(.name == "dcos-login_linux_amd64") | .url' <<< "$LATEST_RELEASE")

  curl -sSL -H 'Accept: application/octet-stream' "$DOWNLOAD_URL" -o "$DCOS_LOGIN"
  chmod u+x "$DCOS_LOGIN"
}

# Install dcos-login if it's missing. If it's present, upgrade it if needed otherwise do nothing
if [ ! -e "$DCOS_LOGIN" ]; then
  echo "dcos-login not found. Installing"
  install_dcos_login
else
  INSTALLED_VERSION="$(installed_version)"
  LATEST_VERSION="$(latest_version)"
  if [ "$LATEST_VERSION" != "$INSTALLED_VERSION" ]; then
    echo "dcos-login has version $INSTALLED_VERSION, latest is $LATEST_VERSION. Upgrading"
    rm -rf "$DCOS_LOGIN"
    install_dcos_login
  else
    echo "Using cached dcos-login $INSTALLED_VERSION"
  fi
fi
