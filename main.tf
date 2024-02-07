resource "random_pet" "s3_bucket_name" {
  prefix = "template-s3-bucket"
  length = 6
}

resource "aws_default_vpc" "default" {}

module "sqs" {
  source     = "./sqs"
  queue_name = "test-queue"
  tags       = local.tags
}

data "aws_sqs_queue" "test_queue" {
  name = "test-queue"
}

module "test_lambda" {
  source        = "./lambda"
  function_name = "test-lambda-java"
  function_type = "file"
  filename      = "${path.module}/lambda/lambda-1.1-SNAPSHOT.jar"
  image_uri     = ""
  s3_bucket_id  = ""
  s3_object_id  = ""
  runtime       = "java21"
  handler       = "lambda.SQSMessageHandler::handleRequest"
  architectures = ["arm64"]
  integrations  = ["dynamodb", "sqs"]
  sqs_event_source = {
    enabled                    = true
    arn                        = data.aws_sqs_queue.test_queue.arn
    batch_size                 = 10
    batch_window               = 0
    report_batch_item_failures = true
  }
}

#module "test_dynamodb_table" {
#  source = "./dynamodb"
#  name   = "product_catalog"
#  partition_key = "location"
#  sort_key = "product_id"
#  attributes = [{
#    name = "location"
#    type = "S"
#  }, {
#    name = "product_id"
#    type = "S"
#  }]
#}

module "test_api_gateway_lambda" {
  source               = "./apigateway/aws_proxy"
  api_name             = "test-lambda-api"
  lambda_function_name = "test-lambda-java"
  function_alias       = "apigw-target"
  aws_region           = var.aws_region
  stage = {
    create               = true
    name                 = "test-lambda"
    enable_cache         = false
    cache_size           = 0.5
    cache_ttl_seconds    = 300
    cache_data_encrypted = false
    enable_metrics       = false
    logging_level        = "OFF"
    #    logging_level        = "INFO"
  }
  enable_cloudwatch = false
}


#module "s3" {
#  source      = "./s3"
#  bucket_name = random_pet.s3_bucket_name.id
#  tags        = local.tags
#}

module "main_vpc" {
  source     = "./network"
  aws_region = var.aws_region
  vpc_name   = "main_vpc"
  tags       = local.tags
}

data "aws_vpcs" "main_vpc" {
  filter {
    name   = "tag:Name"
    values = ["${var.aws_region}-main_vpc"]
  }
}

#module "ec2" {
#  source = "./ec2"
#  vpc_id = data.aws_vpcs.main_vpc.ids[0]
#}