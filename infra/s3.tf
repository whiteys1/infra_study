# s3.tf
# 개발용 S3 버킷

resource "aws_s3_bucket" "app" {
  bucket = "dev-everywear-app-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name = "dev-everywear-app"
  }
}

resource "aws_s3_bucket_versioning" "app" {
  bucket = aws_s3_bucket.app.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "app" {
  bucket = aws_s3_bucket.app.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# 개발 환경이므로 퍼블릭 액세스 차단
resource "aws_s3_bucket_public_access_block" "app" {
  bucket = aws_s3_bucket.app.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 현재 AWS 계정 ID 조회용
data "aws_caller_identity" "current" {}