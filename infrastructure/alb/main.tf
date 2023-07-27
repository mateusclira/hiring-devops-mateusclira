resource "aws_lb" "main" {
  name               = "alb-mateusclira"
  load_balancer_type = "application"

  subnets = var.aws_subnet_public
  security_groups = [var.alb_sg]
}

resource "aws_lb_target_group" "main" {
  name     = "alb-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  target_type = "ip"
}

resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.id
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.id
  }
}

# resource "aws_lb_target_group_attachment" "vpc" {
#   target_group_arn = aws_lb_target_group.main.arn
#   target_id        = var.vpc_id
#   port             = 80
# }
