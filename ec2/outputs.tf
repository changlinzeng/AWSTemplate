output "instance_arn" {
  value = aws_instance.this[*].arn
}

output "instance_state" {
  value = aws_instance.this[*].instance_state
}

output "private_dns" {
  value = aws_instance.this[*].private_dns
}