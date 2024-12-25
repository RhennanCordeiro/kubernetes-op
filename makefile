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
	ssh-keygen -f "/home/rhennan/.ssh/known_hosts" -R "192.168.122.101"
	ssh-keygen -f "/home/rhennan/.ssh/known_hosts" -R "192.168.122.102"
	ssh-keygen -f "/home/rhennan/.ssh/known_hosts" -R "192.168.122.103"

clean:
	git clean -xdf