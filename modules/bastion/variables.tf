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

variable "public_subnet_id" {
  type        = string
  description = "Subnet ID for bastion (public subnet)"
}

variable "ssh_sg_id" {
  type        = string
  description = "Security group ID that allows SSH from the Internet"
}

variable "ssh_public_key_path" {
  type        = string
  description = "Path to SSH public key that will be added to instance metadata (ssh-keys)"
  default     = "~/.ssh/id_rsa.pub"
}

variable "bastion_private_key_path" {
  type        = string
  description = "Path to SSH private key that will be copied into the bastion VM for hopping to private hosts"
  default     = "~/.ssh/id_rsa"
}