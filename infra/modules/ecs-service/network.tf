# Use the account's default VPC + subnets (assignment simplification).
# Production: a dedicated VPC with private subnets + NAT for the tasks.
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# ALB security group: public entry point on port 80.
resource "aws_security_group" "alb" {
  name        = "${var.name}-alb"
  description = "Public HTTP ingress for the ALB"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

# Task security group: only the ALB can reach the container port.
resource "aws_security_group" "service" {
  name        = "${var.name}-service"
  description = "Allow traffic only from the ALB"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description     = "App port from ALB only"
    from_port       = var.container_port
    to_port         = var.container_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}
