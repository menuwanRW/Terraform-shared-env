variable "project" {
  type    = string
  default = "acme-app"
}

variable "region" {
  type    = string
  default = "ap-south-1"
}

variable "container_image" {
  type = string
}

variable "certificate_arn" {
  description = "ACM certificate for the public hostname. Required in prod: no plaintext listener."
  type        = string
  validation {
    condition     = length(var.certificate_arn) > 0
    error_message = "prod requires an ACM certificate_arn."
  }
}

variable "alarm_email" {
  type = string
}

variable "enable_internet_egress" {
  description = "false (default) = tasks can reach only S3 + VPC endpoints. Set true only if the app must call third-party APIs."
  type        = bool
  default     = false
}
