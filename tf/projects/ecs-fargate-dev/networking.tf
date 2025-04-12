resource "aws_lb_target_group" "ecs_tg" {
  name     = "${var.vpc_name}-epoch-api"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = module.ecs-fargate-infra.vpc_id

  target_type = "ip"
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = module.ecs-fargate-infra.alb_arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs_tg.arn
  }
}

resource "aws_security_group" "ecs" {
  name        = "${var.vpc_name}-ecs"
  vpc_id      = module.ecs-fargate-infra.vpc_id

  ingress {
    from_port   = 80
    to_port     = 8080
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
