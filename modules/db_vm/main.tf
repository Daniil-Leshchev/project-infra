terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
}

locals {
  db_workdir     = "/opt/postgres"
  db_compose_b64 = base64encode(file("${path.module}/files/docker-compose.yml"))
  db_init_sql_b64 = base64encode(file("${path.module}/files/init.sql"))
  db_seed_sql_b64 = base64encode(file("${path.module}/files/seed.sql"))
  db_env_b64     = base64encode(file("${path.module}/files/.env"))
}


resource "yandex_compute_instance" "db_vm" {
  name        = "project-db-vm-01"
  platform_id = "standard-v1"
  zone        = var.zone

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
    subnet_id = var.private_db_subnet_id
    nat       = false

    security_group_ids = [
      var.db_sg_id,
      var.db_ssh_sg_id
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
