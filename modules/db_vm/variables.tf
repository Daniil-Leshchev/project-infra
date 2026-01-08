variable "cloud_id" {
  type = string
}

variable "folder_id" {
  type = string
}

variable "zone" {
  type    = string
  default = "ru-central1-a"
}

variable "image_id" {
  type = string
}

variable "private_db_subnet_id" {
  type        = string
  description = "Private subnet ID for DB VM"
}

variable "db_sg_id" {
  type        = string
  description = "Security group ID for DB access"
}

variable "db_ssh_sg_id" {
  type        = string
  description = "Security group ID for SSH access from bastion"
}