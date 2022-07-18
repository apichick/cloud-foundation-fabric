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
  app_role_ids = ["User.Read.All", "Group.Read.All"]
  console_redirect_uri = "https://console.cloud.google.com/kubernetes/oidc"
  cli_redirect_uri = "http://localhost:1025/callback"
}

data "azuread_application_published_app_ids" "well_known" {}

resource "azuread_service_principal" "msgraph" {
  application_id = data.azuread_application_published_app_ids.well_known.result.MicrosoftGraph
  use_existing   = true
}

resource "azuread_application" "application" {
  display_name = "Anthos"
  required_resource_access {
    resource_app_id = data.azuread_application_published_app_ids.well_known.result.MicrosoftGraph

    dynamic "resource_access" {
      for_each = toset(local.app_role_ids)
      content {
        id   = azuread_service_principal.msgraph.app_role_ids[resource_access.value]
        type = "Role"
      }
    }
  }
  web {
    redirect_uris = [
      local.console_redirect_uri,
      local.cli_redirect_uri
    ]
  }
}

resource "azuread_application_password" "application_password" {
  application_object_id = azuread_application.application.object_id
}

resource "azuread_service_principal" "service_principal" {
  application_id               = azuread_application.application.application_id
}

resource "azuread_app_role_assignment" "app_role_assignments" {
  for_each            = toset(local.app_role_ids)
  app_role_id         = azuread_service_principal.msgraph.app_role_ids[each.value]
  principal_object_id = azuread_service_principal.service_principal.object_id
  resource_object_id  = azuread_service_principal.msgraph.object_id
}

