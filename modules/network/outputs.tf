output "network_id" {
  value = yandex_vpc_network.network_1.id
}

output "public_subnet_id" {
  value = yandex_vpc_subnet.public_subnet.id
}

output "private_db_subnet_id" {
  value = yandex_vpc_subnet.private_db_subnet.id
}

output "ssh_sg_id" {
  value = yandex_vpc_security_group.ssh_sg.id
}

output "db_sg_id" {
  value = yandex_vpc_security_group.db_sg.id
}

output "db_ssh_sg_id" {
  value = yandex_vpc_security_group.db_ssh_sg.id
}