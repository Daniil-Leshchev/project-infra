output "db_vm_id" {
  value       = yandex_compute_instance.db_vm.id
  description = "ID of DB VM"
}

output "internal_ip_address" {
  value       = yandex_compute_instance.db_vm.network_interface.0.ip_address
  description = "Internal IP address of DB VM"
}
