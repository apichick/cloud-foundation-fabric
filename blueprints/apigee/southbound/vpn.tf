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
module "apigee_vpn" {
  source        = "../../../modules/net-vpn-ha"
  project_id    = module.apigee_project.project_id
  network       = module.apigee_vpc.self_link
  region        = var.region
  name          = "vpn"
  router_create = true
  router_name   = "router"
  router_asn    = 64513
  router_advertise_config = {
    groups = ["ALL_SUBNETS"]
    ip_ranges = {
      "35.191.0.0/16"  = "health checks"
      "130.211.0.0/22" = "load balancers"
    }
    mode = "CUSTOM"
  }
  peer_gcp_gateway = module.onprem_vpn.self_link
  tunnels = {
    0 = {
      bgp_peer = {
        address = "169.254.2.2"
        asn     = 64514
      }
      bgp_peer_options                = null
      bgp_session_range               = "169.254.2.1/30"
      ike_version                     = 2
      peer_external_gateway_interface = null
      router                          = null
      shared_secret                   = var.shared_secret
      vpn_gateway_interface           = 0
    }
    1 = {
      bgp_peer = {
        address = "169.254.2.6"
        asn     = 64514
      }
      bgp_peer_options                = null
      bgp_session_range               = "169.254.2.5/30"
      ike_version                     = 2
      peer_external_gateway_interface = null
      router                          = null
      shared_secret                   = var.shared_secret
      vpn_gateway_interface           = 1
    }
  }
}

module "onprem_vpn" {
  source        = "../../../modules/net-vpn-ha"
  project_id    = module.onprem_project.project_id
  network       = module.onprem_vpc.self_link
  region        = var.region
  name          = "vpn"
  router_create = true
  router_name   = "router-${var.region}"
  router_asn    = 64514
  router_advertise_config = {
    groups = ["ALL_SUBNETS"]
    ip_ranges = {
    }
    mode   = "CUSTOM"
  }
  peer_gcp_gateway = module.apigee_vpn.self_link
  tunnels = {
    0 = {
      bgp_peer = {
        address = "169.254.2.1"
        asn     = 64513
      }
      bgp_peer_options                = null
      bgp_session_range               = "169.254.2.2/30"
      ike_version                     = 2
      peer_external_gateway_interface = null
      router                          = null
      shared_secret                   = var.shared_secret
      vpn_gateway_interface           = 0
    }
    1 = {
      bgp_peer = {
        address = "169.254.2.5"
        asn     = 64513
      }
      bgp_peer_options                = null
      bgp_session_range               = "169.254.2.6/30"
      ike_version                     = 2
      peer_external_gateway_interface = null
      router                          = null
      shared_secret                   = var.shared_secret
      vpn_gateway_interface           = 1
    }
  }
}

