terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
}

provider "yandex" {
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone      = "ru-central1-a"
}

# VARIABLES

variable "cloud_id" {
  type = string
}

variable "folder_id" {
  type = string
}

variable "image_id" {
  type = string
}

# NETWORK

resource "yandex_vpc_network" "network-1" {
  name = "project-main-network"
}

resource "yandex_vpc_subnet" "subnet-1" {
  name           = "project-main-subnet-a"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.network-1.id
  v4_cidr_blocks = ["10.2.0.0/16"]
}

# DB VM

resource "yandex_compute_instance" "vm-1" {
  name        = "project-db-vm-01"
  platform_id = "standard-v1"
  zone        = "ru-central1-a"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = var.image_id
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-1.id
    nat       = true
  }

  metadata = {
    ssh-keys = <<EOF
ubuntu:${file("~/.ssh/id_rsa.pub")}
ubuntu:${file("~/.ssh/id_rsa_sasha.pub")}
EOF
  }
}

# OUTPUTS

output "internal_ip_address_vm_1" {
  value = yandex_compute_instance.vm-1.network_interface.0.ip_address
}

output "external_ip_address_vm_1" {
  value = yandex_compute_instance.vm-1.network_interface.0.nat_ip_address
}