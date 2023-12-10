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

resource "tls_private_key" "private_keys" {
  for_each  = toset(var.ssl_certificates.self_signed_configs)
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "certs" {
  for_each        = toset(var.ssl_certificates.self_signed_configs)
  private_key_pem = tls_private_key.private_keys[each.value].private_key_pem
  subject {
    common_name = each.value
  }
  validity_period_hours = 525600
  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

resource "google_compute_region_ssl_certificate" "self_signed" {
  for_each    = toset(var.ssl_certificates.self_signed_configs)
  project     = var.project_id
  region      = var.region
  name        = "${var.name}-${replace(each.key, ".", "-")}"
  certificate = tls_self_signed_cert.certs[each.value].cert_pem
  private_key = tls_private_key.private_keys[each.value].private_key_pem

  lifecycle {
    create_before_destroy = true
  }
}
