create:
	terraform init
	terraform apply -auto-approve

destroy:
	terraform destroy -auto-approve

clean:
	git clean -xdf