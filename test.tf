module "private-dns" {
  source     = "./fabric/modules/dns"
  project_id = "myproject"
  type       = "forwarding"
  name       = "test-example"
  zone_config = {
    domain          = "test.example."
    client_networks = [var.vpc.self_link]
  }
  forwarders = { "10.0.1.1" = null, "1.2.3.4" = "private" }
}
