# https://www.terraform.io/docs/backends/types/s3.html
terraform {
  backend "s3" {
    bucket         = "terraform-ct-state-dev"
    key            = "network/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"

    # encrypted = true
  }
}

provider "aws" {
  region = "us-east-1"
}

provider "commercetools" {}

resource "commercetools_product_type" "gift_card_type" {
  name        = "gift-card-value"
  description = "Gift Card Product Type"

  attribute {
    name = "electronic"

    label = {
      en = "Is Electronic Gift Card"
      pl = "Elktroniczna karta podarunkowa"
    }

    required = true

    type {
      name = "boolean"
    }
  }
}

resource "commercetools_product_type" "hardgoods_type" {
  name        = "hardgoods-value"
  description = "Hardgoods Product"

  attribute {
    name = "weigth"

    label = {
      en = "Weigth of the product"
      pl = "Waga produktu"
    }

    required = true

    type {
      name = "number"
    }
  }

  attribute {
    name = "height"

    label = {
      en = "Height of the product"
      pl = "Wysokosc produktu"
    }

    required = true

    type {
      name = "number"
    }
  }
}

data "aws_sqs_queue" "commercetools_sqs" {
  name = "terraform-example-queue"
}

data "aws_region" "current" {

}

resource "commercetools_subscription" "test_subscription" {
  key = "test-subscription"

  destination {
    type          = "SQS"
    queue_url     = "${data.aws_sqs_queue.commercetools_sqs.id}"
    # access_key    = ""
    # access_secret = ""
    region        = "${data.aws_region.current.name}"
  }

  changes {
    resource_type_ids = ["product", "product-type"]
  }

  message {
    resource_type_id = "product"
  }
}
