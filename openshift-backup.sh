#!/bin/bash

# Note the location of the etcd data directory (or $ETCD_DATA_DIR in the 
# following sections), which depends on how etcd is deployed.
#
# Deployment Type               | Data Directory
# -----------------------------------------------------------------------
# all-in-one cluster            | /var/lib/openshift/openshift.local.etcd
# external etcd (not on master) | /var/lib/etcd
# embedded etcd (on master)     | /var/lib/origin/etcd

ETCD_DATA_DIR="/var/lib/origin/openshift.local.etcd"
BACKUP_DIR="/root/openshift_backup"
BACKUP_DIR_WITH_DATE=${BACKUP_DIR}_$(date +%Y%m%d%H%M)


### Setup
mkdir -p $BACKUP_DIR_WITH_DATE


### Cluster Backup
# Backup certificates and keys
cd /etc/origin/master
tar cf ${BACKUP_DIR_WITH_DATE}/certs-and-keys-$(hostname).tar \
#    master.proxy-client.crt \
#    master.proxy-client.key \
#    proxyca.crt \
#    proxyca.key \
#    master.server.crt \
#    master.server.key \
#    ca.crt \
#    ca.key \
#    master.etcd-client.crt \
#    master.etcd-client.key \
#    master.etcd-ca.crt
#FIXME: Replace with
    *.crt \
    *.key \
    named_certificates/*

#FIXME: According to docs this is only necessary if etcd is running on more than one host
# Restart etcd
#systemctl stop etcd

# Create an etcd backup
etcdctl backup \
    --data-dir $ETCD_DATA_DIR \
    --backup-dir ${BACKUP_DIR_WITH_DATE}/etcd.bak


### Project Backup
for project in $(oc get projects --no-headers | awk '{print $1}')
do
    mkdir -p ${BACKUP_DIR_WITH_DATE}/${project}
    oc export all -o json -n ${project} > ${BACKUP_DIR_WITH_DATE}/${project}/project.json
    oc export rolebindings -o json -n ${project} > ${BACKUP_DIR_WITH_DATE}/${project}/rolebindings.json
    oc get serviceaccount -o json --export=true -n ${project} > ${BACKUP_DIR_WITH_DATE}/${project}/serviceaccount.json
    oc get secret -o json --export=true -n ${project} > ${BACKUP_DIR_WITH_DATE}/${project}/secret.json
    oc get pvc -o json --export=true -n ${project} > pvc.json
done

