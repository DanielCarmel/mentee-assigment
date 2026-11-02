resource "aws_cloudwatch_log_group" "this" {
  name              = "/ecs/${var.name}"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

resource "aws_ecs_cluster" "this" {
  name = var.name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = var.tags
}

# Initial task definition. CI registers new revisions on every release;
# CodeDeploy picks the revision at deploy time, so we ignore drift here.
resource "aws_ecs_task_definition" "this" {
  family                   = var.name
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = aws_iam_role.task_execution.arn
  task_role_arn            = aws_iam_role.task.arn

  container_definitions = jsonencode([
    {
      name      = var.name
      image     = var.image
      essential = true
      portMappings = [
        {
          containerPort = var.container_port
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "APP_VERSION"
          value = var.app_version
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.this.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = var.tags

  lifecycle {
    ignore_changes = [container_definitions]
  }
}

resource "aws_ecs_service" "this" {
  name            = var.name
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  deployment_controller {
    type = "CODE_DEPLOY"
  }

  network_configuration {
    subnets          = data.aws_subnets.default.ids
    security_groups  = [aws_security_group.service.id]
    assign_public_ip = true # default-VPC public subnets pull from ECR without NAT
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.blue.arn
    container_name   = var.name
    container_port   = var.container_port
  }

  # CodeDeploy manages task_definition + the active target group.
  lifecycle {
    ignore_changes = [task_definition, load_balancer]
  }

  depends_on = [aws_lb_listener.http]

  tags = var.tags
}
