# https://www.terraform.io/docs/backends/types/s3.html
#terraform {
#  backend "s3" {
#    bucket = "mybucket"
#    key    = "path/to/my/key"
#    region = "us-east-1"
#  }
#}

provider "commercetools" {}

resource "commercetools_product_type" "gift_card" {
    name = "gift-card"
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

resource "commercetools_product_type" "hardgoods" {
    name = "hardgoods"
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
