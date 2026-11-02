include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "${get_repo_root()}/infra/modules/ecr"
}

inputs = {
  name = "hello-world"
}
