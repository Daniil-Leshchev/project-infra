terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.177"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9"
    }
  }
}

provider "yandex" {
  folder_id = var.folder_id
  cloud_id  = var.cloud_id
}

variable "cloud_id" {
  type = string
}

variable "folder_id" {
  type = string
}

resource "yandex_iam_service_account" "trading_reports_sa" {
  name        = "trading-reports-sa"
  description = "Для записи отчетов в Object Storage"
}

resource "yandex_resourcemanager_folder_iam_member" "trading_reports_sa_storage" {
  folder_id = var.folder_id
  role      = "storage.editor"
  member    = "serviceAccount:${yandex_iam_service_account.trading_reports_sa.id}"
}

resource "time_sleep" "wait_for_iam" {
  depends_on = [
    yandex_resourcemanager_folder_iam_member.trading_reports_sa_storage
  ]
  create_duration = "30s"
}

resource "yandex_iam_service_account_static_access_key" "trading_reports_sa_key" {
  service_account_id = yandex_iam_service_account.trading_reports_sa.id
  description        = "S3 access for trading reports backend"
}

resource "yandex_storage_bucket" "reports_bucket" {
  bucket = "bucket-for-reports-orders"
  access_key = yandex_iam_service_account_static_access_key.trading_reports_sa_key.access_key
  secret_key = yandex_iam_service_account_static_access_key.trading_reports_sa_key.secret_key

  force_destroy = true

  anonymous_access_flags {
    read = false
    list = false
  }

  depends_on = [
    time_sleep.wait_for_iam
  ]
}

resource "yandex_container_registry" "backend_registry" {
  name = "backend-registry"
}

resource "yandex_resourcemanager_folder_iam_member" "trading_reports_sa_registry_pusher" {
  folder_id = var.folder_id
  role      = "container-registry.images.pusher"
  member    = "serviceAccount:${yandex_iam_service_account.trading_reports_sa.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "trading_reports_sa_registry_puller" {
  folder_id = var.folder_id
  role      = "container-registry.images.puller"
  member    = "serviceAccount:${yandex_iam_service_account.trading_reports_sa.id}"
}

output "storage_access_key_id" {
  value       = yandex_iam_service_account_static_access_key.trading_reports_sa_key.access_key
  description = "Access key for Object Storage"
}

output "storage_secret_access_key" {
  value       = yandex_iam_service_account_static_access_key.trading_reports_sa_key.secret_key
  description = "Secret key for Object Storage"
  sensitive   = true
}

output "storage_bucket_name" {
  value       = yandex_storage_bucket.reports_bucket.bucket
  description = "Object Storage bucket name for trading reports"
}

output "container_registry_id" {
  value       = yandex_container_registry.backend_registry.id
  description = "ID of Container Registry"
}

output "container_registry_name" {
  value       = yandex_container_registry.backend_registry.name
  description = "Name of Container Registry"
}