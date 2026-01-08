output "external_ip_address_bastion" {
  value       = yandex_compute_instance.bastion.network_interface.0.nat_ip_address
  description = "Public NAT IP of the bastion host"
}