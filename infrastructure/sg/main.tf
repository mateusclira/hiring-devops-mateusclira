resource "aws_security_group" "alb" {
  name        = "alb"
  description = "Allow TLS inbound traffic"
  vpc_id      = var.vpc_id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_security_group" "ec2" {
  name        = "ec2"
  description = "Allow TLS inbound traffic"
  vpc_id      = var.vpc_id
  ingress {
    description     = "Allow ingress traffic from ALB on HTTP on ephemeral ports"
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }
  ingress {
    description     = "Allow SSH ingress traffic from bastion host"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }
  egress {
    description = "Allow all egress traffic"
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#I Created this bastion so I could connect first on the bastion using SSH with my Public IP and then on the ec2
#I also needed to create RSA keys to connect on the bastion and EC2

#I Had to pass my rsa key to the bastion, I did it just using vi id_rsa and copied the key into it.
#I needed to give CHMOD 400 on the key to be able to connect

# to create the key: ssh-keygen -t rsa -b 4096 -C my-email@mail.com
# ssh -i id_rsa ubuntu@(private_ip)

resource "aws_security_group" "bastion" {
  name        = "bastion"
  description = "Allow TLS inbound traffic"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
