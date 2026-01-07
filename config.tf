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

# LOCALS

locals {
  db_workdir         = "/opt/postgres"
  db_compose_b64     = base64encode(file("${path.module}/docker-compose.yml"))
  db_env_b64         = base64encode(file("${path.module}/.env"))
  db_init_sql_b64    = base64encode(file("${path.module}/init.sql"))
}

# NETWORK

resource "yandex_vpc_network" "network-1" {
  name = "project-main-network"
}

resource "yandex_vpc_security_group" "ssh_sg" {
  name      = "ssh-sg"
  network_id = yandex_vpc_network.network-1.id

  ingress {
    protocol   = "TCP"
    port       = 22
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "db_sg" {
  name      = "db-sg"
  network_id = yandex_vpc_network.network-1.id

  ingress {
    protocol   = "TCP"
    port       = 5432
    v4_cidr_blocks = ["10.3.0.0/24"]
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# PUBLIC SUBNET

resource "yandex_vpc_subnet" "public_subnet" {
  name           = "project-public-subnet-a"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.network-1.id
  v4_cidr_blocks = ["10.3.0.0/24"]
}

# PRIVATE SUBNET

resource "yandex_vpc_subnet" "private_db_subnet" {
  name           = "project-db-private-subnet-a"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.network-1.id
  v4_cidr_blocks = ["10.3.1.0/24"]
}

# OLD SUBNET
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
    subnet_id         = yandex_vpc_subnet.subnet-1.id
    nat               = true
    security_group_ids = [
      yandex_vpc_security_group.ssh_sg.id,
      yandex_vpc_security_group.db_sg.id
    ]
  }


  metadata = {
    ssh-keys = <<EOF
ubuntu:${file("~/.ssh/id_rsa.pub")}
ubuntu:${file("~/.ssh/id_rsa_sasha.pub")}
EOF

    user-data = <<EOF
#cloud-config
runcmd:
  - |
    #!/usr/bin/env bash
    set -eu

    WORKDIR="${local.db_workdir}"

    mkdir -p "$WORKDIR"

    echo "${local.db_compose_b64}"  | base64 -d > "$WORKDIR/docker-compose.yml"
    echo "${local.db_env_b64}"      | base64 -d > "$WORKDIR/.env"
    echo "${local.db_init_sql_b64}" | base64 -d > "$WORKDIR/init.sql"

    chmod 0644 "$WORKDIR/docker-compose.yml" "$WORKDIR/init.sql"
    chmod 0600 "$WORKDIR/.env"

    cd "$WORKDIR"

    docker compose up -d
    docker compose ps
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