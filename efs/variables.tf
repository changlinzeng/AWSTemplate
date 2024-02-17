variable "name" {
  type = string
}

variable "availability_zone" {
  type    = string
  default = null
}

variable "encrypted" {
  type    = bool
  default = false
}

variable "kms_key_id" {
  type    = string
  default = ""
}

variable "lifecycle_policy" {
  type = object({
    transition_to_ia                    = string
    transition_to_primary_storage_class = string
    transition_to_archive               = string
  })
  default = {
    transition_to_ia                    = "AFTER_30_DAYS"
    transition_to_primary_storage_class = "AFTER_1_ACCESS"
    transition_to_archive               = "AFTER_90_DAYS"
  }
  validation {
    condition     = contains(["AFTER_1_DAY", "AFTER_7_DAYS", "AFTER_14_DAYS", "AFTER_30_DAYS", "AFTER_60_DAYS", "AFTER_90_DAYS"], var.lifecycle_policy.transition_to_ia)
    error_message = "Invalid lifecycle periods"
  }
  validation {
    condition     = contains(["AFTER_1_DAY", "AFTER_7_DAYS", "AFTER_14_DAYS", "AFTER_30_DAYS", "AFTER_60_DAYS", "AFTER_90_DAYS"], var.lifecycle_policy.transition_to_archive)
    error_message = "Invalid lifecycle periods"
  }
}

variable "performance_mode" {
  type    = string
  default = "generalPurpose"
  validation {
    condition     = contains(["generalPurpose", "maxIO"], var.performance_mode)
    error_message = "Performance mode must be generalPurpose or maxIO"
  }
}

variable "throughput_mode" {
  type    = string
  default = "bursting"
  validation {
    condition     = contains(["bursting", "provisioned", "elastic"], var.throughput_mode)
    error_message = "Throughput mode must be bursting, provisioned or elastic"
  }
}

variable "provisioned_throughput_in_mibps" {
  type    = number
  default = 0
}

variable "backup" {
  type    = bool
  default = true
}

variable "user" {
  type = object({
    uid            = number
    gid            = number
    secondary_gids = list(number)
  })
  default = {
    uid            = 0
    gid            = 0
    secondary_gids = []
  }
}

variable "owner" {
  type = object({
    owner_uid   = number
    owner_gid   = number
    permissions = string
  })
  default = {
    owner_uid   = 0
    owner_gid   = 0
    permissions = "750"
  }
}

variable "root_directory" {
  type    = string
  default = "/"
}

variable "vpc_id" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}