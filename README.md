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

Resources
---------
* [Terraform documentation](https://www.terraform.io/docs/index.html)
* [Terraform Commercetools Plugin](https://commercetools-terraform-provider.readthedocs.io/en/latest/)
