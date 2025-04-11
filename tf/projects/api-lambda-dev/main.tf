module "api-lambda" {
    source = "../../modules/api-lambda"

    aws_region = var.aws_region
    
    image_repo_name = var.image_repo_name
    image_tag       = var.image_tag

}

output "invoke_url" {
    value = module.api-lambda.invoke_url
}
