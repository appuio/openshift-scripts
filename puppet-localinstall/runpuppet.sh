#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

[ -e /etc/profile.d/proxy.sh ] && source /etc/profile.d/proxy.sh

puppet apply -t --hiera_config ${SCRIPT_DIR}/hiera.yaml --modulepath=${SCRIPT_DIR}/modules ${SCRIPT_DIR}/manifests/site.pp
