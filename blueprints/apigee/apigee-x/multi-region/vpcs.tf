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

module "untrusted_vpc" {
  source     = "../../../../modules/net-vpc"
  project_id = module.host_project.project_id
  name       = "untrusted-vpc"
  subnets = [for k, v in var.network_config :
    {
      ip_cidr_range = v.untrusted_subnet_ip_cidr_range
      name          = "subnet-untrusted-${k}"
      region        = k
    }
  ]
 routes = { for k, v in var.network_config :  "to-trusted-${k}" =>
    {
      dest_range    = v.trusted_subnet_ip_cidr_range
      next_hop_type = "ilb"
      next_hop      = module.ilb_nva_untrusted[k].forwarding_rule.self_link
    }
  }
}

module "untrusted_vpc_firewall" {
  source     = "../../../../modules/net-vpc-firewall"
  project_id = module.host_project.project_id
  network    = module.untrusted_vpc.name
  default_rules_config = {
    admin_ranges = ["10.0.0.0/8"]
    ssh_ranges   = ["35.235.240.0/20", "35.191.0.0/16", "130.211.0.0/22"]
  }
}

module "trusted_vpc" {
  source     = "../../../../modules/net-vpc"
  project_id = module.host_project.project_id
  name       = "trusted-vpc"
  subnets = [for k, v in var.network_config :
    {
      ip_cidr_range = v.trusted_subnet_ip_cidr_range
      name          = "subnet-trusted-${k}"
      region        = k
    }
  ]
  routes = { for k, v in var.network_config : "to-untrusted-${k}" =>
    {
      dest_range    = "0.0.0.0/0"
      next_hop_type = "ilb"
      next_hop      = module.ilb_nva_trusted[k].forwarding_rule.self_link
    }
  }
  psa_config = {
    ranges = merge([for k, v in var.network_config : {
      "apigee-runtime-${k}"         = v.apigee_runtime_ip_cidr_range
      "apigee-troubleshooting-${k}" = v.apigee_troubleshooting_ip_cidr_range
    }]...)
  }
}

module "trusted_vpc_firewall" {
  source     = "../../../../modules/net-vpc-firewall"
  project_id = module.host_project.project_id
  network    = module.trusted_vpc.name
  default_rules_config = {
    admin_ranges = ["10.0.0.0/8"]
    ssh_ranges   = ["35.235.240.0/20", "35.191.0.0/16", "130.211.0.0/22"]
  }
}

module "untrusted_nat" {
  for_each       = var.network_config
  source         = "../../../../modules/net-cloudnat"
  project_id     = module.host_project.project_id
  region         = each.key
  name           = "untrusted-nat"
  router_network = module.untrusted_vpc.name
}