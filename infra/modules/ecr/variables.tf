variable "name" {
  description = "ECR repository name."
  type        = string
}

variable "image_tag_mutability" {
  description = "IMMUTABLE keeps version tags from being overwritten."
  type        = string
  default     = "IMMUTABLE"
}

variable "scan_on_push" {
  description = "Run a vulnerability scan when an image is pushed."
  type        = bool
  default     = true
}

variable "max_image_count" {
  description = "How many images to retain before expiring the oldest."
  type        = number
  default     = 10
}

variable "tags" {
  description = "Extra tags."
  type        = map(string)
  default     = {}
}
