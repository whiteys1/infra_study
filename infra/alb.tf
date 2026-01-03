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

  # 개발 단계 기본 헬스체크(필요 시 경로/코드 수정)
  health_check {
    enabled             = true
    protocol            = "HTTP"
    path                = "/"
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

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
