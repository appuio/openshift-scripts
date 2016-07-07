#!/bin/sh
# Set the following Env variables to configure update 
# export KIBANA_HOSTNAME=logging.example.com
# export KIBANA_OPS_HOSTNAME=logging-ops.example.com
# export PUBLIC_MASTER_URL=https://master.example.com
# export OAP_PUBLIC_MASTER_URL=https://master.example.com
# export OAP_LOGOUT_REDIRECT=https://master.example.com/console/logout

echo \
    '{"kind":"ServiceAccount","apiVersion":"v1","metadata":{"name":"aggregated-logging-curator"}}' \
    | oc create -n logging -f -

oc new-app -n logging logging-deployer-template \
       -p KIBANA_HOSTNAME=$KIBANA_HOSTNAME \
       -p KIBANA_OPS_HOSTNAME=$KIBANA_OPS_HOSTNAME \
       -p ES_CLUSTER_SIZE=1 \
       -p ES_OPS_CLUSTER_SIZE=1 \
       -p PUBLIC_MASTER_URL=$PUBLIC_MASTER_URL \
       -p ES_INSTANCE_RAM=2G \
       -p ES_OPS_INSTANCE_RAM=2G \
       -p ENABLE_OPS_CLUSTER=true \
       -p MODE=upgrade \
       -p OAP_PUBLIC_MASTER_URL=$OAP_PUBLIC_MASTER_URL \
#       -p OAP_LOGOUT_REDIRECT=$OAP_LOGOUT_REDIRECT

#IMAGE_PREFIX=${image_prefix}${image_version}
