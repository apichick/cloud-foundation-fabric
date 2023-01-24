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

module "apigee" {
  source     = "../../../../modules/apigee"
  project_id = module.project.project_id
  organization = merge(var.organization, {
    authorized_network      = module.vpc.name
    database_encryption_key = module.database_kms.keys["database-encryption_key"].id
  })
  envgroups    = var.envgroups
  environments = var.environments
  instances = { for k, v in var.instances : k => merge(v,
    { disk_encryption_key = module.disks_kms[k].keys["database-encryption_key"].id })
  }
}
