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
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone      = var.zone
}