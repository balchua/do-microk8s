/* 

##### Not using this, still need to setup the firewall properly to make linkerd work. #####

resource "digitalocean_firewall" "rules" {
  name = var.cluster_name

  tags = ["microk8s-controller-${var.cluster_name}", "microk8s-worker-${var.cluster_name}"]

  # allow ssh, internal flannel, internal node-exporter, internal kubelet
  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol    = "udp"
    port_range  = "4789"
    source_tags = [digitalocean_tag.microk8s-controller.name, digitalocean_tag.microk8s-worker.name]
  }

  # kubelet - anonymous
  inbound_rule {
    protocol    = "tcp"
    port_range  = "10250"
    source_tags = [digitalocean_tag.microk8s-controller.name, digitalocean_tag.microk8s-worker.name]
  }
  
  # kubelet - readonly port
  inbound_rule {
    protocol    = "tcp"
    port_range  = "10255"
    source_tags = [digitalocean_tag.microk8s-controller.name, digitalocean_tag.microk8s-worker.name]
  }

  # container registry - nodeport
  inbound_rule {
    protocol    = "tcp"
    port_range  = "32000"
    source_tags = [digitalocean_tag.microk8s-controller.name, digitalocean_tag.microk8s-worker.name]
  }

  # containerd metrics - metrics
  inbound_rule {
    protocol    = "tcp"
    port_range  = "1338"
    source_tags = [digitalocean_tag.microk8s-controller.name, digitalocean_tag.microk8s-worker.name]
  }  

  # cluster agent
  inbound_rule {
    protocol    = "tcp"
    port_range  = "25000"
    source_tags = [digitalocean_tag.microk8s-controller.name, digitalocean_tag.microk8s-worker.name]
  }

  # linkerd ports
  inbound_rule {
    protocol         = "tcp"
    port_range       = "8843"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  # linkerd ports
  inbound_rule {
    protocol         = "tcp"
    port_range       = "8089"
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

resource "digitalocean_firewall" "microk8s-controller" {
  name = "microk8s-controllers-${var.cluster_name}"

  tags = ["microk8s-controller-${var.cluster_name}"]

  # etcd
  inbound_rule {
    protocol    = "tcp"
    port_range  = "12379-12380"
    source_tags = [digitalocean_tag.microk8s-controller.name]
  }

  # etcd metrics
  inbound_rule {
    protocol    = "tcp"
    port_range  = "12381"
    source_tags = [digitalocean_tag.microk8s-worker.name]
  }

  # kube-apiserver
  inbound_rule {
    protocol         = "tcp"
    port_range       = "16443"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }
  
  # kube-scheduler Serve HTTPS with authentication and authorization.
  inbound_rule {
    protocol    = "tcp"
    port_range  = "10259"
    source_tags = [digitalocean_tag.microk8s-worker.name]
  }

  # kube-controller Serve HTTPS with authentication and authorization.
  inbound_rule {
    protocol    = "tcp"
    port_range  = "10257"
    source_tags = [digitalocean_tag.microk8s-worker.name]
  }  
}

resource "digitalocean_firewall" "microk8s-worker" {
  name = "microk8s-worker-${var.cluster_name}"

  tags = ["microk8s-worker-${var.cluster_name}"]

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

  inbound_rule {
    protocol         = "tcp"
    port_range       = "10254"
    source_addresses = ["0.0.0.0/0"]
  }
}

*/