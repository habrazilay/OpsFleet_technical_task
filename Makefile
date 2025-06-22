ENV ?= dev
TFVARS  = $(ENV).tfvars          # dev.tfvars, staging.tfvars, …
# BACKEND = backend-$(ENV).hcl     # backend-dev.hcl, backend-staging.hcl, …

init:
	terraform -chdir=environments/$(ENV) init \
		-backend-config=$(BACKEND)

plan: init
	terraform -chdir=environments/$(ENV) plan \
		-var-file=$(TFVARS)

apply: init
	terraform -chdir=environments/$(ENV) apply -var-file=$(TFVARS)

destroy: init
	terraform -chdir=environments/$(ENV) destroy -var-file=$(TFVARS)

