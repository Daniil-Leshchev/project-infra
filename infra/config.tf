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

data "terraform_remote_state" "iam" {
  backend = "local"

  config = {
    path = "../iam/terraform.tfstate"
  }
}

data "yandex_lockbox_secret" "backend" {
  secret_id = data.terraform_remote_state.iam.outputs.lockbox_secret_id
}

data "yandex_lockbox_secret_version" "backend" {
  secret_id = data.yandex_lockbox_secret.backend.id
}

variable "backend_image_url" {
  type = string
}

variable "backend_cpu" {
  type    = number
  default = 1
}

variable "backend_memory" {
  type    = number
  default = 512
}

variable "backend_concurrency" {
  type    = number
  default = 10
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

variable "db_port" {
  type    = string
  default = "5432"
}

variable "db_name" {
  type    = string
}

variable "db_user" {
  type    = string
}

variable "yc_region" {
  type    = string
  default = "ru-central1"
}

# LOCALS

locals {
  db_workdir              = "/opt/postgres"
  db_compose_b64          = base64encode(file("${path.module}/files/docker-compose.yml"))
  db_init_sql_b64         = base64encode(file("${path.module}/files/init.sql"))
  db_seed_sql_b64         = base64encode(file("${path.module}/files/seed.sql"))
  db_env_b64              = base64encode(file("${path.module}/files/.env"))
  bastion_private_key_b64 = base64encode(file("~/.ssh/id_rsa"))
}

# NETWORK

resource "yandex_vpc_network" "network-1" {
  name = "project-main-network"
}

resource "yandex_vpc_gateway" "nat_gw" {
  name = "project-nat-gateway"
  shared_egress_gateway {}
}

resource "yandex_vpc_route_table" "private_rt" {
  name       = "project-private-rt"
  network_id = yandex_vpc_network.network-1.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat_gw.id
  }
}

resource "yandex_vpc_security_group" "ssh_sg" {
  name       = "ssh-sg"
  network_id = yandex_vpc_network.network-1.id

  ingress {
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "db_ssh_sg" {
  name       = "db-ssh-from-bastion-sg"
  network_id = yandex_vpc_network.network-1.id

  ingress {
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = ["10.3.0.0/24"]
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "db_sg" {
  name       = "db-sg"
  network_id = yandex_vpc_network.network-1.id

  ingress {
    protocol       = "TCP"
    port           = 5432
    v4_cidr_blocks = ["198.19.0.0/16"]
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

# BASTION HOST

resource "yandex_compute_instance" "bastion" {
  name        = "project-bastion-vm-01"
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
    subnet_id = yandex_vpc_subnet.public_subnet.id
    nat       = true
    security_group_ids = [
      yandex_vpc_security_group.ssh_sg.id
    ]
  }

  metadata = {
    ssh-keys = <<EOF
ubuntu:${file("~/.ssh/id_rsa.pub")}
EOF

    user-data = <<EOF
#cloud-config
runcmd:
  - |
    mkdir -p /home/ubuntu/.ssh
    echo "${local.bastion_private_key_b64}" | base64 -d > /home/ubuntu/.ssh/id_rsa
    chmod 600 /home/ubuntu/.ssh/id_rsa
    chown -R ubuntu:ubuntu /home/ubuntu/.ssh
EOF
  }
}

# PRIVATE SUBNET
resource "yandex_vpc_subnet" "private_db_subnet" {
  name           = "project-db-private-subnet-a"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.network-1.id
  v4_cidr_blocks = ["10.3.1.0/24"]
  route_table_id = yandex_vpc_route_table.private_rt.id
}

# DB VM

resource "yandex_compute_instance" "vm-1" {
  name        = "project-db-vm-01"
  platform_id = "standard-v1"
  zone        = "ru-central1-a"

  allow_stopping_for_update = true

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
    subnet_id = yandex_vpc_subnet.private_db_subnet.id
    nat       = false
    security_group_ids = [
      yandex_vpc_security_group.db_sg.id,
      yandex_vpc_security_group.db_ssh_sg.id
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
    echo "${local.db_init_sql_b64}" | base64 -d > "$WORKDIR/init.sql"
    echo "${local.db_seed_sql_b64}" | base64 -d > "$WORKDIR/seed.sql"
    echo "${local.db_env_b64}"      | base64 -d > "$WORKDIR/.env"

    chmod 0644 "$WORKDIR/docker-compose.yml" "$WORKDIR/init.sql" "$WORKDIR/seed.sql"
    chmod 0600 "$WORKDIR/.env"

    cd "$WORKDIR"

    docker compose up -d
    docker compose ps
EOF
  }
}

resource "yandex_serverless_container" "backend" {
  name = "project-backend"

  memory = var.backend_memory
  cores  = var.backend_cpu

  execution_timeout = "30s"
  concurrency       = var.backend_concurrency

  service_account_id = data.terraform_remote_state.iam.outputs.runtime_service_account_id

  image {
    url = var.backend_image_url

    environment = {
      DB_HOST               = yandex_compute_instance.vm-1.network_interface[0].ip_address
      DB_PORT               = var.db_port
      DB_NAME               = var.db_name
      DB_USER               = var.db_user
      YC_OBJ_STORAGE_BUCKET = data.terraform_remote_state.iam.outputs.storage_bucket_name
      YC_REGION             = var.yc_region
    }
  }

  secrets {
    environment_variable = "DB_PASS"
    id                   = data.yandex_lockbox_secret.backend.id
    version_id           = data.yandex_lockbox_secret_version.backend.id
    key                  = "DB_PASS"
  }

  secrets {
    environment_variable = "YC_ACCESS_KEY_ID"
    id                   = data.yandex_lockbox_secret.backend.id
    version_id           = data.yandex_lockbox_secret_version.backend.id
    key                  = "YC_ACCESS_KEY_ID"
  }

  secrets {
    environment_variable = "YC_SECRET_ACCESS_KEY"
    id                   = data.yandex_lockbox_secret.backend.id
    version_id           = data.yandex_lockbox_secret_version.backend.id
    key                  = "YC_SECRET_ACCESS_KEY"
  }

  connectivity {
    network_id = yandex_vpc_network.network-1.id
  }
}

# API GATEWAY
resource "yandex_api_gateway" "backend_gw" {
  name                = "project-backend-gw"
  description         = "API Gateway for serverless backend"

  spec = <<EOF
openapi: 3.0.0
info:
  title: Exchange API
  version: 1.0.0

paths:
  /{proxy+}:
    x-yc-apigateway-any-method:
      parameters:
        - name: proxy
          in: path
          required: true
          schema:
            type: string
      x-yc-apigateway-integration:
        type: serverless_containers
        container_id: ${yandex_serverless_container.backend.id}
        service_account_id: ${data.terraform_remote_state.iam.outputs.api_gw_service_account_id}
        timeout: 30s
        headers:
          Authorization: "{request.headers.Authorization}"
EOF
}

#
# OUTPUTS

output "internal_ip_address_vm_1" {
  value = yandex_compute_instance.vm-1.network_interface.0.ip_address
}

output "external_ip_address_vm_1" {
  value = yandex_compute_instance.vm-1.network_interface.0.nat_ip_address
}

output "external_ip_address_bastion" {
  value = yandex_compute_instance.bastion.network_interface.0.nat_ip_address
}

output "backend_container_id" {
  value = yandex_serverless_container.backend.id
}

output "api_gw_domain" {
  value = yandex_api_gateway.backend_gw.domain
}
