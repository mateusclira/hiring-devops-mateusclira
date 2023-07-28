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
  health_check {
    healthy_threshold   = "3"
    interval            = "300"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "3"
    path                = "/v1/status"
    unhealthy_threshold = "2"
  }
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

resource "aws_lb_target_group_attachment" "ecs" {
  target_group_arn = aws_lb_target_group.main.id
  target_id        = var.cluster_id
  port             = 80
}