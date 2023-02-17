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
  nva_zones = {
    for v in setproduct(keys(var.network_config), ["b", "c"]) :
    join("-", v) => v.0
  }
}

module "nvas" {
  for_each       = local.nva_zones
  source         = "../../../../modules/compute-vm"
  project_id     = module.host_project.project_id
  name           = "nva-${each.key}"
  zone           = each.key
  instance_type  = "e2-standard-2"
  tags           = ["nva"]
  can_ip_forward = true
  network_interfaces = [
    {
      network    = module.untrusted_vpc.self_link
      subnetwork = module.untrusted_vpc.subnet_self_links["${each.value}/subnet-untrusted-${each.value}"]
      nat        = false
      addresses  = null
    },
    {
      network    = module.trusted_vpc.self_link
      subnetwork = module.trusted_vpc.subnet_self_links["${each.value}/subnet-trusted-${each.value}"]
      nat        = false
      addresses  = null
    }
  ]
  boot_disk = {
    image = "projects/ubuntu-os-cloud/global/images/family/ubuntu-2004-lts",
    size  = 10
    type  = "pd-balanced"
  }
  options = {
    allow_stopping_for_update = true
    deletion_protection       = false
    spot                      = false
    termination_action        = "STOP"
  }
  metadata = {
    user-data = templatefile("${path.module}/templates/gateway.yaml.tpl",
      {
        ip_cidr_range = var.network_config[each.value].trusted_subnet_ip_cidr_range
        endpoint      = module.apigee.instances["instance-${each.value}"].host
    })
  }
  group = { named_ports = null }
}

module "ilb_nva_untrusted" {
  for_each      = var.network_config
  source        = "../../../../modules/net-ilb"
  project_id    = module.host_project.project_id
  region        = each.key
  name          = "nva-untrusted-${each.key}"
  global_access = true
  vpc_config = {
    network    = module.untrusted_vpc.self_link
    subnetwork = module.untrusted_vpc.subnet_self_links["${each.key}/subnet-untrusted-${each.key}"]
  }
  backends = [
    for k, v in module.nvas :
    { group = v.group.self_link }
    if startswith(k, each.key)
  ]
  health_check_config = {
    enable_logging = true
    tcp = {
      port = 22
    }
  }
}

module "ilb_nva_trusted" {
  for_each      = var.network_config
  source        = "../../../../modules/net-ilb"
  project_id    = module.host_project.project_id
  region        = each.key
  name          = "nva-trusted-${each.key}"
  global_access = true
  vpc_config = {
    network    = module.trusted_vpc.self_link
    subnetwork = module.trusted_vpc.subnet_self_links["${each.key}/subnet-trusted-${each.key}"]
  }
  backends = [
    for k, v in module.nvas :
    { group = v.group.self_link }
    if startswith(k, each.key)
  ]
  health_check_config = {
    enable_logging = true
    tcp = {
      port = 22
    }
  }
}