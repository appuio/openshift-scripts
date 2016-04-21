#!/bin/sh

HTTP_PROXY=$http_proxy
HTTPS_PROXY=$https_proxy
NO_PROXY=$no_proxy

json_env="[{\"name\": \"http_proxy\", \"value\": \"${HTTP_PROXY}\" }, {\"name\": \"https_proxy\", \"value\": \"${HTTPS_PROXY}\"}, {\"name\": \"no_proxy\", \"value\": \"${NO_PROXY}\"}]"

jq "(. | select(.kind == \"BuildConfig\").spec.source.git.httpProxy)=\"${HTTP_PROXY}\"" | \
jq "(. | select(.kind == \"BuildConfig\").spec.source.git.httpsProxy)=\"${HTTPS_PROXY}\"" | \
jq "(. | select(.kind == \"BuildConfig\").spec.strategy.customStrategy.env)=${json_env}"
#jq "(.objects[] | select(.kind == \"BuildConfig\").spec.source.git.httpProxy)=\"${HTTP_PROXY}\"" | \
#jq "(.objects[] | select(.kind == \"BuildConfig\").spec.source.git.httpsProxy)=\"${HTTPS_PROXY}\"" | \
#jq "(.objects[] | select(.kind == \"BuildConfig\").spec.strategy.sourceStrategy.env)=${json_env}" | \
#jq "del(.objects[] | select(.kind == \"DeploymentConfig\").spec.template.spec.containers[0].env[] | select(.name == \"http_proxy\" or .name == \"https_proxy\" or .name == \"no_proxy\"))" | \
#jq "(.objects[] | select(.kind == \"DeploymentConfig\").spec.template.spec.containers[0].env)+=${json_env}"
