# alb.tf
# - Internet-facing ALB
# - Target Group (type = ip)
# - HTTP → HTTPS 리디렉션
# - HTTPS Listener

resource "aws_lb" "app" {
  name               = "dev-app-alb"
  internal           = false
  load_balancer_type = "application"

  security_groups = [aws_security_group.alb.id]
  subnets         = [aws_subnet.public_a.id, aws_subnet.public_c.id]

  idle_timeout = 180

  tags = {
    Name = "dev-app-alb"
  }
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

  tags = {
    Name = "dev-app-tg"
  }
}

# HTTP Listener - HTTPS로 리디렉션
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

# HTTPS Listener
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

# Crawler 경로 라우팅 규칙 (HTTPS용)
resource "aws_lb_listener_rule" "crawler_https" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 100

  condition {
    path_pattern {
      values = ["/crawler/*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.crawler.arn
  }
}

# 크롤러용 Target Group
resource "aws_lb_target_group" "crawler" {
  name        = "dev-crawler-tg"
  port        = 8001
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

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

  tags = {
    Name = "dev-crawler-tg"
  }
}