Purpose
-------

It is a proof of concept to demonstrate how to join following solutions

- CircleCI - a ci system
- AWS - a cloud provider
- Commercetools - a cloud based commerce provider
- Terraform - a cloud management tool

Scope
-----

1. Create a project in commercetools
2. Configure git repository
3. Connect git to cirecleci
4. Configure circeci
    - use AWS ec2 parameter store to store Commercetools credentials
4. Configure terraform template
    - to lock the deployment
    - to store the state in S3 bucket
5. Perform following operations:
    - create an object
    - update the object
    - remove the object
    - configure and manage subscription
6. Create example for mono and single repos

Error assumptions
-----------------

- the configuration fails all should stop
- if next steps fails it will required manual intervention

TODO: explain directories and their purpose

Step 1 - Configure AWS CI User
------

Create a AWS account which gives CircleCI access to AWS infrastructure to pull configuration required to setup subscription in commercetools.

1. Login to AWS 
2. Create a user named e.g. CI by giving only programmatic access
3. Download credentials.csv

Step 2 - Configure CircleCI
-------

Configure CircleCI by navigating to project list and select a gear box. You will be taken to the `Project Settings` where you will have to configure following envrionment variables by clicking `Environment Variables` in the `Build Settings` section.

| Name | Value |
| ---- | ----- |
| AWS_ACCESS_KEY_ID | value from credentials.csv | 
| AWS_SECRET_ACCESS_KEY | value from credentials.csv | 

Step 3 - Configure EC2 Parameters
------

Configure AWS platform with secrets to access commercetools platform:

```bash
aws ssm put-parameter --name /api/commercetools/<replace_with_project_name>/client_id --type SecureString --value <commercetools_client_id>
aws ssm put-parameter --name /api/commercetools/<replace_with_project_name>/secret --type SecureString --value <commercetools_secret>
aws ssm put-parameter --name /api/commercetools/<replace_with_project_name>/scope --type SecureString --value <commercetools_scope>
aws ssm put-parameter --name /api/commercetools/lego-poc/subscription_access_key --type SecureString --value <aws_access_key>
aws ssm put-parameter --name /api/commercetools/lego-poc/subscription_secret_key --type SecureString --value <aws_secret_key>
```

Verify all parameters have been added correctly:

```bash
aws ssm get-parameters --names \
    /api/commercetools/<replace_with_project_name>/client_id /api/commercetools/<replace_with_project_name>/secret /api/commercetools/<replace_with_project_name>/scope \
    --with-decryption
```

