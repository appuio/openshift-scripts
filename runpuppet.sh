[ -e /etc/profile.d/proxy.sh ] && source /etc/profile.d/proxy.sh

puppet apply -t --hiera_config /root/openshift-scripts/hiera.yaml --modulepath=/root/openshift-scripts/modules /root/openshift-scripts/manifests/site.pp
