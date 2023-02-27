resource "random_id" "this" {
  byte_length = 4
}

#tfsec:ignore:aws-s3-enable-bucket-logging
resource "aws_s3_bucket" "builds" {
  bucket = "pufferfish-builds-${random_id.this.hex}"
}

#tfsec:ignore:aws-s3-encryption-customer-key
resource "aws_s3_bucket_server_side_encryption_configuration" "builds" {
  bucket = aws_s3_bucket.builds.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_versioning" "builds" {
  bucket = aws_s3_bucket.builds.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "builds" {
  bucket                  = aws_s3_bucket.builds.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_ssm_parameter" "builds_s3_name" {
  name  = "/pufferfish/infra/builds_s3_name"
  type  = "String"
  value = aws_s3_bucket.builds.bucket
}
