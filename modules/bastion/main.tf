terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
}

locals {
  bastion_private_key_b64 = base64encode(file(var.bastion_private_key_path))
}


resource "yandex_compute_instance" "bastion" {
  name        = "project-bastion-vm-01"
  platform_id = "standard-v1"
  zone        = var.zone

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
    subnet_id = var.public_subnet_id
    nat       = true

    security_group_ids = [
      var.ssh_sg_id
    ]
  }

  metadata = {
    ssh-keys = <<EOF
ubuntu:${file(var.ssh_public_key_path)}
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
