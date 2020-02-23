resource "digitalocean_droplet" "microk8s-controller" {
  image              = "${var.os_image}"
  name               = "microk8s-controller-${var.cluster_name}"
  region             = "${var.region}"
  size               = "${var.controller_size}"
  private_networking = true

  ssh_keys = [
    var.digitalocean_ssh_fingerprint,
  ]

  tags = [
    digitalocean_tag.microk8s-controller.id,
  ]

  user_data = data.template_file.controller_node_config.rendered

}

# Tag to label controllers
resource "digitalocean_tag" "microk8s-controller" {
  name = "microk8s-controller-${var.cluster_name}"
}

# controller node user-config
data "template_file" "controller_node_config" {
  template = file("${path.module}/templates/master.yaml.tmpl")
}

resource "null_resource" "setup_tokens" {
    count = "${var.worker_node_count}"
    connection {
        host        = "${digitalocean_droplet.microk8s-controller.ipv4_address}"
        user        = "root"
        type        = "ssh"
        private_key = file(var.digitalocean_private_key)
        timeout     = "2m"
    }      

    provisioner "remote-exec" {
        inline = [
            "until /snap/bin/microk8s.status --wait-ready; do sleep 1; echo \"waiting for status..\"; done",
            "touch /var/snap/microk8s/current/credentials/cluster-tokens.txt",
            "echo \"${var.cluster-token}\"-\"${count.index}\" >> /var/snap/microk8s/current/credentials/cluster-tokens.txt",
              
        ]
    }
}


resource "null_resource" "get_kubeconfig" {
    depends_on = [null_resource.setup_tokens]    

    provisioner "local-exec" {
        command = "scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${var.digitalocean_private_key}  root@${digitalocean_droplet.microk8s-controller.ipv4_address}:/var/snap/microk8s/current/credentials/client.config /tmp/"
    }
}

# Discrete DNS records for each controller's private IPv4 for etcd usage
resource "digitalocean_record" "microk8s-controller" {
  # DNS zone where record should be created
  domain = var.dns_zone

  # DNS record (will be prepended to domain)
  name = "microk8s-controller-${var.cluster_name}"
  type = "A"
  ttl  = 300

  # private IPv4 address for etcd
  value = "${digitalocean_droplet.microk8s-controller.ipv4_address}"
}