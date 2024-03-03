variable "api_name" {
  type = string
}

variable "endpoint_type" {
  type    = string
  default = "REGIONAL"
  validation {
    condition     = contains(["EDGE", "REGIONAL", "PRIVATE"], var.endpoint_type)
    error_message = "Endpoint types must be EDGE, REGIONAL or PRIVATE"
  }
}

variable "method" {
  type    = string
  default = "ANY"
}

variable "integration_type" {
  type    = string
  default = "AWS_PROXY"
  validation {
    condition     = contains(["AWS_PROXY", "HTTP_PROXY"], var.integration_type)
    error_message = "Integration type must be AWS_PROXY, HTTP_PROXY, AWS or HTTP"
  }
}

variable "target_arns" {
  description = "Arns of the target NLB when integration type is HTTP_PROXY"
  type        = list(string)
  default     = []
}

variable "authorization" {
  type    = string
  default = "NONE"
  validation {
    condition     = contains(["NONE", "AWS_IAM", "CUSTOM", "COGNITO_USER_POOLS"], var.authorization)
    error_message = "Authorization method must be NONE, AWS_IAM, CUSTOM or COGNITO_USER_POOLS"
  }
}

variable "authorizer_id" {
  type    = string
  default = ""
}

variable "authorization_scopes" {
  type    = list(string)
  default = []
}

variable "lambda_function_name" {
  type    = string
  default = ""
}

variable "function_alias" {
  type    = string
  default = ""
}

variable "stage" {
  type = object({
    create               = bool
    name                 = string
    enable_cache         = bool
    cache_size           = number
    cache_ttl_seconds    = number
    cache_data_encrypted = bool
    enable_metrics       = bool
    logging_level        = string
    variables            = map(string)
  })
  default = {
    create               = false
    name                 = ""
    enable_cache         = false
    cache_size           = 0.5
    cache_ttl_seconds    = 300
    cache_data_encrypted = false
    enable_metrics       = false
    logging_level        = "INFO"
    variables            = {}
  }
  validation {
    condition     = !var.stage.create || var.stage.create && contains([0.5, 1.6, 6.1, 13.5, 28.4, 58.2, 118, 237], var.stage.cache_size)
    error_message = "Invalid cache size"
  }
  validation {
    condition     = contains(["OFF", "INFO", "ERROR"], var.stage.logging_level)
    error_message = "Logging level must be OFF, INFO or ERROR"
  }
}

variable "aws_region" {
  type = string
}

variable "enable_cloudwatch" {
  type    = bool
  default = false
}

variable "tags" {
  type    = map(string)
  default = {}
}