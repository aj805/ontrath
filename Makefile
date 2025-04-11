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

.PHONY: init-account-landing-dev \
        plan-account-landing-dev \
		apply-account-landing-dev \
        init-api-lambda-dev \
		plan-api-lambda-dev \
		apply-api-lambda-dev
		test-lambda \
		docker-build-lambda \
		docker-push-to-ecr \
		docker-build-lambda-and-push \
		create-lambda-tf-vars \
		copy-tf-vars \
		one-click-lambda-demo


init-account-landing-dev:
	terraform -chdir=tf/projects/account-landing-dev init

plan-account-landing-dev:
	terraform -chdir=tf/projects/account-landing-dev plan -out "tfplan"

apply-account-landing-dev:
	terraform -chdir=tf/projects/account-landing-dev apply "tfplan"

init-api-lambda-dev:
	terraform -chdir=tf/projects/api-lambda-dev init

plan-api-lambda-dev:
	terraform -chdir=tf/projects/api-lambda-dev plan -out "tfplan"

apply-api-lambda-dev:
	terraform -chdir=tf/projects/api-lambda-dev apply "tfplan"

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

one-click-lambda-demo:
	@$(MAKE) create-lambda-tf-vars IMAGE_TAG=$(IMAGE_TAG)
	@$(MAKE) init-account-landing-dev
	@$(MAKE) plan-account-landing-dev
	@$(MAKE) apply-account-landing-dev
	@$(MAKE) docker-build-lambda-and-push IMAGE_TAG=$(IMAGE_TAG)
	@$(MAKE) init-api-lambda-dev
	@$(MAKE) plan-api-lambda-dev
	@$(MAKE) apply-api-lambda-dev
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
	done
	@echo "\n"
	@echo "🎉 One-click Lambda deploy complete!"

destroy-lambda-dev:
    terraform -chdir=tf/projects/api-lambda-dev init
	terraform -chdir=tf/projects/api-lambda-dev destroy

destroy-account-landing-dev:
    terraform -chdir=tf/projects/account-landing-dev init
	terraform -chdir=tf/projects/account-landing-dev destroy

destroy-all: destroy-lambda-dev destroy-account-landing-dev
