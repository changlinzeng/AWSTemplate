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

resource "aws_api_gateway_integration" "aws_proxy_integration" {
  count                   = var.integration_type == "AWS_PROXY" ? 1 : 0
  rest_api_id             = aws_api_gateway_rest_api.this.id
  http_method             = aws_api_gateway_method.this_method.http_method
  resource_id             = aws_api_gateway_rest_api.this.root_resource_id
  integration_http_method = "POST"
  uri                     = local.target_id
  type                    = "AWS_PROXY"
  cache_key_parameters    = []
  request_parameters      = {}
  request_templates       = {}
  # the following is required when type is MOCK
  #  request_templates = {
  #    "application/json" = jsonencode(
  #      {
  #        statusCode = 200
  #      }
  #    )
  #  }
}

resource "aws_api_gateway_integration" "http_proxy_integration" {
  count                   = var.integration_type == "HTTP_PROXY" ? 1 : 0
  rest_api_id             = aws_api_gateway_rest_api.this.id
  http_method             = aws_api_gateway_method.this_method.http_method
  resource_id             = aws_api_gateway_rest_api.this.root_resource_id
  integration_http_method = "ANY"
  #  uri                     = var.uri
  uri                  = "http://vpclink-${var.api_name}.${var.aws_region}.amazonaws.com"
  type                 = "HTTP_PROXY"
  connection_type      = "VPC_LINK"
  connection_id        = aws_api_gateway_vpc_link.this_vpc_link[0].id
  cache_key_parameters = []
  request_parameters   = {}
  request_templates    = {}
}

resource "aws_api_gateway_vpc_link" "this_vpc_link" {
  count       = var.integration_type == "HTTP_PROXY" ? 1 : 0
  name        = "${var.api_name}-vpc-link"
  target_arns = var.target_arns
  tags = merge(var.tags, {
    Usage = "ApiGateway"
    Name  = "${var.api_name}-vpc-link"
  })
}

# add resource based policy to Lambda to grant access to api gateway
resource "aws_lambda_permission" "invoke_lambda" {
  count         = var.integration_type == "AWS_PROXY" ? 1 : 0
  statement_id  = "${data.aws_lambda_function.backend[0].function_name}-ApiGatewayInvokeLambda"
  action        = "lambda:InvokeFunction"
  function_name = data.aws_lambda_function.backend[0].function_name
  principal     = "apigateway.amazonaws.com"
}

# access tp lambda function alias
resource "aws_lambda_permission" "invoke_lambda_alias" {
  count         = var.function_alias != "" && var.function_alias != null && var.integration_type == "AWS_PROXY" ? 1 : 0
  statement_id  = "${var.function_alias}-ApiGatewayInvokeLambdaAlias"
  action        = "lambda:InvokeFunction"
  function_name = data.aws_lambda_function.backend[0].function_name
  qualifier     = var.function_alias
  principal     = "apigateway.amazonaws.com"
}

resource "aws_api_gateway_deployment" "this_deployment" {
  count       = var.stage.create ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.this.id
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_rest_api.this.id,
      aws_api_gateway_method.this_method.id,
      local.this_integration
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
  variables             = var.stage.variables
  tags = merge(var.tags, {
    Usage = "ApiGateway"
  })
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
      condition     = var.stage.logging_level == "OFF" || var.enable_cloudwatch
      error_message = "CloudWatch must be enabled before setting logging level"
    }
  }
}

# CloudWatch integration
resource "aws_api_gateway_account" "this" {
  count               = var.enable_cloudwatch ? 1 : 0
  cloudwatch_role_arn = data.aws_iam_role.cloudwatch_role.arn
}

locals {
  this_integration = var.integration_type == "AWS_PROXY" ? aws_api_gateway_integration.aws_proxy_integration[0] : aws_api_gateway_integration.http_proxy_integration[0]
}