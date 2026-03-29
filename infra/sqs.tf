# sqs.tf
# - Crawling Request Queue (Backend → Crawler)
# - Dead Letter Queue (실패 메시지 보관)

# ============================================
# Fitting DLQ
# ============================================
resource "aws_sqs_queue" "fitting_dlq" {
  name                      = "dev-fitting-request-dlq"
  message_retention_seconds = 1209600 # 14일

  tags = {
    Name = "dev-fitting-request-dlq"
  }
}

# ============================================
# Fitting Queue
# ============================================
resource "aws_sqs_queue" "fitting_request" {
  name                       = "dev-fitting-request"
  visibility_timeout_seconds = 900 # 15분 (피팅 처리 시간이 더 길 수 있음)
  message_retention_seconds  = 86400
  receive_wait_time_seconds  = 20

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.fitting_dlq.arn
    maxReceiveCount     = 3
  })

  tags = {
    Name = "dev-fitting-request"
  }
}