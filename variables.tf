variable user {default = ""}
variable password { default = ""}
variable domain { default = ""}
variable endpoint { default = "https://compute.aucom-east-1.oraclecloud.com/"}

variable "public_ssh_key" {
  default = "./keys/id_rsa.pub"
}
variable "private_ssh_key" {
  default = "./keys/id_rsa"
}
variable "node_count" {
  default = "3"
 }
variable "vnic" {
  type = "list"
  default =  [ "kubevm-vnic-set1", "kubevm-vnic-set2", "kubevm-vnic-set3" ]
}

variable "ipaddr" {
  type = "list"
  default =  [ "192.168.1.100", "192.168.1.101", "192.168.1.102" ]
}
variable "bootvol" {
  type = "list"
  default =  [ "boot-volume-kube1", "boot-volume-kube2", "boot-volume-kube3" ]
}
variable "kubevmip" {
  type = "list"
  default =  [ "kubevm-ip-address1", "kubevm-ip-address2", "kubevm-ip-address3" ]
}
variable "kubevmipnet" {
  type = "list"
  default =  [ "kubevm-ip-network1", "kubevm-ip-network2", "kubevm-ip-network3" ]
}
variable "kubevminst" {
  type = "list"
  default =  [ "kubevm1", "kubevm2", "kubevm3" ]
}
