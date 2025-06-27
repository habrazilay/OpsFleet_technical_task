ENV ?= dev
TFDIR = environments/$(ENV)
TFVARS = $(ENV).tfvars          # dev.tfvars, staging.tfvars, …
PLAN = tfplan            		 # binary
PLANJSON = plan.json      		 # human-readable
STATE_FILE = terraform.tfstate
BACKUP_DIR = backups/$(ENV)

init:
	@terraform -chdir=$(TFDIR) init -reconfigure	

plan: init
	@terraform -chdir=$(TFDIR) plan -var-file=$(TFVARS) -out=$(PLAN)
	@terraform -chdir=$(TFDIR) show -json $(PLAN) > $(PLANJSON)
	@echo "✅ Plan complete and saved to $(PLAN) and $(PLANJSON)"

apply: init
	@terraform -chdir=$(TFDIR) apply -var-file=$(TFVARS) -auto-approve
	@mkdir -p $(BACKUP_DIR)
	@cp $(TFDIR)/$(STATE_FILE) $(BACKUP_DIR)/$(STATE_FILE).$(shell date +"%Y%m%d-%H%M%S").backup
	@echo "✅ State backup created at $(BACKUP_DIR)/"

destroy: init
	@terraform -chdir=$(TFDIR) destroy -var-file=$(TFVARS) -auto-approve

vpc: init
	@terraform -chdir=$(TFDIR) apply -target=module.vpc -var-file=$(TFVARS) -auto-approve

eks: init
	@terraform -chdir=$(TFDIR) apply -target=module.eks -var-file=$(TFVARS) -auto-approve
