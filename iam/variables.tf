variable "lambda_exec_role_name" {
  type    = string
  default = "BasicLambdaExecutionRole"
}

variable "lambda_integrations" {
  type    = list(string)
  default = ["dynamodb", "sqs"]
}

variable "tags" {
  type    = map(string)
  default = {}
}