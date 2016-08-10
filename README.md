# openshift-scripts
Loose collection of different scripts for OpenShift.

## gluster-recycle-pv.sh
Description: Recycles Gluster PVs that are in failed state.

Usage: 
* Either specify a PV (-p) or let the script take all (-a) failed PVs.

Requirements:
* You need to execute the script as root on the openshift master.
* Before using this script, add one node IP of your Gluster cluster so the script can mount the underlying Gluster volume (`gluster_node_ip`).
* The script tries to mount the volume as glusterfs, so glusterfs packages need to be installed. Either install them or change to mount them as nfs.
