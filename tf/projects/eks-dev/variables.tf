variable "aws_region" {
    default = "us-west-2"
}

variable "vpc_name" {
    default = "ajontra-eks"
}

variable "vpc_cidr" {
    default = "10.99.0.0/16"
}

variable "cluster_name" {
    default = "ajontra-dev"
}

variable "image_repo_root" {}

variable "image_repo" {
    default = "ajontra/epochalypse"
}
