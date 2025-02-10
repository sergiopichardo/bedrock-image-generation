SSO_PROFILE=sergio_sso

init:
	aws-vault exec $(SSO_PROFILE) -- terraform init

plan:
	aws-vault exec $(SSO_PROFILE) -- terraform plan -var-file=dev.tfvars

apply:
	aws-vault exec $(SSO_PROFILE) -- terraform apply -var-file=dev.tfvars -auto-approve

destroy:
	aws-vault exec $(SSO_PROFILE) -- terraform destroy -var-file=dev.tfvars

