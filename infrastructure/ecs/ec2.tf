data "aws_availability_zones" "available" {}

data "aws_ami" "amazon_linux_2" {
  most_recent = true

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*-x86_64-ebs"]
  }

  owners = ["amazon"]
}

resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.amazon_linux_2.id
  instance_type               = var.instance_type
  subnet_id                   = var.aws_subnet_public[0]
  vpc_security_group_ids      = [var.bastion_sg]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.key.key_name
  tags = {
    Name = "bastion"
   }
}

resource "aws_key_pair" "key" {
  key_name   = "key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCy206Rou9+5peIho5PmZM5bu5r51t9qHmEoc1PUFc9sXLsY+ZkYhfGfiNVcMc+4MB1pG2l3rB1iY5im6mDpTl8ej8kXcit62O3Bf0rxZ7kOTcByFhfMBmv4csStxjUa5ndy9pRRXTMutgYEe6jG1GzJ7cbvcCiRTF5DwTNtz9C+qzF4vwuQK6RIk7DcTxSgmh7JTZJwYFhkKcO/l8asOTDzgJFLKoTpeJXpcXA10YoWhBtycD/U+mGifVm721GkdJzftN5iPjtEEiwgtQqGWg8BSmNwU4L2Ps1eITiRG14YGth6e3Rpr694HgQjb+6oDik/rcMmPaGefm5fWHC1oaS4I1XT3Q5JAsHLNaDM2T/EFof6zHK8gWIIQ3K0nI1Qa0s5fEMuwsdRm6tb9B7BQh7jsJPv1ZuYZIt7lSefZH2U0L9rkOiHDDXjXD9Ze+a2awfaxnFTOtzRZJGmOGmWeW1a3EL2OB2hGCHX1t15I5y7Uq8xtoNIFjcQeYbpcxfbBZ3VfojnD9j0M1XSSsRSVBV5MCxo7Wv3zhb4jXNDuH5DsKVlXe4xwWl/hvt+5hhdvdtMOF/HQgV5gRLkEZaVDrbRg0ielcAcbmh+C/VBsQMci0nA72EttxIMjx/rzaaMmdOupyW4kRrwJTSAlv0lWCC30MIBmDD6nS8X3AnhB2kJw== mateusc.lira@gmail.com"
}

# This path.module is the path to the directory where the ec2 module is located
# This path.root is the path to the root directory of the project
# Using "../" to go up one directory didn't work here, so I had to use the full path with this variable
# filebase64 is a function that converts a file to base64

# sudo rm /var/lib/cloud/instance/sem/config_scripts_user 
# This is a necessary command to remove "cache" from the instances to run the user_data again

# data "template_file" "userdata" {
#   template = file("${path.module}/userdata.tpl")
#   vars = {
#     DOCKER_NODE = filebase64("${path.root}./app/node/Dockerfile")
#   }
# }

data "template_file" "user_data" {
        template = file("${path.module}/user_data.sh")

        vars = {
            ecs_cluster_name = aws_ecs_cluster.default.name
        }
    }

resource "aws_ecs_cluster" "default" {
  name  = "${var.name}-cluster"
  tags = {
    Scenario = "scenario-ecs-ec2"
  }
}

 resource "aws_launch_template" "ecs_launch_template" {
  name                   = "template-${var.name}"
  image_id               = data.aws_ami.amazon_linux_2.id
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.key.key_name
  user_data              = base64encode(data.template_file.user_data.rendered)
  vpc_security_group_ids = [var.sg_id]
  iam_instance_profile {
    arn = aws_iam_instance_profile.ec2_instance_role_profile.arn
  }
    monitoring {
        enabled = true
    }
  tags = {
    Scenario = "scenario-ecs-ec2"
  }
}

 resource "aws_autoscaling_group" "general" {
  name                      = "${var.name}-asg"
  max_size                  = var.max_size
  min_size                  = var.min_size
  health_check_type         = "EC2"
  protect_from_scale_in     = true
  vpc_zone_identifier       = [var.aws_subnet_private[0], var.aws_subnet_private[1]]

 launch_template {
    id      = aws_launch_template.ecs_launch_template.id
    version = "$Latest"
  }
  instance_refresh {
    strategy = "Rolling"
  }
  lifecycle {
    create_before_destroy = true
  }
  tag {
    key                 = "Name"
    value               = "ASG"
    propagate_at_launch = true
  }
  tag {
    key                 = "Scenario"
    value               = "scenario-ecs-ec2"
    propagate_at_launch = false
  }
}

