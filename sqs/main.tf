resource "aws_sqs_queue" "this" {
  count                      = var.fifo ? 0 : 1
  name                       = var.queue_name
  visibility_timeout_seconds = var.visibility_timeout_seconds
  sqs_managed_sse_enabled    = true
  tags = merge(var.tags, {
    Usage = "SQS"
    Name  = var.queue_name
  })
}

resource "aws_sqs_queue" "this_fifo" {
  count                       = var.fifo ? 1 : 0
  name                        = var.queue_name
  fifo_queue                  = true
  visibility_timeout_seconds  = var.visibility_timeout_seconds
  content_based_deduplication = true
  deduplication_scope         = "messageGroup"
  fifo_throughput_limit       = "perMessageGroupId"
  sqs_managed_sse_enabled     = true
  tags = merge(var.tags, {
    Usage = "SQS"
    Name  = var.queue_name
  })
}

resource "aws_sqs_queue" "dead_letter_queue" {
  count = var.create_dead_letter_queue ? 1 : 0
  redrive_allow_policy = jsonencode(
    {
      redrivePermission = "byQueue"
      sourceQueueArns   = [var.fifo ? aws_sqs_queue.this_fifo[0].arn : aws_sqs_queue.this[0].arn]
    }
  )
  tags = merge(var.tags, {
    Usage = "SQS"
    Name  = var.dead_letter_queue_name
  })
}