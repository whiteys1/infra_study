# variables.tf (provider에서 사용할 최소 변수)
variable "aws_region" {
  type    = string
  default = "ap-northeast-2"
}

variable "app_port" {
  description = "Container port exposed by the backend service"
  type        = number
  default     = 8080
}

variable "db_port" {
  description = "Database port (MySQL=3306, Postgres=5432)"
  type        = number
  default     = 3306
}

variable "backend_image_tag" {
  description = "ECR image tag for backend container"
  type        = string
  default     = "latest"
}

variable "db_name" {
  type    = string
  default = "everywear"
}

variable "db_username" {
  type    = string
  default = "root"
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "db_instance_class" {
  type    = string
  default = "db.t4g.micro"
}

variable "db_allocated_storage" {
  type    = number
  default = 20
}

variable "db_max_allocated_storage" {
  type    = number
  default = 50
}

# JWT 관련 변수 추가
variable "jwt_secret" {
  type        = string
  sensitive   = true
  description = "JWT secret key for token signing"
}

variable "jwt_access_token_expiration" {
  type        = number
  default     = 3600000  # 1시간 (밀리초)
  description = "JWT access token expiration time in milliseconds"
}

variable "jwt_refresh_token_expiration" {
  type        = number
  default     = 1209600000  # 7일
  description = "JWT refresh token expiration time in milliseconds"
}

# OAuth2 관련 변수 추가
variable "kakao_client_id" {
  type        = string
  sensitive   = true
  description = "Kakao OAuth2 client ID"
}

variable "kakao_client_secret" {
  type        = string
  sensitive   = true
  description = "Kakao OAuth2 client secret"
}

variable "kakao_admin_key" {
  type        = string
  sensitive   = true
  description = "Kakao Admin Key"
}