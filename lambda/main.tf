resource "aws_lambda_function" "this" {
  function_name    = var.function_name
  runtime          = var.runtime
  handler          = var.handler
  architectures    = var.architectures
  role             = data.aws_iam_role.lambda_basic_execution_role.arn
  filename         = local.function_type_file ? var.filename : null
  source_code_hash = local.function_type_file ? filebase64sha256(var.filename) : (local.function_type_s3 ? filebase64sha256(var.s3_object_id) : null)
  s3_bucket        = local.function_type_s3 ? var.s3_bucket_id : null
  s3_key           = local.function_type_s3 ? var.s3_object_id : null
  image_uri        = local.function_type_image ? var.image_uri : null
  publish          = var.publish
  vpc_config {
    security_group_ids = var.vpc_config_security_groups
    subnet_ids         = var.vpc_config_subnets
  }
  tags = merge(var.tags,
    {
      Name = var.function_name
    }
  )
  lifecycle {
    precondition {
      condition     = local.function_type_file || local.function_type_image || local.function_type_s3
      error_message = "Function type must be set"
    }
  }
}

resource "aws_lambda_function_url" "this_url" {
  function_name      = aws_lambda_function.this.function_name
  authorization_type = var.function_url.authorization_type
  invoke_mode        = var.function_url.invoke_mode
}

resource "aws_lambda_event_source_mapping" "sqs_event" {
  count                              = contains(var.integrations, "sqs") ? 1 : 0
  function_name                      = aws_lambda_function.this.function_name
  enabled                            = var.sqs_event_source.enabled
  event_source_arn                   = var.sqs_event_source.arn
  batch_size                         = var.sqs_event_source.batch_size
  maximum_batching_window_in_seconds = var.sqs_event_source.batch_window
  function_response_types            = var.sqs_event_source.report_batch_item_failures ? ["ReportBatchItemFailures"] : []
}

resource "null_resource" "function_alias" {
  count = var.publish && var.alias != "" && var.alias != null ? 1 : 0
  triggers = {
    lambda_version = aws_lambda_function.this.version
  }
  provisioner "local-exec" {
    command = <<EOT
      aws lambda create-alias --function-name "${var.function_name}" --name "${var.alias}" --function-version "${aws_lambda_function.this.version}" --description "${var.alias_description}"
      aws lambda create-function-url-config --function-name "${var.function_name}" --qualifier "${var.alias}" --auth-type "${var.function_url.authorization_type}"
      aws lambda add-permission --function-name "${var.function_name}" --statement-id "${var.alias}-AllowPublicAccess" --action "lambda:InvokeFunctionUrl" --principal "*" --qualifier "${var.alias}" --function-url-auth-type "${var.function_url.authorization_type}"
    EOT
  }
}