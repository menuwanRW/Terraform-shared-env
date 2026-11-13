provider "aws" {
  region = var.region
  default_tags {
    tags = { Project = var.project, Environment = "prod", ManagedBy = "terraform" }
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  name = "${var.project}-prod"
  azs  = slice(data.aws_availability_zones.available.names, 0, 3)
}

# Prod optimises for AVAILABILITY and LEAST PRIVILEGE: 3 AZs, PrivateLink endpoints, no internet egress by default.
module "network" {
  source                     = "../../modules/network"
  name                       = local.name
  cidr                       = "10.20.0.0/16"
  azs                        = local.azs
  enable_nat_gateway         = var.enable_internet_egress
  single_nat_gateway         = false # one NAT per AZ when enabled
  enable_interface_endpoints = true
  flow_log_retention_days    = 90
}

module "service" {
  source                   = "../../modules/ecs-service"
  name                     = local.name
  vpc_id                   = module.network.vpc_id
  public_subnet_ids        = module.network.public_subnet_ids
  private_subnet_ids       = module.network.private_subnet_ids
  container_image          = var.container_image
  certificate_arn          = var.certificate_arn
  s3_prefix_list_id        = module.network.s3_prefix_list_id
  vpce_sg_id               = module.network.endpoints_sg_id
  allow_internet_egress    = var.enable_internet_egress
  use_spot                 = false
  cpu                      = 1024
  memory                   = 2048
  desired_count            = 6
  min_count                = 6 # >= 2 per AZ so losing an AZ still leaves capacity
  max_count                = 60
  target_requests_per_task = 20000 # ~330 rps/task; derive from load tests, not guesswork
  log_retention_days       = 90
  deletion_protection      = true
  environment              = { APP_ENV = "prod" }
}

module "observability" {
  source                  = "../../modules/observability"
  name                    = local.name
  cluster_name            = module.service.cluster_name
  service_name            = module.service.service_name
  alb_arn_suffix          = module.service.alb_arn_suffix
  target_group_arn_suffix = module.service.target_group_arn_suffix
  log_group_name          = module.service.log_group_name
  alarm_email             = var.alarm_email
  min_running_tasks       = 6
  p99_latency_seconds     = 0.5
}
