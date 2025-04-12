include .env
TF_DIR ?= tf/projects/dev-account
GITHUB_ORG ?= "ajontra"
LAMBDA_NAME ?= "aj-epoch-time"
AWS_REGION ?= "us-west-2"
IMAGE_REPO_ROOT ?= 305578904386.dkr.ecr.us-west-2.amazonaws.com
IMAGE_REPO ?= $(GITHUB_ORG)/epochalypse
IMAGE_TAG ?= test
IMAGE_FULL_PATH ?= "$(IMAGE_REPO_ROOT)/$(IMAGE_REPO):$(IMAGE_TAG)"

ifndef AWS_REGION
  $(error AWS_REGION is not set. Export it or pass it inline: AWS_REGION=us-west-2 make ...)
endif

.PHONY:

create-account-landing-tf-vars:
	@echo "github_org = \"$(GITHUB_ORG)\"" > tf/projects/account-landing-dev/terraform.auto.tfvars
	@echo "aws_region = \"$(AWS_REGION)\"" >> tf/projects/account-landing-dev/terraform.auto.tfvars

init-account-landing-dev:
	@$(MAKE) create-account-landing-tf-vars
	terraform -chdir=tf/projects/account-landing-dev init

plan-account-landing-dev:
	@$(MAKE) init-account-landing-dev
	terraform -chdir=tf/projects/account-landing-dev plan -out "tfplan"

apply-account-landing-dev:
	@$(MAKE) init-account-landing-dev
	terraform -chdir=tf/projects/account-landing-dev apply "tfplan"

auto-apply-account-landing-dev:
	@$(MAKE) init-account-landing-dev
	terraform -chdir=tf/projects/account-landing-dev apply -auto-approve

init-api-lambda-dev:
	@$(MAKE) create-lambda-tf-vars IMAGE_TAG=$(IMAGE_TAG)
	terraform -chdir=tf/projects/api-lambda-dev init

plan-api-lambda-dev:
	terraform -chdir=tf/projects/api-lambda-dev plan -out "tfplan"

apply-api-lambda-dev:
	terraform -chdir=tf/projects/api-lambda-dev apply "tfplan"

auto-apply-api-lambda-dev:
	@$(MAKE) init-api-lambda-dev
	terraform -chdir=tf/projects/api-lambda-dev apply -auto-approve

update-lambda-image:
	@echo "🔄 Updating Lambda function $(LAMBDA_NAME) with image: $(IMAGE_REPO):$(IMAGE_TAG)"
	@aws lambda update-function-code \
		--function-name $(LAMBDA_NAME) \
		--image-uri $(IMAGE_FULL_PATH) \
		--region $(AWS_REGION) >/dev/null 2>&1
	@echo "⏳ Waiting for Lambda function update to complete..."

	@while true; do \
	  status=$$(aws lambda get-function-configuration \
	    --function-name $(LAMBDA_NAME) \
	    --region $(AWS_REGION) \
	    --query 'LastUpdateStatus' \
	    --output text) ; \
	  if [ "$$status" = "Successful" ]; then \
	    echo "✅ Lambda update completed successfully!"; \
	    break; \
	  elif [ "$$status" = "Failed" ]; then \
	    echo "❌ Lambda update failed!"; \
	    exit 1; \
	  else \
	    echo "🔄 Current status: $$status... waiting"; \
	    sleep 2; \
	  fi; \
	done
	@echo "✅ Lambda function updated successfully!"

test-lambda:
	cd epoch-api-lambda && go test

docker-build-lambda:
	@echo "Building Docker Image $(IMAGE_FULL_PATH)"
	docker buildx build --platform linux/amd64 --provenance=false -t $(IMAGE_FULL_PATH) ./epoch-api-lambda --file epoch-api-lambda/Dockerfile

docker-push-to-ecr:
	aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin $(IMAGE_REPO_ROOT)
	docker push $(IMAGE_FULL_PATH)

docker-build-lambda-and-push: \
    docker-build-lambda \
	docker-push-to-ecr

