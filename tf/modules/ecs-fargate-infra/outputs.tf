output "vpc_id" {
    value = aws_vpc.main.id
}

output "ecs_cluster_id" {
    value = aws_ecs_cluster.fargate.id
}

output "private_subnets" {
    value = aws_subnet.private[*].id
}

output "public_subnets" {
    value = aws_subnet.public[*].id
}

output "security_group_id" {
    value = aws_security_group.alb_sg.id
}

output "alb_arn" {
    value = aws_lb.public_alb.arn
}

output "alb_dns_name" {
    description = "Public URL of the ALB"
    value       = aws_lb.public_alb.dns_name
}
