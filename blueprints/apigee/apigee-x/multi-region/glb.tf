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

module "glb" {
  source              = "../../../../modules/net-glb"
  name                = "glb"
  project_id          = module.project.project_id
  protocol            = "HTTPS"
  use_classic_version = false
  backend_service_configs = {
    default = {
      backends      = [for k, v in var.instances : { backend = k }]
      protocol      = "HTTPS"
      health_checks = []
    }
  }
  health_check_configs = {
    default = {
      https = { port_specification = "USE_SERVING_PORT" }
    }
  }
  neg_configs = {
    for k, v in var.instances : k => {
      psc = {
        region         = v.region
        target_service = module.apigee.instances[k].service_attachment
        network        = module.vpc.network.self_link
        subnetwork = (
          module.vpc.subnets_psc["${v.region}/subnet-psc-${v.region}"].self_link
        )
      }
    }
  }
  ssl_certificates = {
    managed_configs = {
      default = {
        domains = flatten([for k, v in var.envgroups : v])
      }
    }
  }

}
