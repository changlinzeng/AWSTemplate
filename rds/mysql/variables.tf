variable "region" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "db_name" {
  type = string
}

variable "engine" {
  # available values https://docs.aws.amazon.com/AmazonRDS/latest/APIReference/API_CreateDBInstance.html
  type = string
}

variable "engine_version" {
  type = string
}

variable "instance_class" {
  type = string
  default = "db.t3.micro"
}

variable "storage_type" {
  type = string
  validation {
    condition     = contains(["standard", "gp2", "gp3", "io1"], var.storage_type)
    error_message = "storage type must be standard, gp2, gp3 or io1"
  }
  default = "gp2"
}

variable "iops" {
  type = number
  default = 0
}

variable "allocated_storage" {
  type = number
  default = 20
}

variable "max_allocated_storage" {
  # define max_allocated_storage higher than allocated_storage to enable storage autoscaling
  type = number
  default = null
}

variable "storage_encrypted" {
  type    = bool
  default = false
}

variable "kms_key_arn" {
  type = string
  default = ""
}

variable "license_model" {
  # values ofr different engine
  # MariaDB and MySQL: general-public-license
  # PostgreSQL: postgresql-license
  # MSSQL Server: license-included
  # Oracle: bring-your-own-license | license-included
  type    = string
  default = null
}

variable "master_username" {
  type = string
}

variable "master_password" {
  type = string
}

variable "port" {
  type = number
}

variable "character_set_name" {
  type    = string
  default = null
}

variable "time_zone" {
  type    = string
  default = null
}

variable "security_groups_ids" {
  type    = list(string)
  default = []
}

variable "db_subnet_group_name" {
  type    = string
  default = null
}

variable "parameter_group_name" {
  type    = string
  default = null
}

variable "option_group_name" {
  type    = string
  default = null
}

variable "availability_zone" {
  type    = string
  default = null
}

variable "multi_az" {
  type    = bool
  default = false
}

variable "ca_cert_identifier" {
  type    = string
  default = null
}

variable "maintenance_window" {
  type    = string
  default = null
}

variable "deletion_protection" {
  type    = bool
  default = false
}

variable "delete_automated_backups" {
  type    = bool
  default = true
}

variable "tags" {
  type    = map(string)
  default = {}
}