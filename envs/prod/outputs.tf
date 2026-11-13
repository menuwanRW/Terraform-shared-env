output "alb_dns_name" { value = module.service.alb_dns_name }
output "cluster_name" { value = module.service.cluster_name }
output "service_name" { value = module.service.service_name }
output "dashboard_name" { value = module.observability.dashboard_name }
