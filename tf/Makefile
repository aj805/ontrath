ACCOUNT_TF_DIR=tf/projects/dev-account

.PHONY: init-dev plan-dev-account

init-dev:
	terraform -chdir=$(TF_ACCOUNT_DIR) init

plan-dev-account:
ifndef VAR_FILE
	$(error VAR_FILE is not set. Usage: make plan-dev-account VAR_FILE=alex-dev.tfvars)
endif
	terraform -chdir=$(TF_ACCOUNT_DIR) plan -out=dev-account.tfplan -var-file=$(VAR_FILE)
