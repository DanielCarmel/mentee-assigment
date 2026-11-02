include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_repo_root()}/infra/modules/tfstate-backend"
}

# Chicken-and-egg: this unit creates the state bucket, so it cannot use it.
# Override the inherited S3 backend with local state for this unit only.
# This local state is disposable — losing it just means the bucket is
# unmanaged; the bucket (and all real state) still persists in S3.
remote_state {
  backend = "local"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    path = "${get_terragrunt_dir()}/terraform.tfstate"
  }
}

inputs = {
  bucket_name = "exam-mentee-tfstate-030454160336"
}
