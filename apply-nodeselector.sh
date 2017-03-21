#!/bin/bash

set -e

usage() {
  echo "Usage: $0 <nodeselector> <resource>..."
  echo
  echo "example: $0 region=zrh dc/myapp dc/myapp2"
}

main() {
  if [[ $# -lt 2 ]]; then
    usage >&2
    exit 1
  fi

  IFS='=' read -ra parts <<< "$1"
  local label="${parts[0]}"
  local value="${parts[1]}"
  shift

  local patch=$(
    jq --null-input -c \
      --arg lbl "${label}" \
      --arg value "${value}" \
      '{
        "spec":{
          "template":{
            "spec":{
              "nodeSelector":{
                ($lbl): $value
              }
            }
          }
        }
      }'
  )

  set -x
  oc patch -p "${patch}" -- "$@"
}

main $@
