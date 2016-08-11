#!/bin/bash

set -o pipefail

vol_nr=0
gluster_name="glusterfs-cluster"

# Set GlusterFS nodes and IP addresses
nodes[0]=
nodes[1]=
nodes_ip[0]=
nodes_ip[0]=

# OSE projects in which the endpoint will be created
projects[0]=default
projects[1]=openshift-infra
projects[2]=logging


create_gluster_brick() {
  vol_name=$1
  vol_size=$2
  node=$3

  if ! ssh $node test -b "/dev/vg_gluster/$vol_name"; then
    ssh $node lvcreate --name $vol_name --size ${vol_size}Gi vg_gluster -y >/dev/null 2>&1

    ssh $node mkfs.xfs -i size=512 /dev/vg_gluster/$vol_name >/dev/null 2>&1
  else
    echo "ERROR: Failed to create logical volume /dev/vg_gluster/$vol_name. Volume already exists. Aborting."
    exit 1
  fi  
  
  ssh $node 'echo "/dev/vg_gluster/$vol_name /data/$vol_name xfs noatime 0 0" >> /etc/fstab'
  
  if ! ssh $node test -d "/data/$vol_name"; then
    ssh $node mkdir -p /data/$vol_name/brick
  fi  

  ssh $node mount /dev/vg_gluster/$vol_name /data/$vol_name
}


create_gluster_volume() {
  vol_name=$1
  vol_size=$2

  # Create gluster volume if it doesn't yet exist
  if ! ssh ${nodes[0]} gluster volume list | grep $vol_name >/dev/null 2>&1; then

    for node in "${nodes[@]}"; do
      # Create gluster brick if it doesn't yet exist
      if ! create_gluster_brick $vol_name $vol_size $node; then
        echo "ERROR: Failed to create gluster brick on node ${node}. Aborting."
        exit 1
      fi
    done

    if ! ssh ${nodes[0]} gluster volume create $vol_name replica ${#nodes[@]} ${nodes[@]/%/:\/data\/$vol_name\/brick} >/dev/null 2>&1; then
      echo "ERROR: Failed to create gluster volume $vol_name. Aborting."
      exit 1
    fi
  fi

  if ! ssh ${nodes[0]} gluster volume info $vol_name | grep "Status: Started" >/dev/null 2>&1; then
    if ! ssh ${nodes[0]} gluster volume start $vol_name >/dev/null 2>&1; then
      echo "ERROR: Failed to start gluster volume $vol_name. Aborting."
      exit 1
    fi
  fi

  for node in "${nodes[@]}"; do
    ssh $node "chmod -R 777 /data/$vol_name/"
  done
}


create_persistent_volume() {

  vol_size=$1
  vol_nr=$((vol_nr+1))
  vol_name="gluster_vol_${vol_nr}"

  if ! create_gluster_volume $vol_name ${vol_size}; then
    echo "ERROR: Failed to create gluster volume. Aborting."
    exit 1
  else
    echo "  Successfully created gluster volume $vol_name on ${#nodes[@]} nodes (${nodes[@]})."
  fi

  # Create Gluster Service
  if ! oc get -n default services ${gluster_name} >/dev/null 2>&1; then
cat <<-EOF | oc create -n default -f -
  {
    "apiVersion": "v1",
    "kind": "Service",
    "metadata": {
      "name": "${gluster_name}"
    },
    "spec": {
      "ports": [
        {
          "port": 1
        }
      ]
    }
  }
EOF
  else
    echo "service ${gluster_name} already exists. Skipping."
  fi

  # Create Gluster Endpoints
  for project in "${projects[@]}"; do
    if ! oc get -n ${project} endpoints ${gluster_name} >/dev/null 2>&1; then
cat <<-EOF | oc create -n ${project} -f -
{
  "apiVersion": "v1",
  "kind": "Endpoints",
  "metadata": {
    "name": "${gluster_name}"
  },
  "subsets": [
      {
          "addresses": [
              {
                  "ip": "${nodes_ip[0]}"
              },
              {
                  "ip": "${nodes_ip[1]}"
              }
          ],
          "ports": [
              {
                  "port": 1,
                  "protocol": "TCP"
              }
          ]
      }
  ]
}
EOF
    else
      echo "endpoint ${gluster_name} already exists. Skipping."
    fi
  done

  # create persistent volume
  if ! oc get -n default persistentvolumes gluster-pv${vol_nr} >/dev/null 2>&1; then
cat <<-EOF | oc create -n default -f -
  {
    "apiVersion": "v1",
    "kind": "PersistentVolume",
    "metadata": {
      "name": "gluster-pv${vol_nr}"
    },
    "spec": {
      "capacity": {
        "storage": "${vol_size}Gi"
      },
      "accessModes": [
        "ReadWriteOnce",
        "ReadWriteMany"
      ],
      "glusterfs": {
        "endpoints": "${gluster_name}",
        "path": "/gluster_vol_${vol_nr}",
        "readOnly": false
      },
      "persistentVolumeReclaimPolicy": "Recycle"
    }
  }
EOF
  else
    echo "ERROR: OpenShift persistent volume already exists. This seems wrong. Aborting."
    exit 1
  fi
} 

# Check if executed as root
if [[ $EUID -ne 0 ]]; then
  echo "ERROR: This script must be run as root. Aborting."
  exit 1
fi

# Check if executed on OSE master
if ! systemctl status atomic-openshift-master >/dev/null 2>&1; then
  echo "ERROR: This script must be run on an OpenShift master. Aborting."
  exit 1
fi

# Create persistent volumes for:
# - Docker registry
create_persistent_volume 50

# - Logging
create_persistent_volume 20

# - Metrics
create_persistent_volume 20

# fill up to 100G
for i in `seq 1 25`; do
  create_persistent_volume 1
done

create_persistent_volume 1

# Finally restart gluster daemon so file permissions change takes effect
for node in "${nodes[@]}"; do
  ssh $node systemctl restart glusterd
done
