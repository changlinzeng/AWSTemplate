################################################################################
# CloudWatch IAM definitions
################################################################################
resource "aws_iam_role" "cloudwatch_role" {
  name               = "CloudWatchRole"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "cloudwatch" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents",
      "logs:GetLogEvents",
      "logs:FilterLogEvents",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "cloudwatch" {
  name   = "default"
  role   = aws_iam_role.cloudwatch_role.id
  policy = data.aws_iam_policy_document.cloudwatch.json
}

################################################################################
# Lambda IAM definitions
################################################################################
resource "aws_iam_role" "basic_lambda_exec_role" {
  name               = var.lambda_exec_role_name
  assume_role_policy = data.aws_iam_policy_document.exec_role_policy.json
  tags               = var.tags
}

data "aws_iam_policy_document" "exec_role_policy" {
  version = "2012-10-17"
  statement {
    sid    = "LambdaExecutionRole"
    effect = "Allow"
    principals {
      identifiers = ["lambda.amazonaws.com"]
      type        = "Service"
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.basic_lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# invoke function
resource "aws_iam_role_policy_attachment" "invoke_function" {
  count      = length(var.lambda_integrations) != 0 ? 1 : 0
  role       = aws_iam_role.basic_lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaRole"
}

# dynamodb
resource "aws_iam_role_policy_attachment" "dynamodb_read" {
  count      = contains(var.lambda_integrations, "dynamodb") ? 1 : 0
  role       = aws_iam_role.basic_lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaDynamoDBExecutionRole"
}

# sqs
resource "aws_iam_role_policy_attachment" "sqs_read" {
  count      = contains(var.lambda_integrations, "sqs") ? 1 : 0
  role       = aws_iam_role.basic_lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole"
}

# VPC access
resource "aws_iam_role_policy_attachment" "vpc_access" {
  count      = var.enabled_vpc_access ? 1 : 0
  role       = aws_iam_role.basic_lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}