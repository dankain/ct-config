#!/bin/bash

args=$*

if [ "${args}x" = "x" ]; then
    echo "No arguments are present"
    exit 1
fi

docker run \
    --env CTP_PROJECT_KEY \
    --env CTP_CLIENT_SECRET \
    --env CTP_CLIENT_ID \
    --env CTP_AUTH_URL \
    --env CTP_API_URL \
    --env CTP_SCOPES \
    --env AWS_ACCESS_KEY_ID \
    --env AWS_SECRET_ACCESS_KEY \
    --env AWS_SESSION_TOKEN \
    -v ${PWD}/config:/config \
    cmt-build \
    ${args}
