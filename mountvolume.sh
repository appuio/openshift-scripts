POD_NAME="$1"
AMOUNT="$2"
MOUNT_PATH="$3"

cat <<EOF >/dev/null #| oc create -f -
{
    "apiVersion": "v1",
    "kind": "PersistentVolumeClaim",
    "metadata": {
        "name": "${POD_NAME}-storage"
    },
    "spec": {
        "accessModes": [ "ReadWriteOnce" ],
        "resources": {
            "requests": {
                "storage": "${AMOUNT}"
            }
        }
    }
}
EOF

oc get dc/${POD_NAME} -o json | jq ".spec.template.spec.volumes=[{\"name\": \"${POD_NAME}-storage\", \"persistentVolumeClaim\": {\"claimName\": \"${POD_NAME}-storage\"}}]" \
  | jq ".spec.template.spec.containers[0].volumeMounts=[{\"name\": \"${POD_NAME}-storage\", \"mountPath\": \"${MOUNT_PATH}\"}]" \
  | oc replace dc/${POD_NAME} -f -
