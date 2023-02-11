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

module "pubsub" {
  source     = "../../../../modules/pubsub"
  project_id = module.project.project_id
  name       = "apigee-alerts"
}

resource "google_monitoring_notification_channel" "notification_channel" {
  display_name = "Apigee Notification Channel"
  type         = "pubsub"
  project      = module.project.project_id
  labels = {
    topic = module.pubsub.id
  }

}

resource "google_logging_metric" "hc_logging_metric" {
  name   = "apigee-hc"
  filter = <<EOT
logName="projects/${module.project.project_id}/logs/compute.googleapis.com%2Fhealthchecks"
 AND jsonPayload.healthCheckProbeResult.healthState = "UNHEALTHY"
EOT
}

resource "google_monitoring_alert_policy" "alert_policy" {
  display_name = "Apigee uptime failure"
  combiner     = "OR"
  project      = module.project.project_id
  conditions {
    display_name = "Apigee healthcheck"
    condition_threshold {
      aggregations {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_PERCENT_CHANGE"
        cross_series_reducer = "REDUCE_COUNT"
      }
      comparison      = "COMPARISON_GT"
      duration        = "300s"
      filter          = <<EOT
metric.type="logging.googleapis.com/user/${google_logging_metric.hc_logging_metric.id}" 
 AND resource.type="global"
EOT
      threshold_value = 0
      trigger {
        percent = 100
      }
    }
  }
  notification_channels = [
    google_monitoring_notification_channel.notification_channel.name
  ]
}

