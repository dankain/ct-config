#!/bin/bash

args=$*

if [ "${args}x" = "x" ]; then
    echo "No arguments are present"
    exit 1
fi

docker run \
    --env AWS_ACCESS_KEY_ID \
    --env AWS_SECRET_ACCESS_KEY \
    --env AWS_SESSION_TOKEN \
    --env AWS_DEFAULT_REGION \
    -w /config \
    -v ${PWD}/aws:/config \
    hashicorp/terraform:0.11.14 \
    ${args}
