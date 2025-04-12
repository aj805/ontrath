resource "aws_ecs_cluster" "fargate" {
  name = var.vpc_name
}
