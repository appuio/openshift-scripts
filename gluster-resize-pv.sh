#!/bin/bash

# Environment definition
## Define logical/gluster volumes to be resized
gluster_volume[0]="gluster_vol_88"
gluster_volume[1]="gluster_vol_86"

## Define OpenShift persistent volumes to be resized
persistent_volume[0]="gluster-pv88"
persistent_volume[1]="gluster-pv86"

## Define volume group containing the logical/gluster volumes
volume_group="vg_gluster"

## Define new volume size in gigabytes
new_volume_size=2

## Define deploymentConfigs to scale down
deploymentconfig[0]=""
#deploymentconfig[1]=""

## Define project
project=""

## Define gluster nodes (hostnames or IPs)
gluster_node[0]=""
gluster_node[1]=""

## Initialize variables
dc_replicas=()


# Rock'n'roll
## Reset timer
SECONDS=0

## Scale down applications
for ((i=0; i<${#deploymentconfig[@]}; i++)); do
  echo "Scaling down ${deploymentconfig[$i]}"
  dc_replicas[$i]=$(oc get dc ${deploymentconfig[$i]} --output jsonpath='{.status.replicas}' -n $project)
  oc scale --replicas=0 dc ${deploymentconfig[$i]} -n $project
done

## Resize logical volumes
for node in "${gluster_node[@]}"; do
  for vol in "${gluster_volume[@]}"; do
    echo "Resizing gluster volume $vol on node $node"
    ssh $node "lvresize --size ${new_volume_size}g --resizefs /dev/${volume_group}/${vol}"
  done
done

## Resize persistent volume in OpenShift
for pv in "${persistent_volume[@]}"; do
  echo "Patching persistent volume"
  oc patch pv $pv --patch="{\"spec\":{\"capacity\":{\"storage\":\"${new_volume_size}Gi\"}}}"
done

## Scale up applications
for ((i=0; i<${#deploymentconfig[@]}; i++)); do
  echo "Scaling up ${deploymentconfig[$i]} to ${dc_replicas[$i]}"
  oc scale --replicas=${dc_replicas[$i]} dc ${deploymentconfig[$i]} -n $project
done

## Calculate run duration
duration=$SECONDS
echo "Duration was $(($duration / 60)) minutes $(($duration % 60)) seconds"

