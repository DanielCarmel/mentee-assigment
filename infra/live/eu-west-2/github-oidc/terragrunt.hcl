include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "${get_repo_root()}/infra/modules/github-oidc"
}

dependency "ecr" {
  config_path = "../ecr"

  mock_outputs = {
    repository_arn = "arn:aws:ecr:eu-west-2:000000000000:repository/hello-world"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

dependency "ecs" {
  config_path = "../ecs-service"

  mock_outputs = {
    task_execution_role_arn = "arn:aws:iam::000000000000:role/exam-hello-world-task-execution"
    task_role_arn           = "arn:aws:iam::000000000000:role/exam-hello-world-task"
    codedeploy_app_arn      = "arn:aws:codedeploy:eu-west-2:000000000000:application:hello-world"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

inputs = {
  role_name          = "exam-github-actions"
  ecr_repository_arn = dependency.ecr.outputs.repository_arn
  codedeploy_app_arn = dependency.ecs.outputs.codedeploy_app_arn
  task_role_arns = [
    dependency.ecs.outputs.task_execution_role_arn,
    dependency.ecs.outputs.task_role_arn,
  ]
}
