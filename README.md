Purpose
-------

It is a proof of concept to demonstrate how to join following solutions
    - CircleCI - a ci system
    - AWS - a could provider
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
    - to lock the a deployment
    - to store the state in S3 bucket
5. Perform following operations:
    - create an object
    - update the object
    - remove the object
    - configure and manage subscription
6. Create example for mono and single repos

Error assumptions
-----------------

the configuration fails all should stop
if next steps fails it will required manual intervention

Step 1
------

Create a AWS account which gives circleci access to AWS infrastructure to pull configuration required to setup subscription in commercetools.

1. Login to AWS 
2. Create a user named e.g. CI by giving only programmatic access
3. Download credentials.csv

Step 2 
-------

Configure circleci by navigating to project list and select a gear box. You will be taken to the `Project Settings` where you will have to configure following envrionment variables by clicking `Environment Variables` in the `Build Settings` section.

| Name | Value |
| ---- | ----- |
| AWS_ACCESS_KEY_ID | value from credentials.csv | 
| AWS_SECRET_ACCESS_KEY | value from credentials.csv | 

Step 3
------

Configure AWS platform with secrets to access commercetools platform:

```bash
aws ssm put-parameter --name /api/commercetools/<replace_with_project_name>/client_id --type SecureString --value <commercetools_client_id>
aws ssm put-parameter --name /api/commercetools/<replace_with_project_name>/secret --type SecureString --value <commercetools_client_id>
aws ssm put-parameter --name /api/commercetools/<replace_with_project_name>/scope --type SecureString --value <commercetools_scope>
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

Resources
---------
* [Terraform documentation](https://www.terraform.io/docs/index.html)
* [Terraform Commercetools Plugin](https://commercetools-terraform-provider.readthedocs.io/en/latest/)
