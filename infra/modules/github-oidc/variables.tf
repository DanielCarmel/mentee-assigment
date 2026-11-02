variable "role_name" {
  description = "Name of the IAM role GitHub Actions assumes (must start with exam-)."
  type        = string
  default     = "exam-github-actions"
}

variable "github_org" {
  description = "GitHub organisation / user that owns the repo."
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name."
  type        = string
}

variable "permissions_boundary_arn" {
  description = "Permissions boundary required on all exam-* roles."
  type        = string
}

variable "ecr_repository_arn" {
  description = "ARN of the ECR repo CI pushes to."
  type        = string
}

variable "task_role_arns" {
  description = "ECS task roles CI must be able to iam:PassRole when registering task defs."
  type        = list(string)
}

variable "codedeploy_app_arn" {
  description = "ARN of the CodeDeploy application CI triggers."
  type        = string
}

variable "aws_region" {
  description = "AWS region."
  type        = string
}

variable "account_id" {
  description = "AWS account id."
  type        = string
}

variable "tags" {
  description = "Extra tags."
  type        = map(string)
  default     = {}
}
