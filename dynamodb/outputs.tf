output "dynamodb_id" {
  value = aws_dynamodb_table.this.id
}

output "dynamodb_arn" {
  value = aws_dynamodb_table.this.arn
}