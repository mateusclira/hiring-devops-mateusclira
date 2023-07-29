resource "aws_ecr_repository" "aws-ecr" {
  name = "${var.name}-ecr"
}
