data "aws_lambda_function" "backend" {
  function_name = var.lambda_function_name
}

data "aws_lambda_alias" "backend" {
  count         = var.function_alias != "" ? 1 : 0
  function_name = var.lambda_function_name
  name          = var.function_alias
}

locals {
  target_id = var.function_alias == "" ? data.aws_lambda_function.backend.invoke_arn : "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${data.aws_lambda_alias.backend[0].arn}/invocations"
}