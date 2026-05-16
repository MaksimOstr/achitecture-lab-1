variable "project_name" {
  type        = string
  description = "Prefix for libvirt resources."
  default     = "architecture-lab4"
}

variable "libvirt_uri" {
  type        = string
  description = "libvirt connection URI."
  default     = "qemu:///system"
}

variable "ubuntu_cloud_image_path" {
  type        = string
  description = "Local path to the official Ubuntu cloud image."
}

variable "ssh_public_key_path" {
  type        = string
  description = "Public SSH key that cloud-init installs for the ansible user."
  default     = "~/.ssh/id_ed25519.pub"
}

variable "ssh_private_key_path" {
  type        = string
  description = "Private SSH key path written into the generated Ansible inventory."
  default     = "~/.ssh/id_ed25519"
}

variable "network_cidr" {
  type        = string
  description = "Private libvirt network CIDR for the two VMs."
  default     = "192.168.124.0/24"
}

variable "worker_memory_mb" {
  type        = number
  description = "Worker VM memory in MiB."
  default     = 2048
}

variable "worker_vcpu" {
  type        = number
  description = "Worker VM vCPU count."
  default     = 2
}

variable "worker_disk_bytes" {
  type        = number
  description = "Worker VM disk size in bytes."
  default     = 21474836480
}

variable "db_memory_mb" {
  type        = number
  description = "Database VM memory in MiB."
  default     = 2048
}

variable "db_vcpu" {
  type        = number
  description = "Database VM vCPU count."
  default     = 1
}

variable "db_disk_bytes" {
  type        = number
  description = "Database VM disk size in bytes."
  default     = 21474836480
}
