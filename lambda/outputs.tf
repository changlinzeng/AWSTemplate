output "invoke_arn" {
  value = aws_lambda_function.this.invoke_arn
}

output "function_url" {
  value = aws_lambda_function_url.this_url.function_url
}