# locals {
#     aws_region = var.aws_region
# }

# terraform {
#     backend "s3" {
#         bucket = "wy-a4f84a230c77"
#         key    = "terraform.tfstate"
#         region = local.aws_region
#     }
#     required_providers {
#         aws = {
#             source  = "hashicorp/aws"
#             version = ">= 3.0.0"
#         }
#     }
# }

# provider "aws" {
#     region = local.aws_region
#     shared_config_files      = ["~/.aws/config"]
#     shared_credentials_files = ["~/.aws/credentials"]
# }
