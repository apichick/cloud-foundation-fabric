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

locals {
  uptime_checks = merge(flatten([for k1, v1 in local.envgroups :
    { for v2 in v1 : replace(v2, ".", "-") => v2 }
  ])...)
}

module "pubsub" {
  source     = "../../../../modules/pubsub"
  project_id = module.host_project.project_id
  name       = "apigee-alerts"
}

resource "google_monitoring_notification_channel" "pubsub_notification_channel" {
  display_name = "Apigee Notification Channel"
  type         = "pubsub"
  project      = module.host_project.project_id
  labels = {
    topic = module.pubsub.id
  }

}

resource "google_monitoring_notification_channel" "email_notification_channel" {
  display_name = "Apigee Notification Channel"
  type         = "email"
  project      = module.host_project.project_id
  labels = {
    email_address = var.email_address
  }

}

resource "google_monitoring_uptime_check_config" "uptime_checks" {
  for_each     = local.uptime_checks
  display_name = "apigee-uc-${each.key}"
  project      = module.host_project.project_id
  timeout      = "30s"
  period       = "60s"
  http_check {
    path           = "/dummy/ping"
    port           = "443"
    request_method = "GET"
    accepted_response_status_codes {
      status_value = 200
    }
    use_ssl      = true
    validate_ssl = true
  }
  monitored_resource {
    type = "uptime_url"
    labels = {
      host = each.value
    }
  }
  # content_matchers {
  #   content = "Apigee Ingress is ready"
  #   matcher = "CONTAINS_STRING"
  # }

  checker_type = "STATIC_IP_CHECKERS"
}

resource "google_logging_metric" "hc_logging_metric" {
  name    = "apigee-hc"
  project = module.host_project.project_id
  filter  = <<EOT
resource.type="gce_network_endpoint_group"  
 AND logName="projects/${module.host_project.project_id}/logs/compute.googleapis.com%2Fhealthchecks"
 AND jsonPayload.healthCheckProbeResult.healthState = "UNHEALTHY"
EOT
}

resource "google_monitoring_alert_policy" "health_check_alert_policy" {
  display_name = "Apigee health check failure"
  combiner     = "OR"
  project      = module.host_project.project_id
  conditions {
    display_name = "Apigee healthcheck"
    condition_threshold {
      aggregations {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_RATE"
        cross_series_reducer = "REDUCE_SUM"
      }
      comparison      = "COMPARISON_GT"
      duration        = "60s"
      filter          = <<EOT
 metric.type="logging.googleapis.com/user/${google_logging_metric.hc_logging_metric.id}" 
 AND resource.type="gce_network_endpoint_group"
EOT
      threshold_value = 0
      trigger {
        percent = 100
      }
    }
  }
  notification_channels = [
    google_monitoring_notification_channel.pubsub_notification_channel.name,
    google_monitoring_notification_channel.email_notification_channel.name,
  ]
}

resource "google_monitoring_alert_policy" "uptime_check_alert_policy" {
  for_each     = local.uptime_checks
  display_name = "Apigee uptime check failure (${each.value})"
  combiner     = "OR"
  project      = module.host_project.project_id
  conditions {
    display_name = "Apigee healthcheck"
    condition_threshold {
      aggregations {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_NEXT_OLDER"
        cross_series_reducer = "REDUCE_COUNT_FALSE"
      }
      comparison      = "COMPARISON_GT"
      duration        = "600s"
      filter          = <<EOT
metric.type="monitoring.googleapis.com/uptime_check/check_passed"
 AND metric.label.check_id=${google_monitoring_uptime_check_config.uptime_checks[each.key].uptime_check_id}
 AND resource.type="uptime_url"
EOT
      threshold_value = 1
      trigger {
        count = 1
      }
    }
  }
  notification_channels = [
    google_monitoring_notification_channel.pubsub_notification_channel.name,
    google_monitoring_notification_channel.email_notification_channel.name,
  ]
}
