variable "vsphere_server" {
  type = "string"
  description = "vServer Server address"
}

variable "vsphere_user" {
  type = "string"
  description = "vCenter user"
}

variable "vsphere_password" {
  type = "string"
  description = "vCenter password"
}

variable "vshpere_datastore" {
  type = "string"
  description = "vCenter datastore"
}

variable "vshpere_datacenter" {
  type = "string"
  description = "vCenter datacenter"
}

variable "vsphere_resource_pool" {
  type = "string"
  description = "vSphere resource pool"
}

variable "vsphere_network" {
  type = "string"
  description = "vSphere network"
}

variable "vsphere_template" {
  type = "string"
  description = "The vSphere template for vm"
}

variable "upsteam_dns" {
  type = "string"
  description = "The upstream dns"
}

variable "dhcp_range" {
  type = "string"
  description = "The dhcp range"
}

variable "provisioner_ip" {
  type = "string"
  description = "The provisioner ip"
}

variable "hostname" {
  type = "string"
  description = "The vm hostname"
}

variable "provisioner_node_name" {
  type = "string"
  description = "The vm DNS name"
}

variable "subnet_gateway" {
  type = "string"
  description = "The default gateway"
}

variable "static_network_dev" {
  type = "string"
  description = "The network of the static network"
}

variable "ssh_key_location" {
  type = "string"
  description  = "The ssh key location"
}

variable "coreos_version" {
  type = "string"
  description = "The coreos version to deploy"
}

variable "num_cpus" {
  type = "string"
  description = "The number of cpu for vm"
}

variable "memory_size_mb" {
  type = "string"
  description = "The memory size in MB"
}

variable "disk_size_gb" {
  type = "string"
  description = "The disk size in GB"
}

variable "cloud_init_filename" {
  type = "string"
  default = "cloud-config.cfg"
  description  = "The filename of generated cloudinit file"
}

variable matchbox_ca_file {
  type = "string"
  description = "matchbox ca key"
  default = "asserts/ca.crt"
}

variable matchbox_server_cert_file {
  type = "string"
  description = "matchbox server cert"
  default = "asserts/server.crt"
}

variable matchbox_server_cert_key {
  type = "string"
  description = "matchbox server key"
  default = "asserts/server.key"
}
