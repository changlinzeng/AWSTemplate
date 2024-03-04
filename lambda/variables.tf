variable "function_name" {
  type = string
}

variable "filename" {
  type    = string
  default = ""
}

variable "function_type" {
  type    = string
  default = "file"
  validation {
    condition     = contains(["file", "image", "s3"], var.function_type)
    error_message = "Function type must be file, image or s3"
  }
}

variable "image_uri" {
  type    = string
  default = ""
}

variable "s3_bucket_id" {
  description = "The id of the S3 bucket that contains the package"
  type        = string
  default     = ""
}

variable "s3_object_id" {
  description = "The id of the lambda package as S3 object"
  type        = string
  default     = ""
}

variable "runtime" {
  type = string
}

variable "handler" {
  type = string
}

variable "architectures" {
  type    = list(string)
  default = ["x86_64"]
  validation {
    condition     = alltrue([for arch in var.architectures : contains(["x86_64", "arm64"], arch)])
    error_message = "Runtime must be x86_64 or arm64"
  }
}

variable "vpc_id" {
  type = string
  default = ""
}

variable "vpc_config_subnets" {
  type    = list(string)
  default = []
}

variable "function_url" {
  type = object({
    authorization_type = string
    invoke_mode        = string
  })
  default = {
    authorization_type = "NONE"
    invoke_mode        = "BUFFERED"
  }
  validation {
    condition     = contains(["AWS_IAM", "NONE"], var.function_url.authorization_type)
    error_message = "Authorization type must be AWS_IAM or NONE"
  }
  validation {
    condition     = contains(["BUFFERED", "RESPONSE_STREAM"], var.function_url.invoke_mode)
    error_message = "Invoke mode must be BUFFERED or RESPONSE_STREAM"
  }
}

variable "integrations" {
  description = "Services the lambda function will integrate so the permissions will be added accordingly"
  type        = list(string)
  default     = []
}

variable "sqs_event_source" {
  type = object({
    enabled                    = bool
    arn                        = string
    batch_size                 = number
    batch_window               = number
    report_batch_item_failures = bool
  })
  default = {
    enabled                    = true
    arn                        = ""
    batch_size                 = 10
    batch_window               = 0
    report_batch_item_failures = true
  }
}

variable "publish" {
  type    = bool
  default = true
}

variable "alias" {
  type    = string
  default = ""
}

variable "alias_description" {
  type    = string
  default = ""
}

variable "tags" {
  type    = map(string)
  default = {}
}

locals {
  function_type_file  = var.function_type == "file" && var.filename != ""
  function_type_image = var.function_type == "image" && var.image_uri != ""
  function_type_s3    = var.function_type == "s3" && var.s3_bucket_id != "" && var.s3_object_id != ""
}