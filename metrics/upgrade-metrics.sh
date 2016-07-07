#!/bin/sh
# Set the following Env variables to configure update 
# clone origin metrics project https://github.com/openshift/origin-metrics
#
# export IMAGE_PREFIX=registry.access.redhat.com/openshift3/
# export HAWKULAR_METRICS_HOSTNAME=metrics.example.com
# export CASSANDRA_PV_SIZE=50Gi

oc process -f origin-metrics/metrics.yaml -v "IMAGE_PREFIX=$IMAGE_PREFIX,IMAGE_VERSION=3.2.1,HAWKULAR_METRICS_HOSTNAME=$HAWKULAR_METRICS_HOSTNAME,USE_PERSISTENT_STORAGE=true,CASSANDRA_PV_SIZE=$CASSANDRA_PV_SIZE,METRIC_DURATION=3,MODE=refresh" | \
oc create -n openshift-infra -f -
