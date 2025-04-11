# Epochalypse

# 🚀 One-Click Lambda Deployment Guide

This project includes infrastructure-as-code, a containerized Lambda function, and a one-click deployment script using **Make**, **Terraform**, and the **AWS CLI**.

---

## 🚀 Tools Required

You’ll need the following CLI tools installed (not included in this repo):

- **Terraform** (>= 1.4)  
- **AWS CLI** (>= 2.10)  
- **Docker**  
- **Make** (>= 4.0)  
- **jq**

✅ Ensure your AWS CLI is authenticated and configured using:

```bash
aws configure
```

You should have administrator-level access to the AWS account.

---

## 📁 Project Structure

```
.
├── epoch-api-lambda/               # Go-based Lambda API source code
├── tf/
│   ├── projects/
│   │   ├── account-landing-dev/   # Terraform for ECR setup
│   │   └── api-lambda-dev/        # Terraform for Lambda + API Gateway
├── Makefile                        # One-click deployment logic
└── ReadMe.md                       # You're here
```

---

## ⚙️ Environment Configuration

You may optionally create a `.env` file in the project root to override Makefile defaults:

```env
AWS_REGION=us-west-2
GITHUB_ORG=ajontra
LAMBDA_NAME=aj-epoch-time
IMAGE_TAG=lambda-one-click
```

---

## 🛠️ One-Click Deployment

To deploy the entire stack, run:

```bash
make one-click-lambda-demo IMAGE_TAG=<SET AN IMAGE TAG>
```

This will:

- Create `terraform.auto.tfvars` files for both Terraform projects  
- Build and push a Docker image for the Lambda function  
- Apply the Terraform stack to provision infrastructure  
- Poll the deployed API Gateway endpoint until it responds successfully

---

## 🧪 API Response Format

Once deployed, the API endpoint will return:

```json
{"The current epoch time": 1712793600}
```

You can also manually verify it with:

```bash
curl https://<invoke_url>
```

---

## 🔧 Useful Makefile Targets

| Target                                 | Description                                        |
|----------------------------------------|----------------------------------------------------|
| `make one-click-lambda-demo`           | Full end-to-end deploy and validation              |
| `make docker-build-lambda`             | Build Lambda Docker image                          |
| `make docker-push-to-ecr`              | Push Docker image to ECR                           |
| `make docker-build-lambda-and-push`    | Build & push Lambda image                          |
| `make test-lambda`                     | Run unit tests in `epoch-api-lambda/`              |
| `make update-lambda-image`             | Update Lambda function with latest image           |
| `make init-account-landing-dev`        | Terraform init for IAM/ECR project                 |
| `make plan-account-landing-dev`        | Terraform plan for IAM/ECR project                 |
| `make apply-account-landing-dev`       | Terraform apply for IAM/ECR project                |
| `make init-api-lambda-dev`             | Terraform init for API Gateway + Lambda project    |
| `make plan-api-lambda-dev`             | Terraform plan for API Gateway + Lambda            |
| `make apply-api-lambda-dev`            | Terraform apply for API Gateway + Lambda           |

---

## 🧼 Cleanup

To destroy the deployed infrastructure:

```bash
make destroy-all
```
