variable "cloud_id" {
  type = string
}

variable "folder_id" {
  type = string
}

variable "db_pass" {
  type      = string
  sensitive = true
}

variable "image_id" {
  type = string
}


variable "backend_image_url" {
  type        = string
  description = "Docker image URL for serverless backend"
}

variable "backend_cpu" {
  type        = number
  description = "CPU cores for serverless backend"
  default     = 1
}

variable "backend_memory" {
  type        = number
  description = "Memory (MB) for serverless backend"
  default     = 512
}

variable "backend_concurrency" {
  type        = number
  description = "Concurrency limit for serverless backend"
  default     = 10
}

variable "db_port" {
  type        = string
  description = "PostgreSQL port"
  default     = "5432"
}

variable "db_name" {
  type        = string
  description = "PostgreSQL database name"
}

variable "db_user" {
  type        = string
  description = "PostgreSQL user"
}

variable "yc_region" {
  type        = string
  description = "Yandex Cloud region"
  default     = "ru-central1"
}

variable "zone" {
  type    = string
  default = "ru-central1-a"
}
