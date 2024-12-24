create:
	wget -nc https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2
	qemu-img resize debian-12-genericcloud-amd64.qcow2 10G
	terraform init
	terraform apply -auto-approve

destroy:
	terraform destroy -auto-approve

recreate:
	terraform destroy -auto-approve
	wget -nc https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2
	qemu-img resize debian-12-genericcloud-amd64.qcow2 10G
	terraform init
	terraform apply -auto-approve

clean:
	git clean -xdf