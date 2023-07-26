output "alb_sg" {
    value = aws_security_group.alb.id
}

output "ec2_sg" {
    value = aws_security_group.ec2.id 
}

output "bastion_sg" {
    value = aws_security_group.bastion.id
}
