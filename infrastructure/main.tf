terraform {
    backend "s3" {
        bucket = "hiring-mateusclira"
        key    = "terraform.tfstate"
        region = "us-east-1"
    }
    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = ">= 3.0.0"
        }
    }
}

provider "aws" {
    region = var.aws_region
    shared_config_files      = ["~/.aws/config"]
    shared_credentials_files = ["~/.aws/credentials"]
}

module "vpc" {
    source = "./vpc"
}
module "alb" {
    source     = "./alb"
    vpc_id     = module.vpc.vpc_id
    aws_subnet_public = module.vpc.aws_subnet_public
    ec2_1_id   = module.ec2.ec2_1_id
    ec2_2_id   = module.ec2.ec2_2_id

    alb_sg = module.sg.alb_sg
}

module "ec2" {
    source = "./ec2"

    aws_subnet_private = module.vpc.aws_subnet_private
    aws_subnet_public  = module.vpc.aws_subnet_public

    ec2_sg     = module.sg.ec2_sg
    bastion_sg = module.sg.bastion_sg
}

module "sg" {
    source = "./sg"

    vpc_id = module.vpc.vpc_id
}