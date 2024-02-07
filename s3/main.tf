resource "aws_s3_bucket" "this" {
  bucket              = var.bucket_name
  force_destroy       = true
  object_lock_enabled = true
  tags = merge(var.tags, {
    Name = var.bucket_name
  })
}

resource "aws_s3_bucket_ownership_controls" "bucket_owner_control" {
  bucket = aws_s3_bucket.this.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_versioning" "bucket_versioning" {
  bucket = aws_s3_bucket.this.id
  versioning_configuration {
    status = var.enable_bucket_versioning ? "Enabled" : "Disabled"
  }
}

resource "aws_s3_bucket_acl" "bucket_acl" {
  bucket = aws_s3_bucket.this.id
  acl    = var.public_bucket ? "public-read" : "private"
}