resource "digitalocean_loadbalancer" "microk8s-lb" {
  name   = "microk8s-lb-${var.cluster_name}"
  region = var.region

  forwarding_rule {
    entry_port = 443
    entry_protocol = "https"

    target_port = 16443
    target_protocol = "https"

    tls_passthrough = true

  }

  healthcheck {
    port = 16443
    protocol = "tcp"
  }

  droplet_tag = digitalocean_tag.microk8s-node.id
}

resource "digitalocean_record" "microk8s-cluster" {
  # DNS zone where record should be created
  domain = var.dns_zone

  # DNS record (will be prepended to domain)
  name = "microk8s-cluster"
  type = "A"
  ttl  = 300

  value = digitalocean_loadbalancer.microk8s-lb.ip
}