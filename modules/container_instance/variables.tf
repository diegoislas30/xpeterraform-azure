variable "container_group_name" {
  description = "The name of the Container Group"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group in which to create the Container Group"
  type        = string
}

variable "location" {
  description = "The Azure location where the Container Group should be created"
  type        = string
}

variable "os_type" {
  description = "The OS type for the containers. Possible values are Linux and Windows"
  type        = string
  default     = "Linux"
}

variable "dns_name_label" {
  description = "The DNS label/name for the container group's IP"
  type        = string
  default     = null
}

variable "ip_address_type" {
  description = "Specifies the IP address type. Possible values are Public, Private and None"
  type        = string
  default     = "Public"
}

variable "restart_policy" {
  description = "Restart policy for the container group. Possible values are Always, Never, OnFailure"
  type        = string
  default     = "Always"
}

variable "containers" {
  description = "List of containers to create in the container group"
  type = list(object({
    name   = string
    image  = string
    cpu    = number
    memory = number
    ports = optional(list(object({
      port     = number
      protocol = optional(string)
    })))
    environment_variables        = optional(map(string))
    secure_environment_variables = optional(map(string))
    volumes = optional(list(object({
      name                 = string
      mount_path           = string
      read_only            = optional(bool)
      share_name           = optional(string)
      storage_account_name = optional(string)
      storage_account_key  = optional(string)
    })))
  }))
}

variable "identity_type" {
  description = "The type of Managed Identity which should be assigned to the Container Group. Possible values are SystemAssigned, UserAssigned"
  type        = string
  default     = null
}

variable "identity_ids" {
  description = "A list of User Managed Identity IDs which should be assigned to the Container Group"
  type        = list(string)
  default     = []
}

variable "image_registry_credentials" {
  description = "A list of image registry credentials for pulling private container images"
  type = list(object({
    server   = string
    username = string
    password = string
  }))
  default = []
}

variable "dns_servers" {
  description = "A list of DNS servers for the container group"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "A mapping of tags to assign to the resources"
  type = object({
    UDN      = string
    OWNER    = string
    xpeowner = string
    proyecto = string
    ambiente = string
  })
}
