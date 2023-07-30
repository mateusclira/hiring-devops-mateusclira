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

resource "aws_key_pair" "key" {
  key_name   = "key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCy206Rou9+5peIho5PmZM5bu5r51t9qHmEoc1PUFc9sXLsY+ZkYhfGfiNVcMc+4MB1pG2l3rB1iY5im6mDpTl8ej8kXcit62O3Bf0rxZ7kOTcByFhfMBmv4csStxjUa5ndy9pRRXTMutgYEe6jG1GzJ7cbvcCiRTF5DwTNtz9C+qzF4vwuQK6RIk7DcTxSgmh7JTZJwYFhkKcO/l8asOTDzgJFLKoTpeJXpcXA10YoWhBtycD/U+mGifVm721GkdJzftN5iPjtEEiwgtQqGWg8BSmNwU4L2Ps1eITiRG14YGth6e3Rpr694HgQjb+6oDik/rcMmPaGefm5fWHC1oaS4I1XT3Q5JAsHLNaDM2T/EFof6zHK8gWIIQ3K0nI1Qa0s5fEMuwsdRm6tb9B7BQh7jsJPv1ZuYZIt7lSefZH2U0L9rkOiHDDXjXD9Ze+a2awfaxnFTOtzRZJGmOGmWeW1a3EL2OB2hGCHX1t15I5y7Uq8xtoNIFjcQeYbpcxfbBZ3VfojnD9j0M1XSSsRSVBV5MCxo7Wv3zhb4jXNDuH5DsKVlXe4xwWl/hvt+5hhdvdtMOF/HQgV5gRLkEZaVDrbRg0ielcAcbmh+C/VBsQMci0nA72EttxIMjx/rzaaMmdOupyW4kRrwJTSAlv0lWCC30MIBmDD6nS8X3AnhB2kJw== mateusc.lira@gmail.com"
}

data "template_file" "user_data" {
        template = file("${path.module}/user_data.sh")

        vars = {
            ecs_cluster_name = "mateusclira-cluster"
      }
}

  resource "aws_launch_template" "ecs_launch_template" {
  name                   = "mateusclira-template"
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
    Name     = "_ECSLaunchTemplate_"
    Scenario = "scenario-ecs-ec2"
  }
}

 resource "aws_autoscaling_group" "general" {
  desired_capacity          = 1
  max_size                  = 1
  min_size                  = 1
  health_check_grace_period = 30
  health_check_type         = "EC2"
  protect_from_scale_in     = true

  vpc_zone_identifier = [var.aws_subnet_private[0], var.aws_subnet_private[1]]
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

module "ecs" {
    source  = "terraform-aws-modules/ecs/aws//modules/cluster"
    version = "5.2.1"

    cluster_name = "mateusclira-cluster"
    default_capacity_provider_use_fargate = false

    autoscaling_capacity_providers = {
    ex-2 = {
      auto_scaling_group_arn         = aws_autoscaling_group.general.arn
      managed_termination_protection = "ENABLED"

      managed_scaling = {
        maximum_scaling_step_size = 1
        minimum_scaling_step_size = 1
        status                    = "ENABLED"
        target_capacity           = 1
      }
      default_capacity_provider_strategy = {
        weight = 1
      }
    }
  }
}
module "ecs_service" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  
  health_check_grace_period_seconds = 30
  name                              = "mateusclira-service"
  cluster_arn                       = module.ecs.arn
  requires_compatibilities          = ["EC2"]
  iam_role_arn                      = aws_iam_role.ecs_service_role.arn

  capacity_provider_strategy = {
  ex-2 = {
      capacity_provider = module.ecs.autoscaling_capacity_providers["ex-2"].name
      weight            = 1
      base              = 1
    }
  }
  volume = {
    my-vol = {}
  }
      # Container definition(s)
  container_definitions = {
    meteorapp = {
      image     = "public.ecr.aws/q3k0a0y5/mateusclira:latest"
      port_mappings = [
        {
          name          = "meteorapp"
          containerPort = 80
          protocol      = "tcp"
        }
      ]
    mount_points = [
      {
        sourceVolume  = "my-vol",
        containerPath = "/var/www/my-vol"
      }
    ]
      # Example image used requires access to write to root filesystem
      readonly_root_filesystem = false
  }
  }
  service_connect_configuration = {
    namespace = "mateusclira"
    service = {
      client_alias = {
        port     = 80
        dns_name = "meteorapp"
      }
      port_name      = "meteorapp"
      discovery_name = "meteorapp"
    }
  }
  load_balancer = {
    service = {
      target_group_arn = var.lb_arn
      container_name   = "meteorapp"
      container_port   = 80
    }
  }
  subnet_ids = [
    var.aws_subnet_public[0],
    var.aws_subnet_public[1]
  ]
  security_group_rules = {
    alb_ingress_3000 = {
      type                     = "ingress"
      from_port                = 0
      to_port                  = 0
      protocol                 = "-1"
      description              = "Service port"
      source_security_group_id = var.alb_sg
    }
    egress_all = {
      type        = "egress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  tags = {
    Environment = "Development"
    Project     = "Example"
  }

  # depends_on = [ aws_ecr_repository.aws-ecr ]
}
  
resource "aws_service_discovery_http_namespace" "main" {
  name = "mateusclira"
}

resource "aws_instance" "bastion" {
  ami                         = "ami-0af9d24bd5539d7af"
  instance_type               = "t3.micro" # used to set core count below
  subnet_id                   = var.aws_subnet_public[0]
  vpc_security_group_ids      = [var.bastion_sg]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.key.key_name
  
  tags = {
    Name = "bastion"
   }
}
