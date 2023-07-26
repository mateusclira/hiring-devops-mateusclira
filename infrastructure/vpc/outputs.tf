output "vpc_id" {
    value = aws_vpc.main.id
}

output "aws_subnet_private" {
    value = [aws_subnet.private1.id, aws_subnet.private2.id]
}

output "aws_subnet_public" {
    value = [aws_subnet.public1.id, aws_subnet.public2.id]
}

output "default_security_group_id" {
  value = aws_vpc.main.default_security_group_id
}