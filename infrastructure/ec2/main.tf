data "aws_availability_zones" "available" {}

# resource "aws_launch_template" "ecs_launch_template" {
#   name                   = "mateusclira-hiring"
#   image_id               = "ami-0af9d24bd5539d7af"
#   instance_type          = "t3.micro"
#   key_name               = aws_key_pair.key.key_name
#   user_data              = data.template_file.userdata.rendered
#   vpc_security_group_ids = [var.ec2_sg]
# }

resource "aws_instance" "bastion" {
  ami                         = "ami-0af9d24bd5539d7af"
  instance_type               = "t3.micro" # used to set core count below
  availability_zone           = "us-east-1a"
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
data "template_file" "userdata" {
  template = filebase64("${path.module}/ecs.config")
}

resource "aws_ecs_cluster" "default" {
  name  = "mateusclira-cluster"
}

resource "aws_launch_configuration" "general" {
  name           = "mateusclira-template"
  image_id       = "ami-0af9d24bd5539d7af"
  instance_type  = "t3.micro"
  key_name       = aws_key_pair.key.key_name
  user_data = <<-EOF
                #!/bin/bash
                echo ECS_CLUSTER=mateusclira-cluster >> /etc/ecs/ecs.config
                EOF
 }

 resource "aws_autoscaling_group" "general" {
  desired_capacity   = 1
  max_size           = 1
  min_size           = 1
  health_check_grace_period = 300
  health_check_type         = "EC2"
  launch_configuration = aws_launch_configuration.general.name
  vpc_zone_identifier = [var.aws_subnet_private[0], var.aws_subnet_private[1]]
}

resource "aws_ecs_service" "aws_service" {
  name                 = "mateusclira_service"
  cluster              = aws_ecs_cluster.default.id
  launch_type          = "EC2" 
  task_definition      = "${aws_ecs_task_definition.aws-ecs-task.family}:${max(aws_ecs_task_definition.aws-ecs-task.revision, data.aws_ecs_task_definition.main.revision)}"
  scheduling_strategy  = "REPLICA"
  desired_count        = 1
  force_new_deployment = true

  network_configuration {
    subnets          = [var.aws_subnet_private[0], var.aws_subnet_private[1]]
    assign_public_ip = false
    security_groups = [
      var.alb_sg,
      var.sg_id
    ]
  }

  load_balancer {
    target_group_arn = var.lb_arn
    container_name   = "meteorapp"
    container_port   = 80
  }
}

resource "aws_ecs_task_definition" "aws-ecs-task" {
  family = "service"

  container_definitions = jsonencode([
    {
      "name": "meteorapp",
      "instanceType": "t3.micro",
      "image": "mateusclira/meteorapp:v5",
      "portMappings": [
        {
          "containerPort": 80,
          "hostPort": 80
        }
      ],
      "essential": true
    }
  ])

  requires_compatibilities = ["EC2"]
  network_mode             = "awsvpc"
  memory                   = "512"
  cpu                      = "256"
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn
  task_role_arn            = aws_iam_role.ecsTaskExecutionRole.arn
}
data "aws_ecs_task_definition" "main" {
  task_definition = aws_ecs_task_definition.aws-ecs-task.family
}

resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = 1
  min_capacity       = 1
  resource_id        = "service/mateusclira-cluster/mateusclira_service"
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
    target_value = 80
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
    target_value = 80
  }
}
