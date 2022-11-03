# Defining VM Volume
resource "libvirt_volume" "centos7-qcow2" {
  name = "centos7.qcow2"
  pool = "libvirt" # List storage pools using virsh pool-list
  #source = "https://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud.qcow2"
  source = "/var/lib/libvirt/boot/CentOS-7-x86_64-GenericCloud.qcow2"
  format = "qcow2"
}

# Defining VM Volume
resource "libvirt_volume" "kubeworker-qcow2" {
  name = "kuberworker.qcow2"
  pool = "k8s" # List storage pools using virsh pool-list
  #source = "https://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud.qcow2"
  source = "/var/lib/libvirt/boot/CentOS-7-x86_64-GenericCloud.qcow2"
  format = "qcow2"
}


# get user data info
data "template_file" "user_data" {
  template = "${file("${path.module}/cloud_init.cfg")}"
}

# Use CloudInit to add the instance
resource "libvirt_cloudinit_disk" "commoninit" {
  name = "commoninit.iso"
  pool = "libvirt" # List storage pools using virsh pool-list
  user_data      = "${data.template_file.user_data.rendered}"
}


# Cluster storage pool

resource "libvirt_pool" "kubernetes_pool" {
  name = "kubernetes_pool"
  type = "dir"
  path = "${var.cluster_volume_pool_dir}"
}

# Define KVM domain to create
resource "libvirt_domain" "centos7" {
  name   = "centos7"
  memory = "1024"
  vcpu   = 1

  network_interface {
    network_name = "default" # List networks with virsh net-list
  }

  disk {
    volume_id = "${libvirt_volume.centos7-qcow2.id}"
  }

  cloudinit = "${libvirt_cloudinit_disk.commoninit.id}"

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

# Define KVM domain to create
resource "libvirt_domain" "kubeworker" {
  name   = "kubeworker"
  memory = "1024"
  vcpu   = 1

  network_interface {
    network_name = "default" # List networks with virsh net-list
  }

  disk {
    volume_id = "${libvirt_volume.kubeworker-qcow2.id}"
  }

  cloudinit = "${libvirt_cloudinit_disk.commoninit.id}"

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
  value = "${libvirt_domain.centos7.network_interface.0.addresses.0}"
}

# Output Server IP
output "ip-kubeworker" {
  value = "${libvirt_domain.kubeworker.network_interface.0.addresses.0}"
}
