variable "aws_region" {
    default = "us-west-2"
}

variable "vpc_name" {
    default = "ajontra"
}

variable "vpc_cidr" {
    default = "10.88.0.0/16"
}

variable "image" {
    default = "305578904386.dkr.ecr.us-west-2.amazonaws.com/ajontra/epochalypse:ecs-dev"
}
