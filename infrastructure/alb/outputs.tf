output "lb_dns_name" {
  value = aws_lb.main.dns_name
}

output "lb_arn" {
  value = aws_lb_target_group.main.id
}