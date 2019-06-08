provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "terraform-ct-state-dev" # todo: parameterise
  acl    = "private"

  versioning {
    enabled = true
  }
}

resource "aws_dynamodb_table" "terraform_state_lock" {
  name           = "terraform-state-lock"
  read_capacity  = 1
  write_capacity = 1
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

resource "aws_iam_user" "commercetools_subscription" {
  name = "commercetools-subscription"
  path = "/commercetools/"
}

# Todo: at the moment it requires admin to login and create access key through console
# resource "aws_iam_access_key" "commercetools_subscription" {
#   user = "${aws_iam_user.commercetools_subscription.name}"
#   pgp_key = "keybase:kamil" # todo: parameterise 
# }

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

resource "aws_sqs_queue" "commercetools_sqs" {
  name                      = "terraform-example-queue"
  delay_seconds             = 5
  max_message_size          = 262144
  message_retention_seconds = 86400
  receive_wait_time_seconds = 10
}
