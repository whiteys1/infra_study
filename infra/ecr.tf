# ecr.tf
# Backend 컨테이너 이미지를 올릴 ECR 리포지토리

resource "aws_ecr_repository" "backend" {
  name                 = "dev-backend"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "dev-backend"
  }
}

# 최신 아닌 이미지 자동 정리(개발용)
resource "aws_ecr_lifecycle_policy" "backend" {
  repository = aws_ecr_repository.backend.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
