/**
 * Copyright 2023 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

locals {
  vm_startup_script = <<END
    apt update
    apt upgrade -y
    apt install -y nginx tcpdump
END
}

module "untrusted-servers" {
  for_each      = var.network_config
  source        = "../../../../modules/compute-vm"
  project_id    = module.host_project.project_id
  zone          = "${each.key}-b"
  name          = "uts-${each.key}-b"
  instance_type = var.server_config.instance_type
  network_interfaces = [{
    network    = module.untrusted_vpc.self_link
    subnetwork = module.untrusted_vpc.subnet_self_links["${each.key}/subnet-untrusted-${each.key}"]
    nat        = false
    addresses  = null
  }]
  service_account_create = true
  boot_disk = {
    image = var.server_config.image
    type  = var.server_config.disk_type
    size  = var.server_config.disk_size
  }
  tags = ["ssh"]
  metadata = {
    startup-script = local.vm_startup_script
  }
}

module "trusted-servers" {
  for_each      = var.network_config
  source        = "../../../../modules/compute-vm"
  project_id    = module.host_project.project_id
  zone          = "${each.key}-b"
  name          = "ts-${each.key}-b"
  instance_type = var.server_config.instance_type
  network_interfaces = [{
    network    = module.trusted_vpc.self_link
    subnetwork = module.trusted_vpc.subnet_self_links["${each.key}/subnet-trusted-${each.key}"]
    nat        = false
    addresses  = null
  }]
  service_account_create = true
  boot_disk = {
    image = var.server_config.image
    type  = var.server_config.disk_type
    size  = var.server_config.disk_size
  }
  tags = ["ssh"]
  metadata = {
    startup-script = local.vm_startup_script
  }
}