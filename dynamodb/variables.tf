variable "name" {
  type = string
}

variable "partition_key" {
  type = string
}

variable "sort_key" {
  type = string
}

variable "attributes" {
  type = list(object({
    name = string
    type = string
  }))
  default = []
}

variable "table_class" {
  type    = string
  default = "STANDARD"
  validation {
    condition     = contains(["STANDARD", "STANDARD_INFREQUENT_ACCESS"], var.table_class)
    error_message = "table_class must be STANDARD or STANDARD_INFREQUENT_ACCESS"
  }
}

variable "billing_mode" {
  type    = string
  default = "PROVISIONED"
  validation {
    condition     = contains(["PROVISIONED", "PAY_PER_REQUEST"], var.billing_mode)
    error_message = "billing_mode must be PROVISIONED or PAY_PER_REQUEST"
  }
}

variable "deletion_protection" {
  type    = bool
  default = true
}

variable "global_secondary_index" {
  type = object({
    hash_key        = string
    name            = string
    projection_type = string
  })
  default = {
    hash_key        = ""
    name            = ""
    projection_type = ""
  }
}

variable "local_secondary_index" {
  type = object({
    name            = string
    projection_type = string
    range_key       = string
  })
  default = {
    name            = ""
    projection_type = ""
    range_key       = ""
  }
}

variable "read_capacity" {
  type    = number
  default = 1
}

variable "write_capacity" {
  type    = number
  default = 1
}

variable "ttl" {
  type = object({
    enabled        = bool
    attribute_name = string
  })
  default = {
    enabled        = false
    attribute_name = ""
  }
}

variable "tags" {
  type    = map(string)
  default = {}
}