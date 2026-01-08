terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
}

resource "yandex_serverless_container" "backend" {
  name = "project-backend"

  memory = var.backend_memory
  cores  = var.backend_cpu

  execution_timeout = "30s"
  concurrency       = var.backend_concurrency

  service_account_id = var.runtime_service_account_id

  image {
    url = var.backend_image_url

    environment = {
      DB_HOST               = var.db_host
      DB_PORT               = var.db_port
      DB_NAME               = var.db_name
      DB_USER               = var.db_user
      YC_OBJ_STORAGE_BUCKET = var.storage_bucket_name
      YC_REGION             = var.yc_region
    }
  }

  secrets {
    environment_variable = "DB_PASS"
    id                   = var.lockbox_secret_id
    version_id           = var.lockbox_secret_version_id
    key                  = "DB_PASS"
  }

  secrets {
    environment_variable = "YC_ACCESS_KEY_ID"
    id                   = var.lockbox_secret_id
    version_id           = var.lockbox_secret_version_id
    key                  = "YC_ACCESS_KEY_ID"
  }

  secrets {
    environment_variable = "YC_SECRET_ACCESS_KEY"
    id                   = var.lockbox_secret_id
    version_id           = var.lockbox_secret_version_id
    key                  = "YC_SECRET_ACCESS_KEY"
  }

  connectivity {
    network_id = var.network_id
  }
}

