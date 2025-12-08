variable "acr_name" {
  description = "The name of the Container Registry. Must be globally unique"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group in which to create the Container Registry"
  type        = string
}

variable "location" {
  description = "The Azure location where the Container Registry should be created"
  type        = string
}

variable "sku" {
  description = "The SKU name of the container registry. Possible values are Basic, Standard and Premium"
  type        = string
  default     = "Standard"
  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.sku)
    error_message = "SKU must be one of: Basic, Standard, Premium"
  }
}

variable "admin_enabled" {
  description = "Specifies whether the admin user is enabled"
  type        = bool
  default     = false
}

variable "public_network_access_enabled" {
  description = "Whether public network access is allowed for the container registry"
  type        = bool
  default     = true
}

variable "network_rule_set" {
  description = "Network rule set configuration. Only available for Premium SKU"
  type = object({
    default_action              = string
    ip_rules                    = optional(list(string))
    virtual_network_subnet_ids  = optional(list(string))
  })
  default = null
}

variable "georeplications" {
  description = "A list of geo-replication configurations. Only available for Premium SKU"
  type = list(object({
    location                = string
    zone_redundancy_enabled = optional(bool)
  }))
  default = []
}

variable "identity_type" {
  description = "The type of Managed Identity. Possible values are SystemAssigned, UserAssigned, SystemAssigned, UserAssigned"
  type        = string
  default     = null
}

variable "identity_ids" {
  description = "A list of User Managed Identity IDs"
  type        = list(string)
  default     = []
}

variable "encryption" {
  description = "Encryption configuration using customer-managed keys. Only available for Premium SKU"
  type = object({
    key_vault_key_id   = string
    identity_client_id = string
  })
  default = null
}

variable "retention_policy_days" {
  description = "The number of days to retain an untagged manifest. Only available for Premium SKU"
  type        = number
  default     = null
}

variable "trust_policy_enabled" {
  description = "Whether content trust (Notary) is enabled. Only available for Premium SKU"
  type        = bool
  default     = false
}

variable "quarantine_policy_enabled" {
  description = "Whether quarantine policy is enabled. Only available for Premium SKU"
  type        = bool
  default     = false
}

variable "zone_redundancy_enabled" {
  description = "Whether zone redundancy is enabled. Only available for Premium SKU"
  type        = bool
  default     = false
}

variable "export_policy_enabled" {
  description = "Whether export policy is enabled"
  type        = bool
  default     = true
}

variable "anonymous_pull_enabled" {
  description = "Whether anonymous pull access is allowed"
  type        = bool
  default     = false
}

variable "data_endpoint_enabled" {
  description = "Whether to enable dedicated data endpoints"
  type        = bool
  default     = false
}

variable "network_rule_bypass_option" {
  description = "Whether to allow trusted Azure services to access. Possible values are AzureServices and None"
  type        = string
  default     = "AzureServices"
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
