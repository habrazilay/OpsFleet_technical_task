ENV ?= dev
TFVARS = environments/$(ENV)/$(ENV).tfvars
BACKEND = environments/$(ENV)/backend-$(ENV).hcl

init:
	terraform -chdir=environments/$(ENV) init -backend-config=$(BACKEND)

plan: init
	terraform -chdir=environments/$(ENV) plan -var-file=$(TFVARS)

apply: init
	terraform -chdir=environments/$(ENV) apply -var-file=$(TFVARS)

destroy: init
	terraform -chdir=environments/$(ENV) destroy -var-file=$(TFVARS)
