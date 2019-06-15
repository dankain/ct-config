variable "ci_user" {
  type = "string"
  default = "ci"
}

variable "terraform_bucket_name" {
  type = "string"
}

variable "terraform_table_name" {
  type = "string"
  default = "terraform-state-lock"
}

variable "ctp_project_id" {
  type = "string"
}
variable "ctp_client_id" {
  type = "string"
}
variable "ctp_secret" {
  type = "string"
}
variable "ctp_scope" {
  type = "string"
}



provider "aws" {
  region = "us-east-1"
}

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "${var.terraform_bucket_name}"
  acl    = "private"

  versioning {
    enabled = true
  }
}

resource "aws_dynamodb_table" "terraform_state_lock" {
  name           = "${var.terraform_table_name}"
  read_capacity  = 1
  write_capacity = 1
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

resource "aws_iam_user" "ci_user" {
  name = "${var.ci_user}"
}

resource "aws_iam_access_key" "ci_user" {
  user = "${var.ci_user}"
}

resource "aws_ssm_parameter" "ctp_client_id" {
  name  = "/api/commercetools/${var.ctp_project_id}/client_id"
  type  = "SecureString"
  value = "${var.ctp_client_id}"
}
resource "aws_ssm_parameter" "ctp_secret" {
  name  = "/api/commercetools/${var.ctp_project_id}/secret"
  type  = "SecureString"
  value = "${var.ctp_secret}"
}
resource "aws_ssm_parameter" "ctp_scope" {
  name  = "/api/commercetools/${var.ctp_project_id}/scope"
  type  = "SecureString"
  value = "${var.ctp_scope}"
}

resource "aws_ssm_parameter" "ci_access_key" {
  name  = "/api/circleci/${var.ctp_project_id}/access_key"
  type  = "SecureString"
  value = "${aws_iam_access_key.ci_user.id}"
}

resource "aws_ssm_parameter" "ci_secret_key" {
  name  = "/api/circleci/${var.ctp_project_id}/secret_key"
  type  = "SecureString"
  value = "${aws_iam_access_key.ci_user.secret}"
}

resource "aws_ssm_parameter" "tf_bucket_name" {
  name  = "/api/commercetools/${var.ctp_project_id}/tf_bucket_name"
  type  = "String"
  value = "${var.terraform_bucket_name}"
}

# Configure ci user
resource "aws_iam_user_policy" "ci_user" {
  name = "ci-user"
  user = "${var.ci_user}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
      {
        "Effect": "Allow",
        "Action": "s3:ListBucket",
        "Resource": "${aws_s3_bucket.terraform_state.arn}"
      },
      {
        "Effect": "Allow",
        "Action": ["s3:GetObject", "s3:PutObject"],
        "Resource": "${aws_s3_bucket.terraform_state.arn}/*"
      },
      {
        "Effect": "Allow",
        "Action": [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem"
        ],
        "Resource": "${aws_dynamodb_table.terraform_state_lock.arn}"
      },
      {
        "Effect": "Allow",
        "Action": [
          "ssm:GetParameters",
          "ssm:GetParameter"
        ],
        "Resource": "arn:aws:ssm:*:${data.aws_caller_identity.current.account_id}:parameter/api/commercetools/*"
      },
      {
        "Effect": "Allow",
        "Action": [
          "sqs:ListQueues",
          "sqs:GetQueueUrl",
          "sqs:GetQueueAttributes"
        ],
        "Resource": "*"
      }
  ]
}
EOF
}

# From here you see specific configuration for Commercetools to create a subscription
resource "aws_iam_user" "commercetools_subscription" {
  name = "commercetools-subscription"
  path = "/commercetools/"
}

resource "aws_iam_access_key" "commercetools_subscription" {
  user = "${aws_iam_user.commercetools_subscription.name}"
}

resource "aws_iam_user_policy" "commercetools_subscription" {
  name = "test"
  user = "${aws_iam_user.commercetools_subscription.name}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "sqs:SendMessage",
      "Resource": "${aws_sqs_queue.commercetools_sqs.arn}"
    }
  ]
}
EOF
}

resource "aws_ssm_parameter" "ctp_subscription_access_key" {
  name  = "/api/commercetools/${var.ctp_project_id}/subscription_access_key"
  type  = "SecureString"
  value = "${aws_iam_access_key.commercetools_subscription.id}"
}

resource "aws_ssm_parameter" "ctp_subscription_secret_key" {
  name  = "/api/commercetools/${var.ctp_project_id}/subscription_secret_key"
  type  = "SecureString"
  value = "${aws_iam_access_key.commercetools_subscription.secret}"
}

resource "aws_sqs_queue" "commercetools_sqs" {
  name                      = "terraform-example-queue"
  delay_seconds             = 5
  max_message_size          = 262144
  message_retention_seconds = 86400
  receive_wait_time_seconds = 10
}