Test if the authentication works by calling following method (you have to have [jq](https://stedolan.github.io/jq/) utility installed)

```bash
CT_CLIENT_ID=$(aws ssm get-parameter --name /api/commercetools/lego-poc/client_id --with-decryption | jq -r '.Parameter.Value')
CT_SECRET=$(aws ssm get-parameter --name /api/commercetools/lego-poc/secret --with-decryption | jq -r '.Parameter.Value')
CT_SCOPE=$(aws ssm get-parameter --name /api/commercetools/lego-poc/scope --with-decryption | jq -r '.Parameter.Value')
CT_AUTH_RESULT=$(curl https://auth.sphere.io/oauth/token \
     --basic --user "${CT_CLIENT_ID}:${CT_SECRET}" \
     -X POST \
     -d "grant_type=client_credentials&scope=${CT_SCOPE}")
echo ${CT_AUTH_RESULT}
```

If all is ok you should get following output:

```json
{
    "access_token":"<token_to_use_api>",
    "token_type":"Bearer",
    "expires_in":172800,
    "scope":"<scope>"
}
```

Execute example query using token:
```bash
CT_TOKEN=$(echo $CT_AUTH_RESULT | jq -r '.access_token')
curl -H "Authorization: Bearer ${CT_TOKEN}" https://api.sphere.io/lego-poc/categories
```

Step 4 - Configure CI User Policies
----------------

TODO:....

Step 5 - Publish Docker Image
----------------

If you don't have a user in docker hub create an account to publish an image. 

```bash
docker tag cmt-build kamaz/cmt-build
docker push kamaz/cmt-build
```

Step 6 - Connect all the piecies
----------------

TODO:....

How to run locally
----------------
Needed tools:
- docker
- git 

Create `s3` bucket for storing state and `dynamodb` to lock state update
```bash
scripts/aws-init.sh init
scripts/aws-init.sh apply --auto-approve
```

Create a local version of the docker build:

```bash
scripts/create-build-images.sh
```

Verify that image is created:
```bash
docker images | grep cmt-build
```

Next export all commerce tools envrionment variables:
```bash
export CTP_PROJECT_KEY=lego-poc
export CTP_CLIENT_SECRET=$(aws ssm get-parameter --name /api/commercetools/lego-poc/secret --with-decryption | jq -r '.Parameter.Value')
export CTP_CLIENT_ID=$(aws ssm get-parameter --name /api/commercetools/lego-poc/client_id --with-decryption | jq -r '.Parameter.Value')
export CTP_AUTH_URL="https://auth.sphere.io"
export CTP_API_URL="https://api.sphere.io"
export CTP_SCOPES=$(aws ssm get-parameter --name /api/commercetools/lego-poc/scope --with-decryption | jq -r '.Parameter.Value')
export CTP_SUBSCRIPTION_ACCESS_KEY=$(aws ssm get-parameter --name /api/commercetools/lego-poc/subscription_access_key --with-decryption | jq -r '.Parameter.Value')
export CTP_SUBSCRIPTION_SECRET_KEY=$(aws ssm get-parameter --name /api/commercetools/lego-poc/subscription_secret_key --with-decryption | jq -r '.Parameter.Value')
```

Initialise the terraform:
```bash
scripts/local-terraform.sh init
```

Run plan on for deployment:
```bash
scripts/local-terraform.sh plan -var "subscription_access_key=${CTP_SUBSCRIPTION_ACCESS_KEY}" -var "subscriptoin_secret_key=${CTP_SUBSCRIPTION_SECRET_KEY}"
```

Run apply on for deployment:
```bash
scripts/local-terraform.sh apply --auto-approve -var "subscription_access_key=${CTP_SUBSCRIPTION_ACCESS_KEY}" -var "subscriptoin_secret_key=${CTP_SUBSCRIPTION_SECRET_KEY}"
```

Verity product types applied correctly:
```bash
curl -H "Authorization: Bearer ${CT_TOKEN}" https://api.sphere.io/${CTP_PROJECT_KEY}/product-types/ | jq
```

Debug
-----

Using Commercetools plugin in most cases you don't get useful error message except EOF e.g.

```
2 errors occurred:
        * commercetools_product_type.gift_card_type: 1 error occurred:
        * commercetools_product_type.gift_card_type: unexpected EOF
```

In following cases you can just create use `docker run` to create container debug the problem.

Create a container:
```bash
docker run \
    --env CTP_PROJECT_KEY \
    --env CTP_CLIENT_SECRET \
    --env CTP_CLIENT_ID \
    --env CTP_AUTH_URL \
    --env CTP_API_URL \
    --env CTP_SCOPES \
    --env CTP_SUBSCRIPTION_ACCESS_KEY \
    --env CTP_SUBSCRIPTION_SECRET_KEY \
    --env AWS_ACCESS_KEY_ID \
    --env AWS_SECRET_ACCESS_KEY \
    --env AWS_SESSION_TOKEN \
    -v ${PWD}/config:/config \
    --entrypoint '/bin/sh' \
    -it \
    --rm \
    cmt-build
```

From docker you can run Terraform commands with debug mode

```bash
$ TF_LOG=DEBUG terraform apply
2019-06-08T19:36:01.047Z [DEBUG] plugin.terraform-provider-commercetools_v0.9.0: Response: {"statusCode":401,"message":"Please provide valid
client credentials using HTTP Basic Authentication.","errors":[{"code":"invalid_client","message":"Please provide valid client credentials us
ing HTTP Basic Authentication."}],"error":"invalid_client","error_description":"Please provide valid client credentials using HTTP Basic Auth
entication."}
```

Gotchas
-------

- `master` version of the Commercetools Provider does not work, it throws error when executing `apply`
- Commercetools provider version 0.9 only works with Terraform version 0.11 (0.12 is the latest which it doesn't work with, 0.12 has been release quite recently)

Todo
----

- [ ] ! Remove aws/terraform.tfstate
- [ ] Before making it public remove all references to `lego-poc`
- [ ] Extend POC to add ability to deploy between multiple accounts
- [ ] S3 enable/disable lifecycle rules
- [ ] Add tags to all `aws` resources
- [ ] AWS Secrets are being stored in the state and potentially state should be encrypted

Resources
---------
* [Terraform documentation](https://www.terraform.io/docs/index.html)
* [Terraform state management & workspaces](https://www.terraform.io/docs/backends/types/s3.html)
* [Terraform Commercetools Plugin](https://commercetools-terraform-provider.readthedocs.io/en/latest/)
