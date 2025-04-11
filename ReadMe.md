# Epochalypse

Returns the current epoch time

## Prerequesites and Dependencies

* AWS CLI - aws-cli/2.24.0
* Terraform - v1.11.3
* Docker - Tested with 28.0.4
* Make - GNU Make 3.81

## Setup

* Set AWS_REGION env var to the correct region for your AWS Account environment. 
example: `AWS_REGION=us-west-2` or `AWS_REGION=us-east-1`
* Set AWS credentials for aws-cli usage


## Create AWS Account Landing Space
The Account Landing Space is for resources that would be shared across multiple environments in one AWS Account such as and ECR Image Repo. One image repo in an account could be used to deploy images to multiple application environments. 


1. Run the Dev Account Terraform Plan
```
VAR_FILE=<tfvars-file> make plan-dev-account
```

Expected output:
```
Terraform will perform the following actions:

  # module.aws-dev.aws_ecr_repository.epochalypse will be created
  + resource "aws_ecr_repository" "epochalypse" {
      + arn                  = (known after apply)
      + id                   = (known after apply)
      + image_tag_mutability = "MUTABLE"
      + name                 = "ajontra/epochalypse"
      + registry_id          = (known after apply)
      + repository_url       = (known after apply)
      + tags_all             = (known after apply)

      + encryption_configuration {
          + encryption_type = "AES256"
          + kms_key         = (known after apply)
        }
    }

Plan: 1 to add, 0 to change, 0 to destroy.
```

2. Apply the Dev Account Plan
```
make apply-dev-account
```

Expected output:
```
terraform -chdir=tf/projects/dev-account apply "dev-account.tfplan"
module.aws-dev.aws_ecr_repository.epochalypse: Creating...
module.aws-dev.aws_ecr_repository.epochalypse: Creation complete after 0s [id=ajontra/epochalypse]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```
