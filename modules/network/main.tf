terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
}


resource "yandex_vpc_network" "network_1" {
  name = "project-main-network"
}

resource "yandex_vpc_gateway" "nat_gw" {
  name = "project-nat-gateway"

  shared_egress_gateway {}
}

resource "yandex_vpc_route_table" "private_rt" {
  name       = "project-private-rt"
  network_id = yandex_vpc_network.network_1.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat_gw.id
  }
}


resource "yandex_vpc_security_group" "ssh_sg" {
  name       = "ssh-sg"
  network_id = yandex_vpc_network.network_1.id

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
  network_id = yandex_vpc_network.network_1.id

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
  network_id = yandex_vpc_network.network_1.id

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


resource "yandex_vpc_subnet" "public_subnet" {
  name           = "project-public-subnet-a"
  zone           = var.zone
  network_id     = yandex_vpc_network.network_1.id
  v4_cidr_blocks = ["10.3.0.0/24"]
}

resource "yandex_vpc_subnet" "private_db_subnet" {
  name           = "project-db-private-subnet-a"
  zone           = var.zone
  network_id     = yandex_vpc_network.network_1.id
  v4_cidr_blocks = ["10.3.1.0/24"]
  route_table_id = yandex_vpc_route_table.private_rt.id
}
