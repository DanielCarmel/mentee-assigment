variable "bucket_name" {
  description = "Globally-unique S3 bucket name for Terraform state."
  type        = string
}

variable "tags" {
  description = "Extra tags."
  type        = map(string)
  default     = {}
}
