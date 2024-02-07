variable "queue_name" {
  type    = string
  default = "template-queue"
}

variable "fifo" {
  type    = bool
  default = false
}

variable "create_dead_letter_queue" {
  type = bool
  default = false
}

variable "dead_letter_queue_name" {
  type    = string
  default = "template-dead-letter-queue"
}

variable "visibility_timeout_seconds" {
  type    = number
  default = 30
}

variable "tags" {
  type    = map(string)
  default = {}
}