#!/bin/bash
# Cleanup all E2E and ops indices

set -e -o pipefail -u

es_curl() {
  oc -n logging rsh --no-tty "${es_pod}" \
    curl \
      --silent \
      --show-error \
      --key /etc/elasticsearch/secret/admin-key \
      --cert /etc/elasticsearch/secret/admin-cert \
      --cacert /etc/elasticsearch/secret/admin-ca \
      "$@"
}

echo "Cleaning up logging indices for $(oc whoami --show-server)"

export es_pod=$(oc -n logging get pods -l component=es -o name | head -n 1)

e2e_indices="$(
  es_curl 'https://localhost:9200/_aliases' \
    | jq '. | with_entries(select(.key | startswith("project.(bd|e2e)-"))) | keys ' \
    | grep '"' | cut -d '"' -f2
)" || :

for idx in $e2e_indices; do
  es_curl -XDELETE "https://localhost:9200/${idx}/" | grep -v '{"acknowledged":true}' || :
  echo -n '.'
done

echo 'done!'
es_curl 'https://localhost:9200/_cluster/health?pretty'
