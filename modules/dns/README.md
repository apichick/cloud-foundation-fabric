# Google Cloud DNS Module

This module allows simple management of Google Cloud DNS zones and records. It supports creating public, private, forwarding, peering, service directory and reverse-managed based zones. To create inbound/outbound server policies, please have a look at the [net-vpc](../net-vpc/README.md) module.

For DNSSEC configuration, refer to the [`dns_managed_zone` documentation](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/dns_managed_zone#dnssec_config).

## Examples

### Private Zone

```hcl
module "private-dns" {
  source          = "./fabric/modules/dns"
  project_id      = "myproject"
  type            = "private"
  name            = "test-example"
  zone_config     = {
    domain          = "test.example."
    client_networks = [var.vpc.self_link]
  }
  recordsets = {
    "A localhost" = { records = ["127.0.0.1"] }
    "A myhost"    = { ttl = 600, records = ["10.0.0.120"] }
  }
  iam = {
    "roles/dns.admin" = ["group:dns-administrators@myorg.com"]
  }
}
# tftest modules=1 resources=4 inventory=private-zone.yaml
```

### Forwarding Zone

```hcl
module "private-dns" {
  source          = "./fabric/modules/dns"
  project_id      = "myproject"
  type            = "forwarding"
  name            = "test-example"
  zone_config     = {
    domain          = "test.example."
    client_networks = [var.vpc.self_link]
  }
  forwarders      = { "10.0.1.1" = null, "1.2.3.4" = "private" }
}
# tftest modules=1 resources=1 inventory=forwarding-zone.yaml
```

### Peering Zone

```hcl
module "private-dns" {
  source          = "./fabric/modules/dns"
  project_id      = "myproject"
  type            = "peering"
  name            = "test-example"
  zone_config     = {
    domain          = "."
    client_networks = [var.vpc.self_link]
  }
  description     = "Forwarding zone for ."
  peer_network    = var.vpc2.self_link
}
# tftest modules=1 resources=1 inventory=peering-zone.yaml
```

### Routing Policies

```hcl
module "private-dns" {
  source          = "./fabric/modules/dns"
  project_id      = "myproject"
  type            = "private"
  name            = "test-example"
  zone_config     = {
    domain          = "test.example."
    client_networks = [var.vpc.self_link]
  }
  recordsets = {
    "A regular" = { records = ["10.20.0.1"] }
    "A geo" = {
      geo_routing = [
        { location = "europe-west1", records = ["10.0.0.1"] },
        { location = "europe-west2", records = ["10.0.0.2"] },
        { location = "europe-west3", records = ["10.0.0.3"] }
      ]
    }

    "A wrr" = {
      ttl = 600
      wrr_routing = [
        { weight = 0.6, records = ["10.10.0.1"] },
        { weight = 0.2, records = ["10.10.0.2"] },
        { weight = 0.2, records = ["10.10.0.3"] }
      ]
    }
  }
}
# tftest modules=1 resources=4 inventory=routing-policies.yaml
```

### Reverse Lookup Zone

```hcl
module "private-dns" {
  source          = "./fabric/modules/dns"
  project_id      = "myproject"
  type            = "reverse-managed"
  name            = "test-example"
  zone_config = {
    domain          = "0.0.10.in-addr.arpa."
    client_networks = [var.vpc.self_link]
  }
}
# tftest modules=1 resources=1 inventory=reverse-zone.yaml
```

### Public Zone

```hcl
module "public-dns" {
  source      = "./fabric/modules/dns"
  project_id  = "myproject"
  type        = "public"
  name        = "example"
  zone_config = {
    domain = "example.com."
  }
  recordsets = {
    "A myhost" = { ttl = 300, records = ["127.0.0.1"] }
  }
  iam = {
    "roles/dns.admin" = ["group:dns-administrators@myorg.com"]
  }
}
# tftest modules=1 resources=4 inventory=public-zone.yaml
```

### Add records to an existing zone

```hcl
module "public-dns" {
  source      = "./fabric/modules/dns"
  project_id  = "myproject"
  type        = "public"
  name        = "example"
  recordsets = {
    "A myhost" = { ttl = 300, records = ["127.0.0.1"] }
  }
}
# tftest modules=1 resources=1 inventory=records.yaml
```
<!-- BEGIN TFDOC -->

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [name](variables.tf#L66) | Zone name, must be unique within the project. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L71) | Project id for the zone. | <code>string</code> | ✓ |  |
| [description](variables.tf#L21) | Domain description. | <code>string</code> |  | <code>&#34;Terraform managed.&#34;</code> |
| [dnssec_config](variables.tf#L27) | DNSSEC configuration for this zone. | <code title="object&#40;&#123;&#10;  non_existence &#61; optional&#40;string, &#34;nsec3&#34;&#41;&#10;  state         &#61; string&#10;  key_signing_key &#61; optional&#40;object&#40;&#10;    &#123; algorithm &#61; string, key_length &#61; number &#125;&#41;,&#10;    &#123; algorithm &#61; &#34;rsasha256&#34;, key_length &#61; 2048 &#125;&#10;  &#41;&#10;  zone_signing_key &#61; optional&#40;object&#40;&#10;    &#123; algorithm &#61; string, key_length &#61; number &#125;&#41;,&#10;    &#123; algorithm &#61; &#34;rsasha256&#34;, key_length &#61; 1024 &#125;&#10;  &#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  state &#61; &#34;off&#34;&#10;&#125;">&#123;&#8230;&#125;</code> |
| [enable_logging](variables.tf#L47) | Enable query logging for this zone. | <code>bool</code> |  | <code>false</code> |
| [forwarders](variables.tf#L54) | Map of {IPV4_ADDRESS => FORWARDING_PATH} for 'forwarding' zone types. Path can be 'default', 'private', or null for provider default. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam](variables.tf#L60) | IAM bindings in {ROLE => [MEMBERS]} format. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>null</code> |
| [recordsets](variables.tf#L76) | Map of DNS recordsets in \"type name\" => {ttl, [records]} format. | <code title="map&#40;object&#40;&#123;&#10;  ttl     &#61; optional&#40;number, 300&#41;&#10;  records &#61; optional&#40;list&#40;string&#41;&#41;&#10;  geo_routing &#61; optional&#40;list&#40;object&#40;&#123;&#10;    location &#61; string&#10;    records  &#61; list&#40;string&#41;&#10;  &#125;&#41;&#41;&#41;&#10;  wrr_routing &#61; optional&#40;list&#40;object&#40;&#123;&#10;    weight  &#61; number&#10;    records &#61; list&#40;string&#41;&#10;  &#125;&#41;&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [service_directory_namespace](variables.tf#L111) | Service directory namespace id (URL), only valid for 'service-directory' zone types. | <code>string</code> |  | <code>null</code> |
| [type](variables.tf#L117) | Type of zone to create, valid values are 'public', 'private', 'forwarding', 'peering', 'service-directory','reverse-managed'. | <code>string</code> |  | <code>&#34;private&#34;</code> |
| [zone_config](variables.tf#L127) | Configuration of the zone. | <code title="object&#40;&#123;&#10;  domain &#61; string&#10;  client_networks &#61; optional&#40;list&#40;string&#41;&#41;&#10;  peer_network &#61; optional&#40;string&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [dns_keys](outputs.tf#L17) | DNSKEY and DS records of DNSSEC-signed managed zones. |  |
| [domain](outputs.tf#L22) | The DNS zone domain. |  |
| [id](outputs.tf#L27) | Fully qualified zone id. |  |
| [name](outputs.tf#L32) | The DNS zone name. |  |
| [name_servers](outputs.tf#L37) | The DNS zone name servers. |  |
| [type](outputs.tf#L42) | The DNS zone type. |  |
| [zone](outputs.tf#L47) | DNS zone resource. |  |

<!-- END TFDOC -->
