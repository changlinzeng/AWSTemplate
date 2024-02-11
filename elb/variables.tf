variable "lb_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "internal" {
  type    = bool
  default = false
}

variable "lb_type" {
  type    = string
  default = "application"
  validation {
    condition = contains(["application", "network", "gateway"], var.lb_type)
    error_message = "Load balancer type must be application, network or gateway"
  }
}

variable "security_groups" {
  type    = list(string)
  default = []
}

variable "subnets" {
  type = list(string)
  default = []
}

variable "cross_zone_load_balancing" {
  type    = bool
  default = true
}

variable "access_logs" {
  type = object({
    enabled   = bool
    bucket_id = string
    prefix    = string
  })
  default = {
    enabled   = false
    bucket_id = ""
    prefix    = ""
  }
}

variable "listeners" {
  type = list(object({
    protocol    = string
    port        = number
    action_type = string
  }))
}

variable "target_group" {
  type = object({
    name        = string
    port        = number
    protocol    = string
    target_type = string
  })
}

variable "tags" {
  type    = map(string)
  default = {}
}