create-lambda-tf-vars:
	@echo "github_org = \"$(GITHUB_ORG)\"" > tf/projects/account-landing-dev/terraform.auto.tfvars
	@echo "aws_region = \"$(AWS_REGION)\"" >> tf/projects/account-landing-dev/terraform.auto.tfvars
	@echo "aws_region = \"$(AWS_REGION)\"" > tf/projects/api-lambda-dev/terraform.auto.tfvars
	@echo "function_name = \"$(LAMBDA_NAME)\"" >> tf/projects/api-lambda-dev/terraform.auto.tfvars
	@echo "image_repo_name = \"$(IMAGE_REPO)\"" >> tf/projects/api-lambda-dev/terraform.auto.tfvars
	@echo "image_tag = \"$(IMAGE_TAG)\"" >> tf/projects/api-lambda-dev/terraform.auto.tfvars
	@echo "Created terraform.auto.tfvars using ENV vars."

copy-tf-vars:
	@cp terraform.tfvars $(PROJECT_PATH)/terraform.tfvars

lambda-deploy:
	@$(MAKE) auto-apply-account-landing-dev
	@$(MAKE) docker-build-lambda-and-push IMAGE_TAG=$(IMAGE_TAG)
	@$(MAKE) auto-apply-api-lambda-dev
	@$(MAKE) update-lambda-image
	@echo "\n"
	@echo "✅ Finished deployment. Waiting for Lambda to be ready...\n"
	@INVOKE_URL=$$(terraform -chdir=tf/projects/api-lambda-dev output -json | jq -r '.invoke_url.value'); \
	echo "🔗 Polling: $$INVOKE_URL"; \
	while true; do \
		echo "⏳ Checking..."; \
		RES=$$(curl -s -D - "$$INVOKE_URL"); \
		BODY=$$(echo "$$RES" | sed -n '/^\r$$/,$$p' | tail -n +2); \
		STATUS=$$(echo "$$RES" | grep HTTP | awk '{print $$2}'); \
		HEADER_IMAGE_TAG=$$(echo "$$RES" | grep -i '^image-tag:' | awk '{print $$2}' | tr -d '\r'); \
		if [ "$$STATUS" = "200" ] && \
		   echo "$$BODY" | jq -e '."The current epoch time" | numbers' >/dev/null 2>&1 && \
		   [ "$$HEADER_IMAGE_TAG" = "$(IMAGE_TAG)" ]; then \
			echo "✅ Lambda responded with correct Image-Tag header: $$HEADER_IMAGE_TAG and valid JSON:"; \
			echo "$$BODY"; \
			break; \
		else \
			echo "❌ Not ready yet (status: $$STATUS, image-tag: $$HEADER_IMAGE_TAG), retrying in 5s..."; \
			sleep 5; \
		fi; \
	done; \
	echo "\n"; \
	echo "🎉 Lambda deploy complete!"; \
	echo "Try it: ' curl $$INVOKE_URL ' ";

destroy-lambda:
	terraform -chdir=tf/projects/api-lambda-dev apply -destroy

destroy-account-landing:
	terraform -chdir=tf/projects/account-landing-dev apply -destroy

docker-build:
	@echo "Building Docker Image $(IMAGE_FULL_PATH)"
	docker buildx build --platform linux/amd64 -t $(IMAGE_FULL_PATH) ./epoch-api --file epoch-api/Dockerfile

docker-build-and-push: \
    docker-build \
	docker-push-to-ecr

ecs-init:
	terraform -chdir=tf/projects/ecs-fargate-dev init

ecs-deploy:
	terraform -chdir=tf/projects/account-landing-dev apply -auto-approve

	@$(MAKE) docker-build-and-push IMAGE_TAG=$(IMAGE_TAG)

	@$(MAKE) ecs-init
	TF_VAR_image=$(IMAGE_FULL_PATH) terraform -chdir=tf/projects/ecs-fargate-dev apply -auto-approve
	@echo "✅ Finished deployment. Waiting for ECS Service to be ready...\n"

	@ECS_URL=$$(terraform -chdir=tf/projects/ecs-fargate-dev output -json | jq -r '.alb_dns_name.value'); \
	echo "🔗 Polling: $$ECS_URL"; \
	while true; do \
		echo "⏳ Checking..."; \
		RES=$$(curl -s -D - "$$ECS_URL"); \
		BODY=$$(echo "$$RES" | sed -n '/^\r$$/,$$p' | tail -n +2); \
		STATUS=$$(echo "$$RES" | grep HTTP | awk '{print $$2}'); \
		if [ "$$STATUS" = "200" ] && \
		   echo "$$BODY" | jq -e '."The current epoch time" | numbers' >/dev/null 2>&1; then \
			echo "✅ ECS Service responded with correct valid JSON:"; \
			echo "$$BODY"; \
			break; \
		else \
			echo "❌ Not ready yet (status: $$STATUS, retrying in 5s..."; \
			sleep 5; \
		fi; \
	done; \
	echo "\n"; \
	echo "🎉 ECS deploy complete!"; \
	echo "Try it: ' curl $$ECS_URL ' ";
	@echo "\n"

