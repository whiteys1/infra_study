# security_group.tf

# 1) ALB Security Group
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

  # HTTPS 추가
  ingress {
    description      = "HTTPS from anywhere"
    from_port        = 443
    to_port          = 443
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

# 2) 크롤러 Internal ALB Security Group (신규)
resource "aws_security_group" "crawler_alb" {
  name        = "dev-crawler-alb-sg"
  description = "Crawler Internal ALB SG: allow inbound from backend only"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "From backend tasks"
    from_port       = 8001
    to_port         = 8001
    protocol        = "tcp"
    security_groups = [aws_security_group.backend.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "dev-crawler-alb-sg" }
}

# ⭐ 2) Backend Security Group (신규)
resource "aws_security_group" "backend" {
  name        = "dev-backend-sg"
  description = "Dev Backend SG: allow inbound from ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "App port from ALB"
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description      = "All outbound (to call crawler and external APIs)"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "dev-backend-sg"
  }
}

# ⭐ 3) Crawler Security Group (신규)
resource "aws_security_group" "crawler" {
  name        = "dev-crawler-sg"
  description = "Dev Crawler SG: allow inbound from ALB and Backend"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Crawler port from ALB (health check)"
    from_port       = 8001
    to_port         = 8001
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # ⭐⭐⭐ 핵심: 백엔드에서 크롤러로 직접 통신 허용
  ingress {
    description     = "Crawler port from backend (crawling requests)"
    from_port       = 8001
    to_port         = 8001
    protocol        = "tcp"
    security_groups = [aws_security_group.backend.id]
  }

  egress {
    description      = "All outbound (to crawl external websites)"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "dev-crawler-sg"
  }
}

# 4) RDS Security Group - ⭐ 그대로 유지
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