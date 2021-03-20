##### Not using this, still need to setup the firewall properly to make linkerd work. #####
resource "digitalocean_firewall" "rules" {
  name = "microk8s-cluster-firewall-${var.cluster_name}"

  tags = [digitalocean_tag.microk8s-node.id]


  # allow ssh from anywhere
  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

 # allow nodes to contact each other
  inbound_rule {
    protocol    = "tcp"
    port_range  = "1-65535"
    source_tags = [digitalocean_tag.microk8s-node.id]
  }

   # allow nodes to contact each other
  inbound_rule {
    protocol    = "udp"
    port_range  = "1-65535"
    source_tags = [digitalocean_tag.microk8s-node.id]
  }

  # allow HTTP/HTTPS ingress from load balancer
  inbound_rule {
    protocol         = "tcp"
    port_range       = "16443"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  # allow HTTP/HTTPS ingress
  inbound_rule {
    protocol         = "tcp"
    port_range       = "80"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "443"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  # allow all outbound traffic
  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "udp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "icmp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

}


