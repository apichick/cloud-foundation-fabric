/**
 * Copyright 2022 Google LLC
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

module "apigee_project" {
  source          = "../../../modules/project"
  billing_account = var.billing_account_id
  parent          = var.parent
  name            = var.apigee_project_id
  services = [
    "apigee.googleapis.com",
    "compute.googleapis.com",
    "servicenetworking.googleapis.com",
  ]
}

module "apigee_vpc" {
  source     = "../../../modules/net-vpc"
  project_id = module.apigee_project.project_id
  name       = var.organization.authorized_network
  /*subnets_psc = [for k, v in var.psc_config :
    {
      ip_cidr_range = v
      name          = "subnet-psc-${k}"
      region        = k
    }
  ]
  psa_config = {
    ranges = { for k, v in var.instances :
      "apigee-${k}" => v.psa_ip_cidr_range
    }
  }*/
}
/*
module "apigee" {
  source       = "../../../modules/apigee"
  project_id   = module.apigee_project.project_id
  organization = var.organization
  envgroups    = var.envgroups
  environments = var.environments
  instances    = var.instances
  depends_on = [
    module.apigee_vpc
  ]
}

resource "google_compute_region_network_endpoint_group" "neg" {
  for_each              = var.instances
  name                  = "apigee-neg-${each.key}"
  project               = module.apigee_project.project_id
  region                = each.value.region
  network_endpoint_type = "PRIVATE_SERVICE_CONNECT"
  psc_target_service    = module.apigee.instances[each.key].service_attachment
  network               = module.apigee_vpc.network.self_link
  subnetwork            = module.apigee_vpc.subnets_psc["${each.value.region}/subnet-psc-${each.value.region}"].self_link
}

module "glb" {
  source     = "../../../modules/net-glb"
  name       = "glb"
  project_id = module.apigee_project.project_id

  https              = true
  reserve_ip_address = true

  ssl_certificates_config = { for k, v in var.envgroups :
    "${k}-domain" => {
      domains          = v,
      unmanaged_config = null
    }
  }

  target_proxy_https_config = {
    ssl_certificates = [for k, v in var.envgroups : "${k}-domain"]
  }

  health_checks_config_defaults = null

  backend_services_config = {
    apigee = {
      bucket_config = null
      enable_cdn    = false
      cdn_config    = null
      group_config = {
        backends = [for k, v in google_compute_region_network_endpoint_group.neg :
          {
            group   = v.id
            options = null
          }
        ],
        health_checks = []
        log_config    = null
        options = {
          affinity_cookie_ttl_sec         = null
          custom_request_headers          = null
          custom_response_headers         = null
          connection_draining_timeout_sec = null
          load_balancing_scheme           = "EXTERNAL_MANAGED"
          locality_lb_policy              = null
          port_name                       = null
          security_policy                 = null
          session_affinity                = null
          timeout_sec                     = null
          circuits_breakers               = null
          consistent_hash                 = null
          iap                             = null
          protocol                        = "HTTPS"
        }
      }
    }
  }
  global_forwarding_rule_config = {
    load_balancing_scheme = "EXTERNAL_MANAGED"
    ip_protocol           = "TCP"
    ip_version            = "IPV4"
    port_range            = null
  }
}*/