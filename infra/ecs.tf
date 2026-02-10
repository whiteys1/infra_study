# ecs.tf
# - ECS Cluster
# - CloudWatch Log Group
# - Task Execution Role
# - Task Definition (Fargate, awsvpc)
# - ECS Service (assign_public_ip = true, ALB 연동)

resource "aws_ecs_cluster" "main" {
  name = "dev-ecs-cluster"
}

resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/dev-backend"
  retention_in_days = 3
}

# ECS가 ECR에서 이미지 Pull, CloudWatch Logs로 로그 전송 등을 하기 위한 실행 역할
resource "aws_iam_role" "ecs_task_execution" {
  name = "dev-ecs-task-execution-role"

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
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_attach" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_task_definition" "backend" {
  family                   = "dev-backend"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "512"
  memory                   = "1024"

  execution_role_arn = aws_iam_role.ecs_task_execution.arn
  task_role_arn      = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name      = "backend"
      image     = "${aws_ecr_repository.backend.repository_url}:${var.backend_image_tag}"
      essential = true

      portMappings = [
        {
          containerPort = var.app_port
          hostPort      = var.app_port
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "DB_URL"
          value = "jdbc:mysql://dev-mysql.c7a2aw6wem27.ap-northeast-2.rds.amazonaws.com:3306/everywear?useSSL=false&serverTimezone=Asia/Seoul&characterEncoding=UTF-8"
        },
        {
          name  = "DB_USER"
          value = var.db_username
        },
        {
          name  = "DB_PASSWORD"
          value = var.db_password
        },
        {
          name  = "S3_BUCKET"
          value = aws_s3_bucket.app.id
        },
        {
          name  = "AWS_REGION"
          value = var.aws_region
        },
        {
          name  = "SQS_CRAWLING_QUEUE_URL"
          value = aws_sqs_queue.crawling_request.url
        },
        {
          name  = "JWT_SECRET"
          value = var.jwt_secret
        },
        {
          name  = "JWT_ACCESS_TOKEN_EXPIRATION"
          value = tostring(var.jwt_access_token_expiration)
        },
        {
          name  = "JWT_REFRESH_TOKEN_EXPIRATION"
          value = tostring(var.jwt_refresh_token_expiration)
        },
        {
          name  = "KAKAO_CLIENT_ID"
          value = var.kakao_client_id
        },
        {
          name  = "KAKAO_CLIENT_SECRET"
          value = var.kakao_client_secret
        },
        {
          name  = "KAKAO_ADMIN_KEY"
          value = var.kakao_admin_key
        },
        {
          name  = "GOOGLE_CLIENT_ID"
          value = var.google_client_id
        },
        {
          name  = "GOOGLE_CLIENT_SECRET"
          value = var.google_client_secret
        },
        {
          name  = "FASTAPI_BASE_URL"
          value = "http://crawler.everywear.local:8001"
        },
        {
          name  = "GEMINI_API_KEY"
          value = var.gemini_api_key_backend
        },
        {
          name  = "OPENAI_API_KEY"
          value = var.gpt_api_key
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "backend" {
  name            = "dev-backend-svc"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.backend.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.public_a.id, aws_subnet.public_c.id]
    security_groups  = [aws_security_group.backend.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = "backend"
    container_port   = var.app_port
  }

  service_registries {
    registry_arn = aws_service_discovery_service.backend.arn
  }

  # ⭐ deployment_configuration와 health_check_grace_period_seconds는 load_balancer가 있을 때만 함께 사용
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200
  
  health_check_grace_period_seconds = 60

  depends_on = [
    aws_lb_listener.http,
    aws_service_discovery_service.backend
  ]
}

# Crawler용 CloudWatch Log Group
resource "aws_cloudwatch_log_group" "crawler" {
  name              = "/ecs/dev-crawler"
  retention_in_days = 3
}

# Crawler Task Definition
resource "aws_ecs_task_definition" "crawler" {
  family                   = "dev-crawler"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "512"
  memory                   = "1024"

  execution_role_arn = aws_iam_role.ecs_task_execution.arn
  task_role_arn      = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name      = "crawler"
      image     = "${aws_ecr_repository.crawler.repository_url}:${var.crawler_image_tag}"
      essential = true

      portMappings = [
        {
          containerPort = 8001
          hostPort      = 8001
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "AWS_REGION"
          value = var.aws_region
        },
        {
          name  = "DATABASE_URL"
          value = "mysql://${var.db_username}:${var.db_password}@${aws_db_instance.mysql.address}:3306/${var.db_name}?charset=utf8mb4"
        },
        {
          name  = "SQS_CRAWLING_QUEUE_URL"
          value = aws_sqs_queue.crawling_request.url
        },
        {
          name  = "GEMINI_API_KEY"
          value = var.gemini_api_key_crawler
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.crawler.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "crawler" {
  name            = "dev-crawler-svc"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.crawler.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.public_a.id, aws_subnet.public_c.id]
    security_groups  = [aws_security_group.crawler.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.crawler.arn
    container_name   = "crawler"
    container_port   = 8001
  }

  service_registries {
    registry_arn = aws_service_discovery_service.crawler.arn
  }

  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200

  health_check_grace_period_seconds = 60

  depends_on = [
    aws_lb_listener.http,
    aws_service_discovery_service.crawler
  ]
}