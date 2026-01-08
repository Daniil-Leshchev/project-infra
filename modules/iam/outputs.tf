output "runtime_service_account_id" {
  value       = yandex_iam_service_account.runtime_sa.id
  description = "Service account ID for serverless backend runtime"
}

output "api_gw_service_account_id" {
  value       = yandex_iam_service_account.api_gw_sa.id
  description = "Service account ID for API Gateway"
}

output "storage_bucket_name" {
  value       = yandex_storage_bucket.reports_bucket.bucket
  description = "Object Storage bucket name for backend"
}

output "lockbox_secret_id" {
  value       = yandex_lockbox_secret.backend_secrets.id
  description = "Lockbox secret ID with backend secrets"
}

output "lockbox_secret_version_id" {
  value       = yandex_lockbox_secret_version.backend_secrets_v1.id
  description = "Active Lockbox secret version ID"
}

output "storage_access_key_id" {
  value       = yandex_iam_service_account_static_access_key.storage_sa_key.access_key
  description = "Access key for Object Storage"
}

output "storage_secret_access_key" {
  value       = yandex_iam_service_account_static_access_key.storage_sa_key.secret_key
  description = "Secret key for Object Storage"
  sensitive   = true
}