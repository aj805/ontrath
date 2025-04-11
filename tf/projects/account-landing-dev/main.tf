provider "aws" {
    region = var.aws_region
}

module "aws-dev" {
    source = "../../modules/account-landing"

    github_org = var.github_org
}
