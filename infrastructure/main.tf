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
    cluster_id = module.ec2.cluster_id

    alb_sg = module.sg.alb_sg_id
}

module "ec2" {
    source = "./ec2"

    aws_subnet_private = module.vpc.aws_subnet_private
    aws_subnet_public  = module.vpc.aws_subnet_public

    alb_sg = module.sg.alb_sg_id
    sg_id  = module.sg.sg_id
    bastion_sg = module.sg.bastion_sg_id
    lb_arn = module.alb.lb_arn
    aws_region = var.aws_region
    name = var.name
}

module "sg" {
    source = "./sg"

    vpc_id = module.vpc.vpc_id
}