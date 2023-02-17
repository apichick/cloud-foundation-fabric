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

variable "active_region" {
  description = "Active region."
  type        = string
  default     = "europe-west1"
}

variable "billing_account_id" {
  description = "Billing account ID."
  type        = string
  nullable    = false
}

variable "email_address" {
  description = "Email address"
  type        = string
  nullable    = false
}

variable "host_project_id" {
  description = "Host project ID."
  type        = string
  nullable    = false
}

variable "hostname" {
  description = "Host name"
  type        = string
}

variable "network_config" {
  description = "Network configuration"
  type = map(object({
    apigee_runtime_ip_cidr_range         = string
    apigee_troubleshooting_ip_cidr_range = string
    untrusted_subnet_ip_cidr_range       = string
    trusted_subnet_ip_cidr_range         = string
  }))
  default = {
    europe-west1 = {
      apigee_runtime_ip_cidr_range         = "10.0.4.0/22"
      apigee_troubleshooting_ip_cidr_range = "10.1.0.0/28"
      untrusted_subnet_ip_cidr_range       = "10.2.0.0/28"
      trusted_subnet_ip_cidr_range         = "10.3.0.0/28"
    }
    europe-west4 = {
      apigee_runtime_ip_cidr_range         = "10.0.8.0/22"
      apigee_troubleshooting_ip_cidr_range = "10.1.8.0/28"
      untrusted_subnet_ip_cidr_range       = "10.2.8.0/28"
      trusted_subnet_ip_cidr_range         = "10.3.8.0/28"
    }
  }
}

variable "parent" {
  description = "Parent."
  type        = string
  nullable    = false
}

variable "server_config" {
  description = "Server configuration"
  type = object({
    disk_size     = number
    disk_type     = string
    image         = string
    instance_type = string
    region        = string
    zone          = string
  })
  default = {
    disk_size     = 50
    disk_type     = "pd-ssd"
    image         = "projects/ubuntu-os-cloud/global/images/family/ubuntu-2204-lts"
    instance_type = "n1-standard-2"
    region        = "europe-west1"
    zone          = "europe-west1-c"
  }
}

variable "service_project_id" {
  description = "Service project ID."
  type        = string
  nullable    = false
}

