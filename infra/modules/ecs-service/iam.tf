data "aws_iam_policy_document" "ecs_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# Pulls the image and writes logs (used by the ECS agent).
resource "aws_iam_role" "task_execution" {
  name                 = "exam-${var.name}-task-execution"
  assume_role_policy   = data.aws_iam_policy_document.ecs_assume.json
  permissions_boundary = var.permissions_boundary_arn
  tags                 = var.tags
}

resource "aws_iam_role_policy_attachment" "task_execution" {
  role       = aws_iam_role.task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Identity the application code runs as (no extra perms needed yet).
resource "aws_iam_role" "task" {
  name                 = "exam-${var.name}-task"
  assume_role_policy   = data.aws_iam_policy_document.ecs_assume.json
  permissions_boundary = var.permissions_boundary_arn
  tags                 = var.tags
}

# CodeDeploy's role to orchestrate ECS blue/green deployments.
data "aws_iam_policy_document" "codedeploy_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["codedeploy.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "codedeploy" {
  name                 = "exam-${var.name}-codedeploy"
  assume_role_policy   = data.aws_iam_policy_document.codedeploy_assume.json
  permissions_boundary = var.permissions_boundary_arn
  tags                 = var.tags
}

resource "aws_iam_role_policy_attachment" "codedeploy" {
  role       = aws_iam_role.codedeploy.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS"
}