destroy-ecs:
	terraform -chdir=tf/projects/ecs-fargate-dev apply -destroy

eks-use-context:
	aws eks update-kubeconfig --region $(AWS_REGION) --name ajontra-dev
	@CONTEXT_ARN=$$(kubectl config get-contexts --no-headers -o name | grep ajontra-dev ) && \
    	kubectl config use-context $$CONTEXT_ARN

eks-init:
	terraform -chdir=tf/projects/eks-dev init

eks-plan:
	terraform -chdir=tf/projects/eks-dev plan -out "tfplan"

eks-apply:
	terraform -chdir=tf/projects/eks-dev apply "tfplan"

eks-deploy:
	terraform -chdir=tf/projects/account-landing-dev apply -auto-approve

	@$(MAKE) docker-build-and-push IMAGE_TAG=$(IMAGE_TAG)

	@$(MAKE) eks-init

	TF_VAR_aws_region=$(AWS_REGION) TF_VAR_image_repo_root=$(IMAGE_REPO_ROOT) TF_VAR_image_repo=$(IMAGE_REPO) \
		terraform -chdir=tf/projects/eks-dev apply -auto-approve

	@VALUE_OVERRIDES=$$(terraform -chdir=tf/projects/eks-dev output -json | jq -r '.valueoverrides.value'); \
	echo "$$VALUE_OVERRIDES" > ./k8s/value-overrides/eks-dev.yaml

	@INGRESS_CLASS_PARAMS=$$(terraform -chdir=tf/projects/eks-dev output -json | jq -r '.ingressclassparams.value'); \
	echo "$$INGRESS_CLASS_PARAMS" > ./k8s/aws-ingress/ingressclassparams.yaml

	aws eks update-kubeconfig --region $(AWS_REGION) --name ajontra-dev
	@$(MAKE) eks-use-context

	kubectl apply -f ./k8s/aws-ingress && \
		helm upgrade epoch-api --install ./k8s/epoch-api \
		-f k8s/value-overrides/eks-dev.yaml \
		--set image.tag=$(IMAGE_TAG) --wait --timeout 11m
	
	@ALB_HOST=$$(kubectl get ingress --no-headers | awk '{print $$4}') && \
	echo "alb host: $$ALB_HOST \n"; \
	while true; do \
		echo "⏳ Checking..."; \
		RES=$$(curl -H "Host: epoch-api.dev" -s -D - "$$ALB_HOST"); \
		BODY=$$(echo "$$RES" | sed -n '/^\r$$/,$$p' | tail -n +2); \
		STATUS=$$(echo "$$RES" | grep HTTP | awk '{print $$2}'); \
		if [ "$$STATUS" = "200" ] && \
		   echo "$$BODY" | jq -e '."The current epoch time" | numbers' >/dev/null 2>&1; then \
			echo "✅ EKS Service responded with correct valid JSON:"; \
			echo "$$BODY"; \
			break; \
		else \
			echo "❌ Not ready yet (status: $$STATUS, retrying in 5s..."; \
			sleep 5; \
		fi; \
	done ; \
	echo "\n"; \
	echo "🎉 EKS deploy complete!"; \
	echo "Try it: ' curl -H \"Host: epoch-api.dev\" $$ALB_HOST ' ";
	@echo "\n"

eks-uninstall:
	@$(MAKE) eks-use-context
	helm uninstall epoch-api

destroy-eks:
	@$(MAKE) eks-uninstall
	terraform -chdir=tf/projects/eks-dev apply -destroy

destroy-all: \
	destroy-lambda \
	destroy-account-landing \
	destroy-ecs \
	destroy-eks

