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

variable "db_host" {
  type = string
}

variable "db_port" {
  type    = string
  default = "5432"
}

variable "db_name" {
  type = string
}

variable "db_user" {
  type = string
}

variable "yc_region" {
  type    = string
  default = "ru-central1"
}

variable "network_id" {
  type = string
}

variable "runtime_service_account_id" {
  type = string
}

variable "lockbox_secret_id" {
  type = string
}

variable "lockbox_secret_version_id" {
  type = string
}

variable "storage_bucket_name" {
  type = string
}