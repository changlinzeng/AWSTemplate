output "queue_arn" {
  value = var.fifo ? aws_sqs_queue.this_fifo[*].arn : aws_sqs_queue.this[*].arn
}

output "dead_letter_queue_arn" {
  value = aws_sqs_queue.dead_letter_queue[*].arn
}