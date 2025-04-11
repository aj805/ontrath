TF_DIR=tf/projects/dev-account
ifndef AWS_REGION
  $(error AWS_REGION is not set. Export it or pass it inline: AWS_REGION=us-west-2 make ...)
endif

.PHONY: init-dev plan-dev-account

init-dev-account:
	terraform -chdir=tf/projects/dev-account init

plan-dev-account:
ifndef VAR_FILE
	$(error VAR_FILE is not set. Usage: make plan-dev-account VAR_FILE=alex-dev.tfvars)
endif
	terraform -chdir=tf/projects/dev-account plan -var-file=$(VAR_FILE) -out "dev-account.tfplan"

apply-dev-account:
	terraform -chdir=tf/projects/dev-account apply "dev-account.tfplan"
