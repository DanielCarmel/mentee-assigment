output "alb_dns_name" {
  description = "Public DNS name users hit."
  value       = aws_lb.this.dns_name
}

output "cluster_name" {
  description = "ECS cluster name."
  value       = aws_ecs_cluster.this.name
}

output "service_name" {
  description = "ECS service name."
  value       = aws_ecs_service.this.name
}

output "task_definition_family" {
  description = "Task definition family CI registers revisions against."
  value       = aws_ecs_task_definition.this.family
}

output "container_name" {
  description = "Container name (for appspec)."
  value       = var.name
}

output "container_port" {
  description = "Container port (for appspec)."
  value       = var.container_port
}

output "task_execution_role_arn" {
  description = "ECS task execution role ARN."
  value       = aws_iam_role.task_execution.arn
}

output "task_role_arn" {
  description = "ECS task role ARN."
  value       = aws_iam_role.task.arn
}

output "codedeploy_app_name" {
  description = "CodeDeploy application name."
  value       = aws_codedeploy_app.this.name
}

output "codedeploy_app_arn" {
  description = "CodeDeploy application ARN."
  value       = aws_codedeploy_app.this.arn
}

output "codedeploy_deployment_group_name" {
  description = "CodeDeploy deployment group name."
  value       = aws_codedeploy_deployment_group.this.deployment_group_name
}
