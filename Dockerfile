FROM hashicorp/terraform:0.11.14

ADD https://github.com/labd/terraform-provider-commercetools/releases/download/0.9.0/terraform-provider-commercetools-0.9.0-linux-amd64.tar.gz /root/.terraform.d/plugins/terraform-provider-commercetools_v0.9.0

WORKDIR /config

