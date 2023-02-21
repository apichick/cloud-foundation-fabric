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

locals {
  organization = {
    billing_type            = "PAYG"
    analytics_region        = keys(var.network_config)[0]
    authorized_network      = module.trusted_vpc.name
    database_encryption_key = module.database_kms.keys["database-encryption-key"].id
  }
  envgroups = {
    test = [var.hostnames.test]
    prod = [var.hostnames.prod]
  }
  environments = {
    apis-test = {
      envgroups = ["test"]
    }
    apis-prod = {
      envgroups = ["prod"]
    }
  }
  instances = { for k, v in var.network_config : "instance-${k}" => {
    region                        = k
    environments                  = ["apis-test", "apis-prod"]
    runtime_ip_cidr_range         = v.apigee_runtime_ip_cidr_range
    troubleshooting_ip_cidr_range = v.apigee_troubleshooting_ip_cidr_range
    disk_encryption_key           = module.disk_kms[k].key_ids["disk-encryption-key"]
    }
  }
}

module "apigee" {
  source     = "../../../../modules/apigee"
  project_id = module.service_project.project_id
  organization = merge(local.organization, {
    authorized_network      = module.trusted_vpc.network.id
    database_encryption_key = module.database_kms.keys["database-encryption-key"].id
  })
  envgroups    = local.envgroups
  environments = local.environments
  instances    = local.instances
}
