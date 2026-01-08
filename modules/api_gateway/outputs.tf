output "api_gw_domain" {
  description = "Public domain of API Gateway"
  value       = yandex_api_gateway.backend_gw.domain
}