#!/usr/bin/env bash
set -e

# source helpers
TOOL_DIR=$(dirname $0)
source ${TOOL_DIR}/src/print.sh
source ${TOOL_DIR}/src/install-helpers.sh

# usage info
if [ "$#" != "1" ]; then
    echo
    echo "Usage: $0 <new-hostname>"
    echo
    echo "Updates /etc/wsl.conf and /etc/hosts with the new hostname."
    echo "Requires a restart for changes to take effect."
    echo
    echo "Eg:"
    echo "  $0 my-dev-box"
    echo
    exit 1
fi

# update hostname
updateHostname $1 