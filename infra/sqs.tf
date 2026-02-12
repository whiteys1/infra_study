# sqs.tf
# - Crawling Request Queue (Backend → Crawler)
# - Dead Letter Queue (실패 메시지 보관)

# ============================================
# Dead Letter Queue (DLQ)
# ============================================
resource "aws_sqs_queue" "crawling_dlq" {
  name                      = "dev-crawling-request-dlq"
  message_retention_seconds = 1209600 # 14일 (최대치)

  tags = {
    Name = "dev-crawling-request-dlq"
  }
}

# ============================================
# Main Queue - 크롤링 요청용
# ============================================
resource "aws_sqs_queue" "crawling_request" {
  name                       = "dev-crawling-request"
  visibility_timeout_seconds = 120 # 5분 (크롤링 처리 시간 고려)
  message_retention_seconds  = 86400 # 1일
  receive_wait_time_seconds  = 20 # Long Polling 활성화

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.crawling_dlq.arn
    maxReceiveCount     = 3 # 3회 실패 시 DLQ로 이동
  })

  tags = {
    Name = "dev-crawling-request"
  }
}

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