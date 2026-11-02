variable "name" {
  description = "Base name for all resources (cluster, service, ALB, roles)."
  type        = string
}

variable "aws_region" {
  description = "AWS region."
  type        = string
}

variable "image" {
  description = "Full image reference for the initial task definition (repo:tag)."
  type        = string
}

variable "container_port" {
  description = "Port the container listens on."
  type        = number
  default     = 8000
}

variable "cpu" {
  description = "Fargate task CPU units."
  type        = number
  default     = 256
}

variable "memory" {
  description = "Fargate task memory (MiB)."
  type        = number
  default     = 512
}

variable "desired_count" {
  description = "Number of tasks to run."
  type        = number
  default     = 1
}

variable "app_version" {
  description = "Version baked into the initial task definition (APP_VERSION env)."
  type        = string
  default     = "0.0.0-bootstrap"
}

variable "health_check_path" {
  description = "ALB target-group health check path."
  type        = string
  default     = "/health"
}

variable "permissions_boundary_arn" {
  description = "Permissions boundary required on all exam-* roles."
  type        = string
}

variable "log_retention_days" {
  description = "CloudWatch log retention."
  type        = number
  default     = 7
}

variable "tags" {
  description = "Extra tags."
  type        = map(string)
  default     = {}
}
