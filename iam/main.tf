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

variable "cloud_id" {
  type        = string
  description = "Yandex Cloud ID"
}

variable "folder_id" {
  type        = string
  description = "Yandex Cloud Folder ID"
}

variable "db_pass" {
  type        = string
  description = "PostgreSQL password for backend"
  sensitive   = true
}
provider "yandex" {
  folder_id = var.folder_id
  cloud_id  = var.cloud_id
}

resource "yandex_iam_service_account" "storage_sa" {
  name        = "reports-storage-sa"
  description = "Доступ backend к Object Storage"
}

resource "yandex_iam_service_account" "registry_ci_sa" {
  name        = "backend-registry-ci-sa"
  description = "CI/CD доступ к Container Registry"
}

resource "yandex_iam_service_account" "runtime_sa" {
  name        = "backend-runtime-sa"
  description = "Runtime service account для serverless backend"
}

resource "yandex_lockbox_secret" "backend_secrets" {
  name = "backend-secrets"
}

resource "yandex_lockbox_secret_version" "backend_secrets_v1" {
  secret_id = yandex_lockbox_secret.backend_secrets.id

  entries {
    key        = "DB_PASS"
    text_value = var.db_pass
  }

  entries {
    key        = "YC_ACCESS_KEY_ID"
    text_value = yandex_iam_service_account_static_access_key.storage_sa_key.access_key
  }

  entries {
    key        = "YC_SECRET_ACCESS_KEY"
    text_value = yandex_iam_service_account_static_access_key.storage_sa_key.secret_key
  }
}

resource "yandex_resourcemanager_folder_iam_member" "storage_sa_role" {
  folder_id = var.folder_id
  role      = "storage.editor"
  member    = "serviceAccount:${yandex_iam_service_account.storage_sa.id}"
}

resource "yandex_iam_service_account_static_access_key" "storage_sa_key" {
  service_account_id = yandex_iam_service_account.storage_sa.id
  description        = "S3 access for trading reports backend"
}

resource "yandex_storage_bucket" "reports_bucket" {
  bucket = "bucket-for-reports-orders"
  access_key = yandex_iam_service_account_static_access_key.storage_sa_key.access_key
  secret_key = yandex_iam_service_account_static_access_key.storage_sa_key.secret_key

  force_destroy = true

  anonymous_access_flags {
    read = false
    list = false
  }

  depends_on = [
    time_sleep.wait_iam
  ]
}
resource "time_sleep" "wait_iam" {
  depends_on = [
    yandex_resourcemanager_folder_iam_member.storage_sa_role,
    yandex_resourcemanager_folder_iam_member.registry_ci_pusher,
    yandex_resourcemanager_folder_iam_member.registry_ci_puller,
    yandex_resourcemanager_folder_iam_member.runtime_logs,
    yandex_resourcemanager_folder_iam_member.runtime_registry_puller
  ]
  create_duration = "30s"
}

resource "yandex_resourcemanager_folder_iam_member" "runtime_registry_puller" {
  folder_id = var.folder_id
  role      = "container-registry.images.puller"
  member    = "serviceAccount:${yandex_iam_service_account.runtime_sa.id}"
}

resource "yandex_container_registry" "backend_registry" {
  name = "backend-registry"
}

resource "yandex_resourcemanager_folder_iam_member" "registry_ci_pusher" {
  folder_id = var.folder_id
  role      = "container-registry.images.pusher"
  member    = "serviceAccount:${yandex_iam_service_account.registry_ci_sa.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "registry_ci_puller" {
  folder_id = var.folder_id
  role      = "container-registry.images.puller"
  member    = "serviceAccount:${yandex_iam_service_account.registry_ci_sa.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "runtime_logs" {
  folder_id = var.folder_id
  role      = "logging.writer"
  member    = "serviceAccount:${yandex_iam_service_account.runtime_sa.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "runtime_lockbox_access" {
  folder_id = var.folder_id
  role      = "lockbox.payloadViewer"
  member    = "serviceAccount:${yandex_iam_service_account.runtime_sa.id}"
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

output "runtime_service_account_id" {
  value       = yandex_iam_service_account.runtime_sa.id
  description = "Service account ID for serverless backend runtime"
}

output "registry_ci_service_account_id" {
  value       = yandex_iam_service_account.registry_ci_sa.id
  description = "Service account ID for Container Registry CI/CD"
}

output "lockbox_secret_id" {
  value       = yandex_lockbox_secret.backend_secrets.id
  description = "Lockbox secret ID with backend secrets"
}
