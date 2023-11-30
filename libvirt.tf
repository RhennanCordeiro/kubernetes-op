# Defining VM Volume
resource "libvirt_volume" "debian12-qcow2" {
  name = "debian12.qcow2"
  pool = "default" # List storage pools using virsh pool-list
  #source = "https://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud.qcow2"
  #source = "CentOS-7-x86_64-GenericCloud.qcow2"
  #source = "debian-11-genericcloud-amd64.qcow2"
  source = "https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2"
  format = "qcow2"
  
}

data "template_file" "user_data"{
  template = file("${path.module}/cloud_init.cfg")
}
resource "libvirt_cloudinit_disk" "commoninit" {
  name = "commoninit"
  user_data = data.template_file.user_data.rendered
}

# Generate a random vm name
resource "random_string" "vm-name" {
  length  = 12
  upper   = false
  lower   = true
  special = false
}

# Define KVM domain to create
resource "libvirt_domain" "debian12" {
  name   = "debian-12-${random_string.vm-name.result}"
  memory = "2048"
  vcpu   = 2
  cloudinit = libvirt_cloudinit_disk.commoninit.id
  network_interface {
    network_name = "default" # List networks with virsh net-list
    wait_for_lease = "true"
  }

  disk {
    volume_id = "${libvirt_volume.debian12-qcow2.id}"
  }
  console {
    type = "pty"
    target_type = "serial"
    target_port = "0"
  }

  graphics {
    type = "spice"
    listen_type = "address"
    autoport = true
  }
}

# Output Server IP
output "ip" {
  depends_on = [libvirt_domain.debian12]
  value = "${libvirt_domain.debian12.network_interface.0.addresses.0}"
}