resource "random_pet" "s3_bucket_name" {
  prefix = "template-s3-bucket"
  length = 6
}

resource "aws_default_vpc" "default" {}

module "iam" {
  source = "./iam"
}

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
  filename      = "${path.module}/lambda/lambda-1.0-SNAPSHOT.jar"
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
  publish    = false
  alias      = "test-alias"
  depends_on = [module.iam]
}

#module "test_lambda_rds" {
#  source        = "./lambda"
#  function_name = "test-lambda-java-rds"
#  function_type = "file"
#  filename      = "${path.module}/lambda/lambda-1.0-SNAPSHOT.jar"
#  runtime       = "java21"
#  handler       = "lambda.RdsHandler::handleRequest"
#  architectures = ["arm64"]
#}

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
  source               = "./apigateway/proxy"
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
    variables            = {}
  }
  enable_cloudwatch = false
  depends_on        = [module.iam]
}

module "test_lambda_kotlin" {
  source        = "./lambda"
  function_name = "test-lambda-kotlin"
  function_type = "file"
  filename      = "${path.module}/lambda/KotlinLambda-1.0-SNAPSHOT-jar-with-dependencies.jar"
  image_uri     = ""
  s3_bucket_id  = ""
  s3_object_id  = ""
  runtime       = "java21"
  handler       = "lambda.ApiGatewayHandler::handleRequest"
  architectures = ["arm64"]
  publish       = true
  alias         = "apigw-v1"
  integrations  = ["apigateway"]
#  vpc_id = data.aws_vpcs.main_vpc.ids[0]
#  vpc_config_subnets = data.aws_subnets.private_subnets.ids
  depends_on    = [module.iam]
}

module "test_api_gateway_lambda_kotlin" {
  source               = "./apigateway/proxy"
  api_name             = "test-lambda-api-kotlin"
  lambda_function_name = "test-lambda-kotlin"
  function_alias       = "apigw-v1"
  aws_region           = var.aws_region
  stage = {
    create               = true
    name                 = "test-lambda-kotlin"
    enable_cache         = false
    cache_size           = 0.5
    cache_ttl_seconds    = 300
    cache_data_encrypted = false
    enable_metrics       = false
    logging_level        = "OFF"
    variables            = {}
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

data "aws_subnets" "private_subnets" {
  filter {
    name   = "vpc-id"
    values = tolist(data.aws_vpcs.main_vpc.ids)
  }
  filter {
    name   = "tag:Tier"
    values = ["Private"]
  }
}

module "mysql_single" {
  source          = "./rds/mysql"
  region          = var.aws_region
  vpc_id          = data.aws_vpcs.main_vpc.ids[0]
  db_name         = "product_catalog"
  engine          = "mysql"
  engine_version  = "8.0"
  master_username = "root"
  master_password = "admin123456"
  port            = 3306
}

module "ec2" {
  source = "./ec2"
  vpc_id = data.aws_vpcs.main_vpc.ids[0]
  #  vpc_id = aws_default_vpc.default.id
  ingresses = [{
    from_port = 8000
    to_port   = 8999
    protocol  = "TCP"
  }]
}

#module "alb" {
#  source  = "./elb"
#  lb_name = "test-alb"
#  listeners = [{
#    protocol    = "HTTP"
#    port        = 80
#    action_type = "forward"
#  }]
#  target_group = {
#    name        = ""
#    port        = 8088
#    protocol    = "HTTP"
#    target_type = "instance"
#  }
#  vpc_id = data.aws_vpcs.main_vpc.ids[0]
#}

module "private-nlb" {
  source   = "./elb"
  lb_name  = "test-private-nlb"
  lb_type  = "network"
  internal = true
  listeners = [{
    protocol    = "TCP"
    port        = 80
    action_type = "forward"
  }]
  target_group = {
    name        = ""
    port        = 8088
    protocol    = "TCP"
    target_type = "instance"
  }
  vpc_id = data.aws_vpcs.main_vpc.ids[0]
}

module "test_api_gateway_nlb" {
  source           = "./apigateway/proxy"
  api_name         = "test-nlb-api"
  aws_region       = var.aws_region
  integration_type = "HTTP_PROXY"
  target_arns      = ["arn:aws:elasticloadbalancing:us-east-1:478332897299:loadbalancer/net/test-private-nlb/0322a5d39bafd2c2"]
  stage = {
    create               = true
    name                 = "test-nlb"
    enable_cache         = false
    cache_size           = 0.5
    cache_ttl_seconds    = 300
    cache_data_encrypted = false
    enable_metrics       = false
    logging_level        = "OFF"
    variables            = {}
  }
  enable_cloudwatch = false
  depends_on        = [module.iam]
}

module "efs" {
  source = "./efs"
  name   = "test-efs"
  backup = false
  vpc_id = data.aws_vpcs.main_vpc.ids[0]
}