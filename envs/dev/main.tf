provider "aws" {
  region = var.region
  default_tags {
    tags = { Project = var.project, Environment = "dev", ManagedBy = "terraform" }
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  name = "${var.project}-dev"
  azs  = slice(data.aws_availability_zones.available.names, 0, 2)
}

# Dev optimises for COST: 2 AZs, one shared NAT, no interface endpoints, Spot capacity.
module "network" {
  source                     = "../../modules/network"
  name                       = local.name
  cidr                       = "10.10.0.0/16"
  azs                        = local.azs
  enable_nat_gateway         = true
  single_nat_gateway         = true
  enable_interface_endpoints = false
  flow_log_retention_days    = 14
}

module "service" {
  source                = "../../modules/ecs-service"
  name                  = local.name
  vpc_id                = module.network.vpc_id
  public_subnet_ids     = module.network.public_subnet_ids
  private_subnet_ids    = module.network.private_subnet_ids
  container_image       = var.container_image
  certificate_arn       = var.certificate_arn
  s3_prefix_list_id     = module.network.s3_prefix_list_id
  vpce_sg_id            = module.network.endpoints_sg_id
  allow_internet_egress = true # goes through the single NAT
  use_spot              = true
  cpu                   = 256
  memory                = 512
  desired_count         = 1
  min_count             = 1
  max_count             = 3
  log_retention_days    = 14
  environment           = { APP_ENV = "dev" }
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
  min_running_tasks       = 1
}
