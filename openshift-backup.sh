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
    *.crt \
    *.key \
    named_certificates/*

#FIXME: According to docs this is only necessary if etcd is running on more than one host
# Stop etcd
#systemctl stop etcd

# Create an etcd backup
etcdctl backup \
    --data-dir $ETCD_DATA_DIR \
    --backup-dir ${BACKUP_DIR_WITH_DATE}/etcd.bak

# Start etcd again
#systemctl start etcd


### Project Backup
# Check if executed as OSE system:admin
if [[ "$(oc whoami)" != "system:admin" ]]; then
  echo -n "Trying to log in as system:admin... "
  oc login -u system:admin > /dev/null && echo "done."
fi

# Backup all resources of every project
for project in $(oc get projects --no-headers | awk '{print $1}')
do
    mkdir -p ${BACKUP_DIR_WITH_DATE}/projects/${project}
    oc export all -o json -n ${project} > ${BACKUP_DIR_WITH_DATE}/projects/${project}/project.json 2>/dev/null
    oc export rolebindings -o json -n ${project} > ${BACKUP_DIR_WITH_DATE}/projects/${project}/rolebindings.json 2>/dev/null
    oc get serviceaccount -o json --export=true -n ${project} > ${BACKUP_DIR_WITH_DATE}/projects/${project}/serviceaccount.json 2>/dev/null
    oc get secret -o json --export=true -n ${project} > ${BACKUP_DIR_WITH_DATE}/projects/${project}/secret.json 2>/dev/null
    oc get pvc -o json --export=true -n ${project} > pvc.json 2>/dev/null
done

