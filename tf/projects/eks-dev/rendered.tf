locals {
    valueoverrides = templatefile("valueoverrides.yaml.tftpl", {
        image_repo_root = var.image_repo_root
        image_repo = var.image_repo
        service_account_role_arn = module.eks-infra.epoch_api_role_arn
    })

    ingressclassparams = templatefile("ingressclassparams.yaml.tftpl", {
        subnets = module.eks-infra.public_subnets
    })
}
