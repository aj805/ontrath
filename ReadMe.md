# Epochalypse

This project includes infrastructure-as-code, a containerized Lambda function, a containerized http service for ECS and EKS deployments, and deployment commands using **Make**.

---

## 🚀 Tools Required

You’ll need the following CLI tools installed (not included in this repo):

- **Terraform** - Tested with 1.11.3 
- **AWS CLI** - Tested with aws-cli/2.24.0 Python/3.12.6 Darwin/24.3.0 exe/x86_64  
- **Docker** - Tested with v28.0.4
- **Make** - Tested with GNU Make 3.81
- **jq** - Tested with jq-1.6-159-apple-gcff5336-dirty

For the EKS implementation:

- **kubectl** - Client Version: v1.32.1
- **helm** - v3.17.3

✅ Ensure your AWS CLI is authenticated and configured using:

```bash
aws configure
```
Or by setting the AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY env vars + AWS_SESSION_TOKEN if needed. 

You should have administrator-level access to the AWS account.

---

## ⚙️ Environment Configuration

You may set ENV vars or optionally create a `.env` file in the project root to override Makefile defaults:

```bash
export AWS_REGION=us-west-2
export GITHUB_ORG=ajontra
export LAMBDA_NAME=aj-epoch-time
export IMAGE_REPO_ROOT=305578904386.dkr.ecr.us-west-2.amazonaws.com
export IMAGE_REPO=ajontra/epochalypse
export IMAGE_TAG=one-click-demo
```

---

## 🛠️ Deployment Commands


### Lambda + API Gateway

To deploy the Lambda + API Gateway solution run:

```bash
make lambda-deploy IMAGE_TAG=<SET AN IMAGE TAG>
```

This will:

- Create `terraform.auto.tfvars` files for Terraform
- Build and push a Docker image from the ./epoch-api-lambda app for the Lambda function  
- Apply the Terraform stack to provision infrastructure creating a local terraform.tfstate file in the project directory. 
- Poll the deployed API Gateway endpoint until it responds successfully


### ECS Fargate + ALB

ETA approx 6-12 minutes. 3-5 min for the infra, 1-2 min for Docker, 3-5 min for the ECS Service to deploy and be ready. 

To deploy the ECS Fargate + ALB solution run:

```bash
make ecs-deploy IMAGE_TAG=<SET AN IMAGE TAG>
```

The IMAGE_TAG can be anything. 

This will:

- Create `terraform.auto.tfvars` files for Terraform.
- Apply the Account Landing project to create the ECR Repository.
- Build and push a Docker image from the ./epoch-api app for the ECS Task Definition and Service.
- Apply the Terraform stack to provision infrastructure creating a local terraform.tfstate file in the project directory. 
- The Terraform for the ECS Service definition has the `wait_for_ready_state = true` set so the service should be ready when Terraform is done applying.
- The ALB DNS Name should be output to be able to use in curl or a browser. 

---

### EKS Auto Mode + AWS Ingress Class

ETA approx 15-25 minutes. 8-12 min for the infra, 1-2 min for Docker, 6-10 min for the EKS Service to deploy via Helm and for the ALB to be ready. The Helm command will wait and timeout after 11 minutes. 

To deploy the EKS Auto Mode + AWS Ingress Class run:

```bash
make eks-deploy IMAGE_TAG=<SET AN IMAGE TAG>
```

The IMAGE_TAG can be any string I believe up to 63 characters. 

This will:

- Create `terraform.auto.tfvars` files for Terraform.
- Apply the Account Landing project to create the ECR Repository.
- Build and push a Docker image from the ./epoch-api app for the EKS Deployment.
- Apply the tf/projects/eks-dev project to create an EKS Cluster in Auto Mode
- Generate manifests for AWS Ingress Class Params and a value override file for Helm install. 
- Kubectl Apply the AWS Ingress manifests
- Helm Upgrade/Install the ./k8s/epoch-api chart and wait

An ALB is provisined during the helm install. 

The curl command for this implementation will need to pass the Host header. 

```bash
curl -H "Host: epoch-api.dev" <ALB DNS>
```

The host is defined in the k8s/epoch-api/templatees/ingress.yaml

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

## 🧼 Cleanup

There are a few destroy commands in the Makefile. You will be prompted to enter 'yes' for each statefile. 

To destroy everything:

```bash
make destroy-all
```

---

## 📁 Project Structure

```
.
├── epoch-api-lambda/              # GOlang Lambda API source code
├── epoch-api/                     # GOlang Basic Http Service for ECS or Kubernetes
├── tf/
│   ├── modules/
│   │   ├── account-landing/       # Terraform Module for AWS Account Landing - ECR setup
│   │   ├── api-lambda/            # Terraform Module for API Gateway + Lambda
│   │   ├── ecs-fargate-infra/     # Terraform Module for infra base. VPC, Subnets, ALB, ECS Cluster, etc
│   │   ├── eks/                   # Terraform Module for infra base. VPC, Subnets and EKS Cluster
│   ├── projects/
│   │   ├── account-landing-dev/   # Terraform Project for AWS Dev Account Landing Creation
│   │   └── api-lambda-dev/        # Terraform Project for API Gateway + Lambda Deploy
│   │   └── ecs-fargate-dev/       # Terraform Project for ECS Fargate Deploy
│   │   └── eks-dev/               # Terraform Project for EKS Deploy
├── Makefile                       # CICD Commands
└── ReadMe.md                      # You're here
```

## 🔧 Useful Makefile Targets

| Target                                 | Description                                        |
|----------------------------------------|----------------------------------------------------|
| `make lambda-deploy`                   | Full end-to-end deploy and validation of Lambda    |
| `make ecs-deploy`                      | Full end-to-end deploy and validation of ECS       |
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
| `make destroy-all`                     | Run all the make destroy commands                  |

---

## 🧼 Cleanup

To destroy the deployed infrastructure:

```bash
make destroy-all
```
