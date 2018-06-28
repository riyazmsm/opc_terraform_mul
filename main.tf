provider "opc" {
  user            = "${var.user}"
  password        = "${var.password}"
  identity_domain = "${var.domain}"
  endpoint        = "${var.endpoint}"
}

resource "opc_compute_ssh_key" "kubevm-ssh-key" {
  name    = "kubevm-ssh-key"
  key     = "${file(var.public_ssh_key)}"
  enabled = true
}

resource "opc_compute_ip_address_reservation" "kubevm-ip-address" {
  count   = "${var.node_count}"
  name            = "${element(var.kubevmip, count.index)}"
  ip_address_pool = "public-ippool"
}

resource "opc_compute_ip_network" "kubevm-ip-network" {
  count   = "${var.node_count}"
  name              = "${element(var.kubevmipnet, count.index)}"
  ip_address_prefix = "192.168.1.0/24"
}

resource "opc_compute_acl" "kubevm-acl" {
  name = "kubevm-acl"
}

resource "opc_compute_security_rule" "ssh" {
  name               = "kubevm-Allow-ssh-ingress"
  flow_direction     = "ingress"
  acl                = "${opc_compute_acl.kubevm-acl.name}"
  security_protocols = ["${opc_compute_security_protocol.kube-ssh.name}"]
}

resource "opc_compute_security_rule" "egress" {
  name               = "kubevm-Allow-all-egress"
  flow_direction     = "egress"
  acl                = "${opc_compute_acl.kubevm-acl.name}"
  security_protocols = ["${opc_compute_security_protocol.kube-all.name}"]
}

resource "opc_compute_security_protocol" "kube-all" {
  name        = "kube-all"
  ip_protocol = "all"
}

resource "opc_compute_security_protocol" "kube-ssh" {
 name        = "kube-ssh"
  dst_ports   = ["22"]
  ip_protocol = "tcp"
}

resource "opc_compute_vnic_set" "kubevm-vnic-set" {
  count   = "${var.node_count}"
  name    = "${element(var.vnic, count.index)}"
  applied_acls = ["${opc_compute_acl.kubevm-acl.name}"]
}
resource "opc_compute_storage_volume" "boot-volume-kube" {
  count   = "${var.node_count}"
  size = "100"
  name = "${element(var.bootvol, count.index)}"
  bootable = true
  image_list = "/oracle/public/OL_7.2_UEKR4_x86_64"
  image_list_entry = 1
}

resource "opc_compute_instance" "kubevm-instance" {
  count   = "${var.node_count}"
  name       = "${element(var.kubevminst, count.index)}"
  hostname   = "${element(var.kubevminst, count.index)}"
  label      = "${element(var.kubevminst, count.index)}"
  shape      = "oc4"

 storage {
    index = 1
    volume = "${element(var.bootvol, count.index)}"
  }
  boot_order = [ 1 ]

  networking_info {
    index              = 0
    ip_network         = "${element(var.kubevmipnet, count.index)}"
    ip_address         = "${element(var.ipaddr, count.index)}"
    is_default_gateway = true
    vnic_sets          = ["${element(var.vnic, count.index)}"]
    nat                = ["${element(var.kubevmip, count.index)}"]
  }

  ssh_keys = ["${opc_compute_ssh_key.kubevm-ssh-key.name}"]
depends_on = ["opc_compute_storage_volume.boot-volume-kube"]
}

output "public_ip_address" {
  value = "${opc_compute_ip_address_reservation.kubevm-ip-address.*.ip_address}"
}
locals {
  opc_instance_addrs = "${opc_compute_ip_address_reservation.kubevm-ip-address.*.ip_address}"
}

resource "null_resource" "vm" {
  count   = "${var.node_count}"
connection {
    type        = "ssh"
    host        = "${local.opc_instance_addrs[count.index]}"
    user        = "opc"
    private_key = "${file(var.private_ssh_key)}"
    timeout     = "3m"
  }
provisioner "file" {
  source      = "public-yum-ol7.repo"
  destination = "/home/opc/public-yum-ol7.repo"
}  
provisioner "remote-exec" {
    inline = [
      "sudo yum -y install telnet","sudo mv /home/opc/public-yum-ol7.repo /etc/yum.repos.d/","sudo yum -y install docker-engine",
      "sudo yum -y install curl","sudo curl -L https://github.com/docker/compose/releases/download/1.21.2/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose","sudo chmod +x /usr/local/bin/docker-compose","sudo yum -y install git","sudo systemctl start docker",
    ]
  }
depends_on = ["opc_compute_instance.kubevm-instance"]
}

