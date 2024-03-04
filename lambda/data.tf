data "aws_iam_role" "lambda_basic_execution_role" {
  name = "BasicLambdaExecutionRole"
}

data "aws_vpc" "target" {
  count = local.vpc_access_enabled ? 1 : 0
  id = var.vpc_id
  state = "available"
}