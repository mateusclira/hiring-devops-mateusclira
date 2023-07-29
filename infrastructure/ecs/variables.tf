variable "aws_subnet_private" {}

variable "aws_subnet_public" {}

variable "sg_id" {}

variable "alb_sg" {}

variable "lb_arn" {}

variable "aws_region" {}

variable "name" {}

variable "bastion_sg" {}

variable "memory" {
    default = 512
}
variable "cpu_units" {
    default = 256
}