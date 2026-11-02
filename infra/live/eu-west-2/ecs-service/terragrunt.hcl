include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "${get_repo_root()}/infra/modules/ecs-service"
}

dependency "ecr" {
  config_path = "../ecr"

  mock_outputs = {
    repository_url = "000000000000.dkr.ecr.eu-west-2.amazonaws.com/hello-world"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

inputs = {
  name          = "hello-world"
  image         = "${dependency.ecr.outputs.repository_url}:bootstrap"
  container_port = 8000
  desired_count = 1
  app_version   = "0.0.0-bootstrap"
}
