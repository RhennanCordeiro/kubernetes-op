terraform {
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

# Variáveis para os nomes das máquinas e IPs estáticos
variable "vm_names" {
  default = ["kubernetes1", "kubernetes2", "kubernetes3"]
}

variable "vm_ips" {
  default = ["192.168.122.101", "192.168.122.102", "192.168.122.103"]
}

# Variáveis para configuração do keepalived
variable "vip" {
  default = "192.168.122.200"  # IP virtual
}

# Definir a prioridade e o estado para cada instância
locals {
  instance_priority = {
    "kubernetes1" = 100
    "kubernetes2" = 90
    "kubernetes3" = 80
  }

  instance_state = {
    "kubernetes1" = "MASTER"
    "kubernetes2" = "BACKUP"
    "kubernetes3" = "BACKUP"
  }
}

# Volume base (imagem principal)
resource "libvirt_volume" "debian12_base" {
  name   = "debian12.qcow2"
  pool   = "default"
  source = "debian-12-genericcloud-amd64.qcow2"
  format = "qcow2"
}

# Volumes individuais para cada VM
resource "libvirt_volume" "debian12_volumes" {
  for_each = toset(var.vm_names)

  name   = "${each.key}.qcow2"
  pool   = "default"
  source = libvirt_volume.debian12_base.id
  format = "qcow2"
}

# Cloud-init
data "template_file" "user_data" {
  for_each = toset(var.vm_names)

  template = file("${path.module}/cloud_init.cfg")

  vars = {
    static_ip      = var.vm_ips[index(var.vm_names, each.key)]
    instance_state = local.instance_state[each.key]
    priority       = local.instance_priority[each.key]
    virtual_ip     = var.vip
    hostname       = each.key
    ssh_public_key   = file("~/.ssh/id_rsa.pub")
  }
}


resource "libvirt_cloudinit_disk" "commoninit" {
  for_each = toset(var.vm_names)

  name      = "commoninit-${each.key}"
  user_data = data.template_file.user_data[each.key].rendered
}

# Criar máquinas dinamicamente
resource "libvirt_domain" "debian12" {
  for_each = toset(var.vm_names)

  name     = each.key
  memory   = "2048"
  vcpu     = 2
  cloudinit = libvirt_cloudinit_disk.commoninit[each.key].id

  network_interface {
    network_name   = "default" # List networks with virsh net-list
    addresses      = [var.vm_ips[index(var.vm_names, each.key)]]
    wait_for_lease = false
  }

  disk {
    volume_id = libvirt_volume.debian12_volumes[each.key].id
  }

  console {
    type        = "pty"
    target_type = "serial"
    target_port = "0"
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }
}

# Outputs dos IPs
output "vm_ips" {
  value = {
    for vm in libvirt_domain.debian12 :
    vm.name => vm.network_interface[0].addresses[0]
  }
}
