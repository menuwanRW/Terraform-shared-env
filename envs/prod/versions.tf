terraform {
  required_version = ">= 1.11"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.81"
    }
  }

  # Bucket/region/KMS key come from backend.hcl (partial configuration) so no account IDs are hard-coded here.
  # Native S3 locking (use_lockfile) needs no DynamoDB table.
  backend "s3" {
    key          = "prod/terraform.tfstate"
    encrypt      = true
    use_lockfile = true
  }
}
