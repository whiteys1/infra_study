# alb.tf
# - Internet-facing ALB
# - Target Group (type = ip)
# - Listener :80 -> Target Group forward

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

  # 헬스체크 설정 (60초 대기)
  health_check {
    enabled             = true
    protocol            = "HTTP"
    path                = "/"
    matcher             = "200-399"
    interval            = 60              # 30초마다 체크
    timeout             = 10              # 응답 대기 10초
    healthy_threshold   = 2               # 2번 연속 성공시 healthy
    unhealthy_threshold = 5               # 3번 연속 실패시 unhealthy
  }
  # 총 대기 시간: interval(30) * healthy_threshold(2) = 60초

  # deregistration_delay 추가 (컨테이너 종료 시 연결 대기 시간)
  deregistration_delay = 30

  tags = {
    Name = "dev-app-tg"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
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

# Path-based routing rule 추가
resource "aws_lb_listener_rule" "crawler" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.crawler.arn
  }

  condition {
    path_pattern {
      values = ["/crawler/*"]
    }
  }
}