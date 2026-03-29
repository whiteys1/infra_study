# alb.tf

# ============================================================
# 외부 ALB (Internet-facing) - 백엔드 전용
# ============================================================
resource "aws_lb" "app" {
  name               = "dev-app-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_c.id]
  idle_timeout       = 180

  tags = { Name = "dev-app-alb" }
}

resource "aws_lb_target_group" "app" {
  name        = "dev-app-tg"
  port        = var.app_port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    enabled             = true
    protocol            = "HTTP"
    path                = "/"
    matcher             = "200-399"
    interval            = 60
    timeout             = 10
    healthy_threshold   = 2
    unhealthy_threshold = 5
  }

  deregistration_delay = 30
  tags = { Name = "dev-app-tg" }
}

# HTTP → HTTPS 리디렉션
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# HTTPS Listener (백엔드 전용, 크롤러 rule 제거)
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.app.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate.cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

# ============================================================
# 크롤러 Internal ALB (VPC 내부 전용)
# ============================================================
resource "aws_lb" "crawler" {
  name               = "dev-crawler-internal-alb"
  internal           = true   # 외부 접근 차단, VPC 내부 전용
  load_balancer_type = "application"
  security_groups    = [aws_security_group.crawler_alb.id]
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_c.id]
  idle_timeout       = 180    # 크롤링 처리 시간 고려

  tags = { Name = "dev-crawler-internal-alb" }
}

resource "aws_lb_target_group" "crawler" {
  name        = "dev-crawler-tg"
  port        = 8001
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"
  load_balancing_algorithm_type = "least_outstanding_requests"

  health_check {
    enabled             = true
    protocol            = "HTTP"
    path                = "/health"
    matcher             = "200-399"
    interval            = 30
    timeout             = 10
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  deregistration_delay = 30
  tags = { Name = "dev-crawler-tg" }
}

# 크롤러 Internal ALB Listener (HTTP, 포트 8001)
resource "aws_lb_listener" "crawler_http" {
  load_balancer_arn = aws_lb.crawler.arn
  port              = 8001
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.crawler.arn
  }
}