output "cluster_endpoint" {
    value = module.eks-infra.cluster_endpoint
}

output "alb_sg" {
    value = module.eks-infra.security_group_id
}

output "public_subnets" {
    value = module.eks-infra.public_subnets
}

output "private_subnets" {
    value = module.eks-infra.private_subnets
}

output "valueoverrides" {
    value = local.valueoverrides
}

output "ingressclassparams" {
    value = local.ingressclassparams
}
