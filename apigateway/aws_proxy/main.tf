resource "aws_api_gateway_rest_api" "this" {
  name = var.api_name
  endpoint_configuration {
    types = [var.endpoint_type]
  }
  tags = merge(var.tags, {
    Usage = "ApiGateway"
  })
}

resource "aws_api_gateway_method" "this_method" {
  rest_api_id          = aws_api_gateway_rest_api.this.id
  authorization        = var.authorization
  authorizer_id        = var.authorizer_id != "" ? var.authorizer_id : null
  authorization_scopes = var.authorization_scopes
  http_method          = var.method
  resource_id          = aws_api_gateway_rest_api.this.root_resource_id
}

resource "aws_api_gateway_integration" "this_integration" {
  rest_api_id             = aws_api_gateway_rest_api.this.id
  http_method             = aws_api_gateway_method.this_method.http_method
  resource_id             = aws_api_gateway_rest_api.this.root_resource_id
  integration_http_method = "POST"
  uri                     = local.target_id
  type                    = "AWS_PROXY"
  # the following is required when type is MOCK
  #  request_templates = {
  #    "application/json" = jsonencode(
  #      {
  #        statusCode = 200
  #      }
  #    )
  #  }
}

resource "aws_lambda_permission" "allow_invoke" {
  statement_id  = "ApiGatewayInvokeLambda"
  action        = "lambda:InvokeFunction"
  function_name = data.aws_lambda_function.backend.function_name
  principal     = "apigateway.amazonaws.com"
}

resource "aws_api_gateway_deployment" "this_deployment" {
  count       = var.stage.create != "" ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.this.id
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_method.this_method.id,
      aws_api_gateway_integration.this_integration.id
    ]))
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "this_stage" {
  count                 = var.stage.create ? 1 : 0
  deployment_id         = aws_api_gateway_deployment.this_deployment[0].id
  rest_api_id           = aws_api_gateway_rest_api.this.id
  stage_name            = var.stage.name
  cache_cluster_enabled = var.stage.enable_cache
  cache_cluster_size    = var.stage.enable_cache ? var.stage.cache_size : null
}

resource "aws_api_gateway_method_settings" "all" {
  count       = var.stage.create ? 1 : 0
  method_path = "*/*"
  rest_api_id = aws_api_gateway_rest_api.this.id
  stage_name  = aws_api_gateway_stage.this_stage[0].stage_name
  settings {
    metrics_enabled      = var.stage.enable_metrics
    logging_level        = var.stage.logging_level
    caching_enabled      = var.stage.enable_cache
    cache_ttl_in_seconds = var.stage.enable_cache ? var.stage.cache_ttl_seconds : null
    cache_data_encrypted = var.stage.enable_cache ? var.stage.cache_data_encrypted : null
  }
  lifecycle {
    precondition {
      condition = var.stage.logging_level == "OFF" || var.enable_cloudwatch
      error_message = "CloudWatch must be enabled before setting logging level"
    }
  }
}

# CloudWatch integration
resource "aws_api_gateway_account" "this" {
  count               = var.enable_cloudwatch ? 1 : 0
  cloudwatch_role_arn = aws_iam_role.cloudwatch[0].arn
}

resource "aws_iam_role" "cloudwatch" {
  count              = var.enable_cloudwatch ? 1 : 0
  name               = "ApiGatewayCloudwatchGlobal"
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
  count  = var.enable_cloudwatch ? 1 : 0
  name   = "default"
  role   = aws_iam_role.cloudwatch[0].id
  policy = data.aws_iam_policy_document.cloudwatch.json
}