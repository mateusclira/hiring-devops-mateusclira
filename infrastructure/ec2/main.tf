data "aws_availability_zones" "available" {}

resource "aws_instance" "instance1" {
  ami                         = "ami-0af9d24bd5539d7af"
  instance_type               = "t3.micro" # used to set core count below
  availability_zone           = "us-east-1a"
  subnet_id                   = var.aws_subnet_private[0]
  vpc_security_group_ids      = [var.ec2_sg]
  key_name                    = aws_key_pair.key.key_name

  user_data = data.template_file.userdata.rendered
}

resource "aws_instance" "instance2" {
  ami                         = "ami-0af9d24bd5539d7af"
  instance_type               = "t3.micro" # used to set core count below
  availability_zone           = "us-east-1b"
  subnet_id                   = var.aws_subnet_private[1]
  vpc_security_group_ids      = [var.ec2_sg]
  key_name                    = aws_key_pair.key.key_name

  user_data = data.template_file.userdata.rendered
}

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

data "template_file" "userdata" {
  template = file("${path.module}/userdata.tpl")
#   vars = {
#     DOCKER_NODE   = filebase64("${path.root}./app/node/Dockerfile")
#   }
}
