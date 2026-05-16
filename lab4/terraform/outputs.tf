output "worker_ip" {
  description = "Worker VM IP address."
  value       = local.worker_ip
}

output "db_ip" {
  description = "Database VM IP address."
  value       = local.db_ip
}

output "ansible_inventory" {
  description = "Generated Ansible inventory path."
  value       = local_file.ansible_inventory.filename
}
