FROM hashicorp/terraform:0.11.14

RUN wget https://github.com/labd/terraform-provider-commercetools/releases/download/0.9.0/terraform-provider-commercetools-0.9.0-linux-amd64.tar.gz; \
    tar -xzvf terraform-provider-commercetools-0.9.0-linux-amd64.tar.gz; \
    mkdir -p /root/.terraform.d/plugins; \
    mv terraform-provider-commercetools_v0.9.0 /root/.terraform.d/plugins

RUN apk update; \
    apk add python3; \
    curl -O https://bootstrap.pypa.io/get-pip.py; \
    python3 get-pip.py --user; \
    pip3 install awscli --upgrade --user
# that is not the best idea but as a POC it should be ok
ENV PATH="/root/.local/bin:$PATH"

WORKDIR /config

