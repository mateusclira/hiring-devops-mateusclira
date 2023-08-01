variable "aws_subnet_private" {}
variable "aws_subnet_public" {}

variable "sg_id" {}
variable "alb_sg" {}
variable "bastion_sg" {}

variable "lb_arn" {}

variable "aws_region" {}
variable "name" {}

variable "memory" {}
variable "cpu_units" {}

variable "vpc_id" {}
variable "env_id" {}

variable "container_name" {}
variable "container_port" {}

variable "instance_type" {
    default = "t3.micro"
}

variable "max_size" {
    default = 1
}

variable "min_size" {
    default = 1
}
