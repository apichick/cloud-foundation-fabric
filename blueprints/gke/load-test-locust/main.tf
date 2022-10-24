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
  image = (
    "${var.region}-docker.pkg.dev/${module.project.project_id}/${module.docker_artifact_registry.name}/locust-load-test:latest"
  )
}

module "project" {
  source = "../../../modules/project"
  billing_account = (var.project_create != null
    ? var.project_create.billing_account_id
    : null
  )
  parent = (var.project_create != null
    ? var.project_create.parent
    : null
  )
  prefix = var.project_create == null ? null : var.prefix
  name   = var.project_id
  services = [
    "artifactregistry.googleapis.com",
    "cloudbuild.googleapis.com",
    "container.googleapis.com"
  ]
  iam = {
    "roles/artifactregistry.reader"      = [module.sa.iam_email],
    "roles/container.nodeServiceAccount" = [module.sa.iam_email]
  }
}

module "vpc" {
  source     = "../../../modules/net-vpc"
  project_id = module.project.project_id
  name       = "${local.prefix}vpc"
  subnets = [
    {
      ip_cidr_range = var.subnet_cidr_block
      name          = "subnet"
      region        = var.region
      secondary_ip_ranges = {
        pods     = var.pods_cidr_block
        services = var.services_cidr_block
      }
    }
  ]
}

module "nat" {
  source         = "../../../modules/net-cloudnat"
  project_id     = module.project.project_id
  region         = var.region
  name           = "${local.prefix}nat"
  router_network = module.vpc.name
}

module "cluster" {
  source     = "../../../modules/gke-cluster"
  project_id = module.project.project_id
  name       = "${local.prefix}cluster"
  location   = var.zone
  vpc_config = {
    master_ipv4_cidr_block = var.master_cidr_block
    network                = module.vpc.self_link
    subnetwork             = module.vpc.subnet_self_links["${var.region}/subnet"]
  }
  private_cluster_config = {
    enable_private_endpoint = false
    master_global_access    = false
  }
}

module "cluster_nodepool" {
  source          = "../../../modules/gke-nodepool"
  project_id      = module.project.project_id
  cluster_name    = module.cluster.name
  location        = var.zone
  name            = "nodepool"
  service_account = {
    email = module.sa.email
    scopes = "https://www.googleapis.com/auth/cloud-platform"
  }
  node_count      = { initial = 3 }
  node_config = {
    machine_type = "e2-standard-4"
  }
  nodepool_config = {
    autoscaling = {
      max_node_count = 10
      min_node_count = 3
    }
  }
}

module "docker_artifact_registry" {
  source     = "../../../modules/artifact-registry"
  project_id = module.project.project_id
  location   = var.region
  format     = "DOCKER"
  id         = "${local.prefix}registry"
  iam = {
  }
}

module "sa" {
  source     = "../../../modules/iam-service-account"
  project_id = module.project.project_id
  name       = "sa-load-test"
}

