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
}

resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}

resource "aws_lb_target_group_attachment" "ec2_1" {
  target_group_arn = aws_lb_target_group.main.arn
  target_id        = var.ec2_1_id
  port             = 80
}

resource "aws_lb_target_group_attachment" "ec2_2" {
  target_group_arn = aws_lb_target_group.main.arn
  target_id        = var.ec2_1_id
  port             = 80
}