resource "aws_ecs_capacity_provider" "cas" {
  name = "cas"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.general.arn
    managed_termination_protection = "ENABLED"

    managed_scaling {
      maximum_scaling_step_size = var.max_size
      minimum_scaling_step_size = var.min_size
      status                    = "ENABLED"
      target_capacity           = 100
    }
  }
  tags = {
    Scenario = "scenario-ecs-ec2"
  }
}

resource "aws_ecs_cluster_capacity_providers" "cas" {
  cluster_name       = aws_ecs_cluster.default.name
  capacity_providers = [aws_ecs_capacity_provider.cas.name]
}

resource "aws_ecs_service" "aws_service" {
  name                              = "${var.name}_service"
  cluster                           = aws_ecs_cluster.default.id
  launch_type                       = "EC2" 
  health_check_grace_period_seconds = 30
  task_definition                   = aws_ecs_task_definition.default.arn
  desired_count                     = 1

  #iam_role            = aws_iam_role.ecs_service_role.arn  # This is iam_role parameter is not possible to use because I'm using network_configuration

  load_balancer {
    target_group_arn = var.lb_arn
    container_name   = var.container_name
    container_port   = var.container_port
  }

  network_configuration {
    subnets          = var.aws_subnet_private
    security_groups  = [aws_security_group.service_security_group.id, var.alb_sg]
    assign_public_ip = false
  }

  ordered_placement_strategy {
    type  = "spread"
    field = "attribute:ecs.availability-zone"
  }

  tags = {
    Scenario = "scenario-ecs-ec2"
  }
}

resource "aws_security_group" "service_security_group" {
  name   = "service-sg-${var.env_id}"
  vpc_id = var.vpc_id
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    # Only allowing traffic in from the load balancer security group
    security_groups = [var.alb_sg]
  }

  egress {
    from_port   = 0 # Allowing any incoming port
    to_port     = 0 # Allowing any outgoing port
    protocol    = "-1" # Allowing any outgoing protocol 
    cidr_blocks = ["0.0.0.0/0"] # Allowing traffic out to all IP addresses
    ipv6_cidr_blocks = ["::/0"] # Allowing traffic out to all IPv6 addresses
  }
}

resource "aws_ecs_task_definition" "default" {
  family             = "ECS_TaskDefinition"
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn      = aws_iam_role.ecs_task_iam_role.arn
  network_mode       = "awsvpc"
  container_definitions = jsonencode([
    {
      name         = var.container_name
      image        = "public.ecr.aws/q3k0a0y5/mateusclira:latest"
      cpu          = var.cpu_units
      memory       = var.memory
      essential    = true
      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = "tcp"
        }
      ]
    }
  ])

  tags = {
    Scenario = "scenario-ecs-ec2"
  }
}

# data "aws_ecs_task_definition" "main" {
#   task_definition = aws_ecs_task_definition.default.family
# }

resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = var.max_size
  min_capacity       = var.min_size
  resource_id        = "service/${aws_ecs_cluster.default.name}/${aws_ecs_service.aws_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "ecs_policy_memory" {
  name               = "memory-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value = 100
  }
}

resource "aws_appautoscaling_policy" "ecs_policy_cpu" {
  name               = "cpu-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = 100
  }
}
