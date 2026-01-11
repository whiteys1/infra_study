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
  cpu                      = "256"
  memory                   = "512"

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

      # 환경 변수 추가
      environment = [
        {
          name  = "DB_URL"
          value = "jdbc:mysql://dev-mysql.c7a2aw6wem27.ap-northeast-2.rds.amazonaws.com:3306/everywear?useSSL=false&serverTimezone=Asia/Seoul&characterEncoding=UTF-8"
        },
        # {
        #   name  = "DB_HOST"
        #   value = aws_db_instance.mysql.address
        # },
        # {
        #   name  = "DB_PORT"
        #   value = tostring(aws_db_instance.mysql.port)
        # },
        # {
        #   name  = "DB_NAME"
        #   value = aws_db_instance.mysql.db_name
        # },
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
        # JWT 환경변수 추가
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
        # OAuth2 환경변수 추가
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
        # Crawler 서비스 URL 추가
        {
          name  = "CRAWLER_SERVICE_URL"
          value = "http://crawler.everywear.local:8001"
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
    security_groups  = [aws_security_group.ecs_task.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = "backend"
    container_port   = var.app_port
  }

  # Service Discovery 추가
  service_registries {
    registry_arn = aws_service_discovery_service.backend.arn
  }

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

# Crawler ECS Service (Service Discovery 연결)
resource "aws_ecs_service" "crawler" {
  name            = "dev-crawler-svc"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.crawler.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.public_a.id, aws_subnet.public_c.id]
    security_groups  = [aws_security_group.ecs_task.id]
    assign_public_ip = true
  }

  service_registries {
    registry_arn = aws_service_discovery_service.crawler.arn
  }

  depends_on = [aws_service_discovery_service.crawler]
}