module "iam" {
  source = "../modules/iam"

  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  db_pass   = var.db_pass
}

module "network" {
  source = "../modules/network"

  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone      = "ru-central1-a"
}

module "bastion" {
  source = "../modules/bastion"

  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone      = "ru-central1-a"

  image_id          = var.image_id
  public_subnet_id  = module.network.public_subnet_id
  ssh_sg_id         = module.network.ssh_sg_id
}

module "db_vm" {
  source = "../modules/db_vm"

  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone      = "ru-central1-a"

  image_id = var.image_id

  private_db_subnet_id = module.network.private_db_subnet_id
  db_sg_id             = module.network.db_sg_id
  db_ssh_sg_id         = module.network.db_ssh_sg_id
}

module "backend_serverless" {
  source = "../modules/backend_serverless"

  backend_image_url = var.backend_image_url
  backend_cpu       = var.backend_cpu
  backend_memory    = var.backend_memory
  backend_concurrency = var.backend_concurrency

  db_host = module.db_vm.internal_ip_address
  db_port = var.db_port
  db_name = var.db_name
  db_user = var.db_user

  yc_region = var.yc_region

  network_id = module.network.network_id

  runtime_service_account_id = module.iam.runtime_service_account_id
  lockbox_secret_id          = module.iam.lockbox_secret_id
  lockbox_secret_version_id  = module.iam.lockbox_secret_version_id
  storage_bucket_name        = module.iam.storage_bucket_name
}

module "api_gateway" {
  source = "../modules/api_gateway"

  backend_container_id      = module.backend_serverless.backend_container_id
  api_gw_service_account_id = module.iam.api_gw_service_account_id
}

