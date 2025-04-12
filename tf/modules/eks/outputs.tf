output "vpc_id" {
    value = aws_vpc.main.id
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

output "cluster_endpoint" {
    value = module.eks.cluster_endpoint
}

output "epoch_api_role_arn" {
    value = aws_iam_role.epoch_api.arn
}
