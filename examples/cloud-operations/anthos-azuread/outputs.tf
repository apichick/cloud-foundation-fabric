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

output "config" {
  description = "Configuration to use in Anthos"
  value       = <<EOT
  spec:
    authentication:
      - name: oidc-azuread
        oidc:
          clientID: ${azuread_application_password.application_password.application_object_id}
          clientSecret: ${azuread_application_password.application_password.value}
          cloudConsoleRedirectURI: ${local.console_redirect_uri}
          extraParams: prompt=consent, access_type=offline
          issuerURI: https://login.microsoftonline.com/${var.tenant_id}/v2.0
          kubectlRedirectURI: ${local.cli_redirect_uri}
          scopes: openid,email,offline_access
          userClaim: email
  EOT  
  sensitive = true
}
