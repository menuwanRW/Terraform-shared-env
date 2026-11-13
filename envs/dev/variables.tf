variable "project" {
  type    = string
  default = "acme-app"
}

variable "region" {
  type    = string
  default = "ap-south-1"
}

variable "container_image" {
  description = "Bootstrap image; CI replaces it on every deploy."
  type        = string
}

variable "certificate_arn" {
  type    = string
  default = ""
}

variable "alarm_email" {
  type    = string
  default = ""
}
