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
  health_check_configs = merge(flatten([
    for k1, v1 in local.envgroups : {
      for v2 in v1 : replace(v2, ".", "-") => {
        enable_logging      = true
        check_interval_sec  = 6
        timeout_sec         = 3
        healthy_threshold   = 10
        unhealthy_threshold = 3
        https = {
          host         = v2
          port         = 443
          request_path = "/healthz/ingress"
          response     = "Apigee Ingress is healthy"
        }
  } }])...)
}

module "glb" {
  source     = "../../../../modules/net-glb"
  project_id = module.host_project.project_id
  name       = "glb"
  protocol   = "HTTPS"
  backend_service_configs = {
    default = {
      backends = [for k, v in module.nvas :
        {
          backend        = "neg-${k}"
          balancing_mode = "RATE"
          max_rate       = { per_endpoint = 10 }
      } if startswith(k, var.active_region)]
      health_checks = keys(local.health_check_configs)
      protocol      = "HTTPS"
    }
  }
  health_check_configs = local.health_check_configs
  neg_configs = { for k, v in module.nvas :
    "neg-${k}" => {
      gce = {
        network    = module.untrusted_vpc.network.id
        subnetwork = module.untrusted_vpc.subnets["${var.active_region}/subnet-untrusted-${var.active_region}"].id
        zone       = k
        endpoints = {
          e-0 = {
            instance   = v.instance.name
            ip_address = v.internal_ip
            port       = 443
          }
        }
      }
    } if startswith(k, var.active_region)
  }
  ssl_certificates = {
    managed_configs = {
      default = {
        domains = flatten([for k, v in local.envgroups : v])
      }
    }
  }
}
