# variables.tf (en el root)
variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "admin_password" {
  description = "Administrator password for the VM (provided via TF_VAR_admin_password from GitHub secret VM_PASSWORD)"
  type        = string
  sensitive   = true
  # No default - debe venir del secreto VM_PASSWORD en GitHub Actions
}

variable "admin_username" {
  type    = string
  default = "guestfemsa"
}
