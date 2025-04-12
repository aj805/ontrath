module "ecs-fargate-infra" {
    source = "../../modules/ecs-fargate-infra"

    aws_region = var.aws_region
   
    vpc_name = var.vpc_name
    vpc_cidr = var.vpc_cidr
}

locals {
    container_name = "epoch-api"
}

resource "aws_ecs_task_definition" "app" {
    family                   = "${var.vpc_name}-epoch-api"
    requires_compatibilities = ["FARGATE"]
    network_mode             = "awsvpc"
    cpu                      = "256"
    memory                   = "512"
    execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

    container_definitions = jsonencode([{
        name      = local.container_name
        image     = var.image
        essential = true
        portMappings = [{
            containerPort = 8080
            hostPort      = 8080
        }]

        healthCheck = {
            startPeriod = 10
            command = [
                "CMD-SHELL",
                "curl -f http://localhost:8080/healthz || exit 1"
            ]
            interval = 10
            timeout  = 2
            retries  = 5
        }
    }])
}

resource "aws_ecs_service" "app" {
  name            = "${var.vpc_name}-epoch-api"
  cluster         = module.ecs-fargate-infra.ecs_cluster_id
  task_definition = aws_ecs_task_definition.app.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets         = module.ecs-fargate-infra.private_subnets
    assign_public_ip = false
    security_groups = [aws_security_group.ecs.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs_tg.arn
    container_name   = local.container_name
    container_port   = 8080
  }

  wait_for_steady_state = true

  depends_on = [module.ecs-fargate-infra]
}
