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

What is what
------------

| Directory | Description |
|-----------|-------------|
| `circleci` | example CircleCI configuration file |
| `aws` | example terraform template to initialise example ci user and commercetools subscription queue |
| `config` | example commercetools template to initialise commercetools assets |
| `scripts` | scripts to simplify process of creating assets in aws, commercetools and docker |

!Important!
---------

IT IS NOT PRODUCTION READY. IT IS DEMONSTRATION ONLY. AFTER USING PLEASE REMOVE ACCESS KEYS CREATED BY SCRIPTS.

TLDR
----

If you want to get things running fast:
1. Fork repository to your github/bitbucket repository
2. Create a project in commercetools and populate `aws/terraform.tfvar` with values created for api client

| Value | Description |
|-------|-------------|
|ctp_project_id| a commercetools project id |
|ctp_client_id| a commercetools client id |
|ctp_secret| a commercetools secret |
|ctp_scope| a commercetools scope |
|terraform_bucket_name| a bucket where terraform will be stored, it has to be unique|
|terraform_table_name| a dynamodb table to lock terraform table|

```bash
scripts/aws-init.sh init
# check that all is ok before running apply
scripts/aws-init.sh plan
scripts/aws-init.sh apply --auto-approve
```

2. Login to CircleCI project using same github/bitbucket credentials and setup the project by adding following envrionment variables:
|Name  | Description |
|------|-------------|
|AWS_ACCESS_KEY_ID | access key for ci user created as part of previous step, value can be retrieved either through aws console inside the System Manager > Parameter Store under `/api/circleci/{ctp_project_id}/access_key` |
|AWS_SECRET_ACCESS_KEY |access key for ci user created as part of previous step, value can be retrieved either through aws console inside the System Manager > Parameter Store under `/api/circleci/{ctp_project_id}/secret_key`  |
|AWS_DEFAULT_REGION | e.g. `us-east-1` |
|CTP_PROJECT_KEY| commercetools project key defined during creation |

Step 1 - Configure AWS Resources
------
Create a project in commercetools and populate `aws/terraform.tfvar` with values created for api client

Create `s3` bucket for storing state, `dynamodb` to lock state update, parameters and ci user with policies.
```bash
scripts/aws-init.sh init
scripts/aws-init.sh apply --auto-approve
```
Step 2 - Configure CircleCI
-------

Configure CircleCI by navigating to project list and select a gear box. You will be taken to the `Project Settings` where you will have to configure following envrionment variables by clicking `Environment Variables` in the `Build Settings` section.

| Name | Value |
| ---- | ----- |
| AWS_ACCESS_KEY_ID | value from AWS Parameter Store for parameter `/api/circleci/{ctp_project_id}/access_key` | 
| AWS_SECRET_ACCESS_KEY | value from AWS Parameter Store for parameter `/api/circleci/{ctp_project_id}/secret_key` | 
| AWS_DEFAULT_REGION | value default region e.g us-east-1 |
| CTP_PROJECT_KEY | commercetools project key defined during creation |

Step 3 - Configure EC2 Parameters
------

Verify all parameters have been added correctly

```bash
export CTP_PROJECT_KET=<commercetools_project_key>
aws ssm get-parameters --names \
    /api/commercetools/${CTP_PROJECT_KEY}/client_id \
    /api/commercetools/${CTP_PROJECT_KEY}/secret \
    /api/commercetools/${CTP_PROJECT_KEY}/scope \
    /api/commercetools/${CTP_PROJECT_KEY}/subscription_access_key \
    /api/commercetools/${CTP_PROJECT_KEY}/subscription_secret_key \
    --with-decryption
```

