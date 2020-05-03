resource "digitalocean_volume" "microk8s-worker" {
  region                  = "${var.region}"
  count                   = "${var.worker_node_count}"
  name                    = "microk8s-worker-fs-${count.index}"
  size                    = "${var.worker_disksize}"
  description             = "A volume to attach to the worker.  Can be used for Rook Ceph"
}

resource "digitalocean_droplet" "microk8s-worker" {
  image              = "${var.os_image}"
  name               = "microk8s-worker-${var.cluster_name}-${count.index}"
  region             = "${var.region}"
  size               = "${var.worker_size}"
  count              = "${var.worker_node_count}"
  private_networking = true

 tags = [
    digitalocean_tag.microk8s-worker.id,
  ]

  ssh_keys = [
    var.digitalocean_ssh_fingerprint,
  ]
  user_data = element(data.template_file.worker_node_config.*.rendered, count.index)
  volume_ids = ["${element(digitalocean_volume.microk8s-worker.*.id, count.index)}"]
  
}

# Tag to label controllers
resource "digitalocean_tag" "microk8s-worker" {
  name = "microk8s-worker-${var.cluster_name}"
}

# master node user-config
data "template_file" "worker_node_config" {
  template = file("${path.module}/templates/worker.yaml.tmpl")
  vars = {
    microk8s_channel = "${var.microk8s_channel}"
  }  
}


resource "null_resource" "join_nodes" {
    count           = "${var.worker_node_count}"
    depends_on      = [null_resource.setup_tokens]
    connection {
        host        = "${element(digitalocean_droplet.microk8s-worker.*.ipv4_address, count.index)}"
        user        = "root"
        type        = "ssh"
        private_key = file(var.digitalocean_private_key)
        timeout     = "10m"
    }      

    provisioner "remote-exec" {
        inline = [
            "until /snap/bin/microk8s.status --wait-ready; do sleep 1; echo \"waiting for worker status..\"; done",
            "/snap/bin/microk8s.join ${digitalocean_droplet.microk8s-controller.ipv4_address_private}:25000/${var.cluster_token}",
            "until /snap/bin/microk8s.status --wait-ready; do sleep 1; echo \"waiting for worker status..\"; done",
            "/snap/bin/microk8s.kubectl label node ${digitalocean_droplet.microk8s-controller.ipv4_address_private} node-role.kubernetes.io/worker=worker",
        ]
    }
}


# Discrete DNS records for each controller's private IPv4 for ingress usage
resource "digitalocean_record" "microk8s-worker" {
  count           = "${var.worker_node_count}"
  # DNS zone where record should be created
  domain = var.dns_zone

  # DNS record (will be prepended to domain)
  name = "microk8s-worker-${count.index}"
  type = "A"
  ttl  = 300

  value = element(digitalocean_droplet.microk8s-worker.*.ipv4_address, count.index)
}