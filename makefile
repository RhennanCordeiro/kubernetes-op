# Variáveis
DEBIAN_IMAGE_URL := https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2
DEBIAN_IMAGE_FILE := debian-12-genericcloud-amd64.qcow2
RESIZE_SIZE := 10G
USER_HOME := $(shell echo $$HOME)
KNOWN_HOSTS := $(USER_HOME)/.ssh/known_hosts
IPS := 192.168.122.101 192.168.122.102 192.168.122.103 192.168.122.104

# Funções para comandos comuns
remove_known_hosts = $(foreach ip,$(IPS),ssh-keygen -f "$(KNOWN_HOSTS)" -R "$(ip)";)

download_image:
	wget -nc $(DEBIAN_IMAGE_URL)

resize_image:
	qemu-img resize $(DEBIAN_IMAGE_FILE) $(RESIZE_SIZE)

terraform_apply:
	terraform init
	terraform apply -auto-approve

terraform_destroy:
	terraform destroy -auto-approve

remove_ssh_hosts:
	$(call remove_known_hosts)

# Targets
create: download_image resize_image remove_ssh_hosts terraform_apply

destroy: terraform_destroy remove_ssh_hosts

recreate: destroy create

clean:
	git clean -xdf
