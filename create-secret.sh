cat <<EOF # | oc create -f -
{
    "kind": "Secret",
    "apiVersion": "v1",
    "metadata": {
        "name": "$1"
    },
    "data": {
        "`basename $2`": "`base64 -w0 <$2`"
    }
}
EOF
