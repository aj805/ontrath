variable "aws_region" {
    type        = string
    description = "Region of the ECR image"
}

variable "function_name" {
    type        = string
    description = "Name of the Lambda Function"
    default     = "aj-epoch-time"
}  

variable "function_handler" {
    type        = string
    description = "Lambda Handler Function"
    default     = "handler"
}

variable "api_name" {
    type        = string
    description = "API Gateway Name"
    default     = "aj-epoch-api"
}

variable "image_repo_name" {
    type        = string
    description = "Name of the ECR image"
}

variable "image_tag" {
    type        = string
    description = "Tag of the ECR image"
}
