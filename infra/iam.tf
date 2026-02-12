# iam.tf
# ECS Task Role: 컨테이너가 실행 중 AWS 서비스에 접근할 때 사용

resource "aws_iam_role" "ecs_task" {
  name = "dev-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "dev-ecs-task-role"
  }
}

# S3 접근 정책
resource "aws_iam_role_policy" "ecs_task_s3" {
  name = "dev-ecs-task-s3-policy"
  role = aws_iam_role.ecs_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.app.arn,
          "${aws_s3_bucket.app.arn}/*"
        ]
      }
    ]
  })
}

# ECS Task Role에 SQS 접근 정책 수정
resource "aws_iam_role_policy" "ecs_task_sqs" {
  name = "dev-ecs-task-sqs-policy"
  role = aws_iam_role.ecs_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SQSSendReceive"
        Effect = "Allow"
        Action = [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl",
          "sqs:ChangeMessageVisibility"
        ]
        Resource = [
          aws_sqs_queue.crawling_request.arn,
          aws_sqs_queue.crawling_dlq.arn,
          aws_sqs_queue.fitting_request.arn,
          aws_sqs_queue.fitting_dlq.arn
        ]
      }
    ]
  })
}