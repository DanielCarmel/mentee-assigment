# Fetch GitHub's OIDC endpoint certificate so we can pin its thumbprint.
data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com/.well-known/openid-configuration"
}

# One OIDC identity provider per account for GitHub Actions.
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github.certificates[0].sha1_fingerprint]
  tags            = var.tags
}

# Trust policy: only this repo, only via web identity, only the sts audience.
data "aws_iam_policy_document" "trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_org}/${var.github_repo}:*"]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name                 = var.role_name
  assume_role_policy   = data.aws_iam_policy_document.trust.json
  permissions_boundary = var.permissions_boundary_arn
  tags                 = var.tags
}

# Least-privilege permissions for the CI pipeline.
data "aws_iam_policy_document" "permissions" {
  # Auth to ECR (must be account/region wide).
  statement {
    sid       = "EcrAuth"
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  # Push/pull layers only on our repo.
  statement {
    sid    = "EcrPushPull"
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
    ]
    resources = [var.ecr_repository_arn]
  }

  # Register new task-def revisions (requires *).
  statement {
    sid    = "EcsRegisterTaskDef"
    effect = "Allow"
    actions = [
      "ecs:RegisterTaskDefinition",
      "ecs:DescribeTaskDefinition",
      "ecs:DescribeServices",
    ]
    resources = ["*"]
  }

  # Trigger blue/green deployments via CodeDeploy.
  statement {
    sid    = "CodeDeploy"
    effect = "Allow"
    actions = [
      "codedeploy:CreateDeployment",
      "codedeploy:GetDeployment",
      "codedeploy:GetDeploymentConfig",
      "codedeploy:GetApplicationRevision",
      "codedeploy:RegisterApplicationRevision",
      "codedeploy:GetDeploymentGroup",
    ]
    resources = ["*"]
  }

  # Pass the ECS roles into the task definition we register.
  statement {
    sid       = "PassEcsRoles"
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = var.task_role_arns
  }
}

resource "aws_iam_role_policy" "permissions" {
  name   = "${var.role_name}-permissions"
  role   = aws_iam_role.github_actions.id
  policy = data.aws_iam_policy_document.permissions.json
}
