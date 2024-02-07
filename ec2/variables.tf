variable "vpc_id" {
  type = string
}

variable "instance_number" {
  type    = number
  default = 1
}

variable "enable_ssh" {
  type    = bool
  default = true
}

variable "ebs_delete_on_termination" {
  type    = bool
  default = true
}

variable "ebs_volume_size" {
  type    = number
  default = 10
}

variable "ebs_volume_type" {
  type    = string
  default = "gp3"
}

variable "shutdown_behavior" {
  type    = string
  default = "terminate"
}

variable "termination_protection" {
  type    = bool
  default = false
}

variable "stop_protection" {
  type    = bool
  default = false
}

variable "user_data" {
  type    = string
  default = ""
}

variable "tags" {
  type    = map(string)
  default = {}
}
