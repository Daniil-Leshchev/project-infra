terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
}

resource "yandex_iam_service_account" "storage_sa" {
  name        = "reports-storage-sa"
  description = "Доступ backend к Object Storage"
}

resource "yandex_iam_service_account" "runtime_sa" {
  name        = "backend-runtime-sa"
  description = "Runtime service account для serverless backend"
}

resource "yandex_iam_service_account" "api_gw_sa" {
  name        = "api-gateway-sa"
  description = "Service account for API Gateway to invoke serverless backend"
}

resource "yandex_iam_service_account_static_access_key" "storage_sa_key" {
  service_account_id = yandex_iam_service_account.storage_sa.id
  description        = "S3 access for trading reports backend"
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

resource "yandex_resourcemanager_folder_iam_member" "runtime_registry_puller" {
  folder_id = var.folder_id
  role      = "container-registry.images.puller"
  member    = "serviceAccount:${yandex_iam_service_account.runtime_sa.id}"
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

resource "yandex_resourcemanager_folder_iam_member" "api_gw_invoker" {
  folder_id = var.folder_id
  role      = "serverless.containers.invoker"
  member    = "serviceAccount:${yandex_iam_service_account.api_gw_sa.id}"
}

resource "time_sleep" "wait_iam" {
  depends_on = [
    yandex_resourcemanager_folder_iam_member.storage_sa_role,
    yandex_resourcemanager_folder_iam_member.runtime_registry_puller,
    yandex_resourcemanager_folder_iam_member.runtime_logs
  ]
  create_duration = "30s"
}

resource "yandex_storage_bucket" "reports_bucket" {
  bucket      = "bucket-for-reports-orders"
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
