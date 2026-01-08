terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.177"
    }
  }

  backend "local" {
    path = "terraform.tfstate"
  }
}

provider "yandex" {
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
}

resource "yandex_container_registry" "backend" {
  name = "backend-registry"
}
