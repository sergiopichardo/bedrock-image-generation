init:
	aws-vault exec sergio_sso -- terraform init

plan:
	aws-vault exec sergio_sso -- terraform plan -var-file=dev.tfvars

apply:
	aws-vault exec sergio_sso -- terraform apply -var-file=dev.tfvars -auto-approve

destroy:
	aws-vault exec sergio_sso -- terraform destroy -var-file=dev.tfvars

