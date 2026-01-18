# security_group.tf

# 1) ALB Security Group
# - 인터넷(0.0.0.0/0)에서 HTTP(80) 접근 허용
# - 아웃바운드는 전체 허용(기본)
resource "aws_security_group" "alb" {
  name        = "dev-alb-sg"
  description = "Dev ALB SG: allow inbound HTTP from anywhere"
  vpc_id      = aws_vpc.main.id

  ingress {
    description      = "HTTP from anywhere"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    description      = "All outbound"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "dev-alb-sg"
  }
}

# 2) ECS Task Security Group
# - 인바운드는 ALB SG에서만(컨테이너 포트는 변수로)
# - 아웃바운드는 전체 허용(외부 API 호출 필요)
resource "aws_security_group" "ecs_task" {
  name        = "dev-ecs-task-sg"
  description = "Dev ECS Task SG: allow inbound only from ALB"
  vpc_id      = aws_vpc.main.id

  # Backend 포트
  ingress {
    description     = "App port from ALB"
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # Crawler 포트 추가
  ingress {
    description     = "Crawler port from ALB"
    from_port       = 8001
    to_port         = 8001
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description      = "All outbound (external API calls)"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "dev-ecs-task-sg"
  }
}


# 3) RDS Security Group
# - 개발 단계: DB 포트만 열고(0.0.0.0/0), 그 외는 차단
# - (권장 구성은 ECS SG만 허용이지만, 요청하신 전제대로 전체 IP 허용)
resource "aws_security_group" "rds" {
  name        = "dev-rds-sg"
  description = "Dev RDS SG: allow DB port from anywhere (dev only)"
  vpc_id      = aws_vpc.main.id

  ingress {
    description      = "DB port from anywhere (dev only)"
    from_port        = var.db_port
    to_port          = var.db_port
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    description      = "All outbound"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "dev-rds-sg"
  }
}

# ECS 태스크 간 내부 통신 허용 (Service Discovery용)
resource "aws_security_group_rule" "ecs_task_internal_crawler" {
  type              = "ingress"
  description       = "Allow crawler port from same security group (for service discovery)"
  from_port         = 8001
  to_port           = 8001
  protocol          = "tcp"
  security_group_id = aws_security_group.ecs_task.id
  source_security_group_id = aws_security_group.ecs_task.id  # 자기 자신을 소스로
}
