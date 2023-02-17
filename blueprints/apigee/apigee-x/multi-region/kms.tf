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

module "database_kms" {
  source     = "../../../../modules/kms"
  project_id = module.service_project.project_id
  keyring    = { location = "global", name = "apigee" }
  key_purpose = {
    database-encryption-key = {
      purpose          = "ENCRYPT_DECRYPT"
      version_template = null
    }
  }
  keys = { database-encryption-key = null }
  key_iam = {
    database-encryption-key = {
      "roles/cloudkms.cryptoKeyEncrypterDecrypter" = ["serviceAccount:${module.service_project.service_accounts.robots.apigee}"]
    }
  }
}

module "disk_kms" {
  for_each   = var.network_config
  source     = "../../../../modules/kms"
  project_id = module.service_project.project_id
  keyring    = { location = each.key, name = "apigee-${each.key}" }
  key_purpose = {
    disk-encryption-key = {
      purpose          = "ENCRYPT_DECRYPT"
      version_template = null
    }
  }
  keys = { disk-encryption-key = null }
  key_iam = {
    disk-encryption-key = {
      "roles/cloudkms.cryptoKeyEncrypterDecrypter" = ["serviceAccount:${module.service_project.service_accounts.robots.apigee}"]
    }
  }
}
