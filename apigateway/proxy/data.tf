data "aws_lambda_function" "backend" {
  count = var.integration_type == "AWS_PROXY" ? 1 : 0
  function_name = var.lambda_function_name
}

data "aws_lambda_alias" "backend" {
  count         = var.integration_type == "AWS_PROXY" && var.function_alias != "" ? 1 : 0
  function_name = var.lambda_function_name
  name          = var.function_alias
}

locals {
  target_id = var.integration_type != "AWS_PROXY" ? "" : var.function_alias == "" ? data.aws_lambda_function.backend[0].invoke_arn : "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${data.aws_lambda_alias.backend[0].arn}/invocations"
}