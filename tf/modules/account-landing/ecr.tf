# ECR Repositories

resource "aws_ecr_repository" "epochalypse" {
  name = "${var.github_org}/epochalypse"

  encryption_configuration {
    encryption_type = "AES256"
  }

}