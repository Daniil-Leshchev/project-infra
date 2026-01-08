variable "cloud_id" {
  type        = string
  description = "Yandex Cloud ID"
}

variable "folder_id" {
  type        = string
  description = "Yandex Cloud Folder ID"
}

variable "db_pass" {
  type        = string
  description = "PostgreSQL password for backend"
  sensitive   = true
}