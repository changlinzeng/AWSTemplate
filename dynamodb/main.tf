resource "aws_dynamodb_table" "this" {
  name                        = var.name
  hash_key                    = var.partition_key
  range_key                   = var.sort_key
  table_class                 = var.table_class
  billing_mode                = "PROVISIONED"
  deletion_protection_enabled = var.deletion_protection
  dynamic "attribute" {
    for_each = var.attributes
    content {
      name = attribute.value.name
      type = attribute.value.type
    }
  }
  dynamic "global_secondary_index" {
    for_each = var.global_secondary_index.hash_key != "" ? [1] : []
    content {
      hash_key        = var.global_secondary_index.hash_key
      name            = var.global_secondary_index.name
      projection_type = var.global_secondary_index.projection_type
    }
  }
  dynamic "local_secondary_index" {
    for_each = var.local_secondary_index.range_key != "" ? [1] : []
    content {
      name            = var.local_secondary_index.name
      projection_type = var.local_secondary_index.projection_type
      range_key       = var.local_secondary_index.range_key
    }
  }
  read_capacity  = var.read_capacity
  write_capacity = var.write_capacity
  ttl {
    enabled        = var.ttl.enabled
    attribute_name = var.ttl.attribute_name
  }
  tags = merge(var.tags, {
    Usage = "Dynamodb"
  })
}