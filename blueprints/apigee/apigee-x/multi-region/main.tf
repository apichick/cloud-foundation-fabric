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


module "host_project" {
  source          = "../../../../modules/project"
  parent          = var.parent
  billing_account = var.billing_account_id
  name            = var.host_project_id
  shared_vpc_host_config = {
    enabled = true
  }
  services = [
    "compute.googleapis.com",
    "servicenetworking.googleapis.com",
    "monitoring.googleapis.com"
  ]
  iam = {
    "roles/pubsub.publisher" = ["serviceAccount:${module.host_project.service_accounts.robots.monitoring-notifications}"]
  }
}

module "service_project" {
  source          = "../../../../modules/project"
  parent          = var.parent
  billing_account = var.billing_account_id
  name            = var.service_project_id
  services = [
    "apigee.googleapis.com",
    "cloudkms.googleapis.com",
    "compute.googleapis.com",
    "servicenetworking.googleapis.com"
  ]
  shared_vpc_service_config = {
    attach       = true
    host_project = module.host_project.project_id
  }
}
