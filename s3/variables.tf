variable "bucket_name" {
  type = string
}

variable "public_bucket" {
  type    = bool
  default = false
}

variable "enable_bucket_versioning" {
  type    = bool
  default = false
}

variable "tags" {
  type    = map(string)
  default = {}
}