Test if the authentication works by calling following method (you have to have [jq](https://stedolan.github.io/jq/) utility installed)

```bash
export CTP_CLIENT_SECRET=$(aws ssm get-parameter --name /api/commercetools/${CTP_PROJECT_KEY}/secret --with-decryption | jq -r '.Parameter.Value')
export CTP_CLIENT_ID=$(aws ssm get-parameter --name /api/commercetools/${CTP_PROJECT_KEY}/client_id --with-decryption | jq -r '.Parameter.Value')
export CTP_SCOPES=$(aws ssm get-parameter --name /api/commercetools/${CTP_PROJECT_KEY}/scope --with-decryption | jq -r '.Parameter.Value')
export CTP_AUTH_RESULT=$(curl https://auth.sphere.io/oauth/token \
     --basic --user "${CTP_CLIENT_ID}:${CTP_CLIENT_SECRET}" \
     -X POST \
     -d "grant_type=client_credentials&scope=${CTP_SCOPES}")
echo ${CTP_AUTH_RESULT}
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
CTP_TOKEN=$(echo $CTP_AUTH_RESULT | jq -r '.access_token')
curl -H "Authorization: Bearer ${CTP_TOKEN}" https://api.sphere.io/${CTP_PROJECT_KEY}/categories
```

Step 4 - Publish Docker Image
----------------

If you don't have a user in docker hub create an account to publish an image. If you change the docker repository location you will have to update CircleCI config.yaml file.

```bash
scripts/create-build-images.sh
docker tag ct-build cabiri/ct-build
docker push cabiri/ct-build
```

Step 5 - Connect all the piecies
----------------

All should be in place now. It should be just enough to `push` repository and CircleCI should build all.

How to run locally
----------------
Needed tools:
- docker
- git 

Create a local version of the docker build:

```bash
scripts/create-build-images.sh
```

Verify that image is created:
```bash
docker images | grep ct-build
```

Next export all commerce tools envrionment variables:
```bash
export CTP_PROJECT_KEY=<commercetools_project_id>
export CTP_CLIENT_SECRET=$(aws ssm get-parameter --name /api/commercetools/${CTP_PROJECT_KEY}/secret --with-decryption | jq -r '.Parameter.Value')
export CTP_CLIENT_ID=$(aws ssm get-parameter --name /api/commercetools/${CTP_PROJECT_KEY}/client_id --with-decryption | jq -r '.Parameter.Value')
export CTP_SCOPES=$(aws ssm get-parameter --name /api/commercetools/${CTP_PROJECT_KEY}/scope --with-decryption | jq -r '.Parameter.Value')
export CTP_AUTH_URL="https://auth.sphere.io"
export CTP_API_URL="https://api.sphere.io"
export CTP_SUBSCRIPTION_ACCESS_KEY=$(aws ssm get-parameter --name /api/commercetools/${CTP_PROJECT_KEY}/subscription_access_key --with-decryption | jq -r '.Parameter.Value')
export CTP_SUBSCRIPTION_SECRET_KEY=$(aws ssm get-parameter --name /api/commercetools/${CTP_PROJECT_KEY}/subscription_secret_key --with-decryption | jq -r '.Parameter.Value')
```

Initialise the terraform:
```bash
scripts/local-terraform.sh init -backend-config="bucket=terraform-ct-state-dev-cab"
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
curl -H "Authorization: Bearer ${CTP_TOKEN}" https://api.sphere.io/${CTP_PROJECT_KEY}/product-types/ | jq
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
    ct-build
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
- when terraform fails with an error the lock stays in `dynamodb` and you have to manually clean-up, it could be seen as positive because someone will have to investigate before reruning

Todo
----

- [ ] Extend POC to add ability to deploy between multiple accounts
- [ ] S3 enable/disable lifecycle rules
- [ ] Add tags to all `aws` resources
- [ ] AWS Secrets are being stored in the state and potentially state should be encrypted

Resources
---------
* [Terraform documentation](https://www.terraform.io/docs/index.html)
* [Terraform state management & workspaces](https://www.terraform.io/docs/backends/types/s3.html)
* [Terraform Commercetools Plugin](https://commercetools-terraform-provider.readthedocs.io/en/latest/)
