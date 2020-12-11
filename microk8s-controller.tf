resource "digitalocean_volume" "microk8s-controller" {
  region                  = var.region
  name                    = "microk8s-controller-fs"
  count                   = "1"
  size                    = var.controller_disksize
  description             = "A volume to attach to the controller.  Can be used for Rook Ceph"
}

resource "digitalocean_droplet" "microk8s-controller" {
  image              = var.os_image
  name               = "microk8s-controller-${var.cluster_name}"
  region             = var.region
  size               = var.controller_size
  private_networking = true

  ssh_keys = [
    var.digitalocean_ssh_fingerprint,
  ]

  tags = [
    digitalocean_tag.microk8s-controller.id, digitalocean_tag.microk8s-controlplane.id
  ]

  user_data = data.template_file.controller_node_config.rendered

  volume_ids = [element(digitalocean_volume.microk8s-controller.*.id, 1)]
}


# Tag to label control plane
resource "digitalocean_tag" "microk8s-controlplane" {
  name = "microk8s-controlplane-${var.cluster_name}"
}


# Tag to label controllers
resource "digitalocean_tag" "microk8s-controller" {
  name = "microk8s-controller-${var.cluster_name}"
}

# controller node user-config
data "template_file" "controller_node_config" {
  template = file("${path.module}/templates/master.yaml.tmpl")
  vars = {
    microk8s_channel = var.microk8s_channel
  }
}

resource "null_resource" "setup_tokens" {
    depends_on = [null_resource.provision_controlplane_hosts_file, null_resource.provision_worker_hosts_file]    
    connection {
        host        = digitalocean_droplet.microk8s-controller.ipv4_address
        user        = "root"
        type        = "ssh"
        private_key = file(var.digitalocean_private_key)
        timeout     = "2m"
    }      

    provisioner "remote-exec" {
        inline = [
            "until /snap/bin/microk8s.status --wait-ready; do sleep 1; echo \"waiting for status..\"; done",
            "echo 'adding microk8s-cluster.${var.dns_zone} dns to CSR.'; sed -i 's@#MOREIPS@DNS.99 = microk8s-cluster.${var.dns_zone}\\n#MOREIPS\\n@g' /var/snap/microk8s/current/certs/csr.conf.template; echo 'done.'",
            "sleep 10",
            #"while true; do READY=$(/snap/bin/microk8s kubectl get no | grep \"NotReady\" | wc -l); if [ $READY -gt 0 ]; then  echo \"Waiting for node to be ready.\"; sleep 2; else break; fi done;",
            "/snap/bin/microk8s.add-node --token \"${var.cluster_token}\" --token-ttl ${var.cluster_token_ttl_seconds}",
            "/snap/bin/microk8s.config -l > /client.config",
            "echo 'updating kubeconfig'; sed -i 's/127.0.0.1:16443/microk8s-cluster.${var.dns_zone}/g' /client.config",
        ]
    }
}


resource "null_resource" "get_kubeconfig" {
    depends_on = [null_resource.setup_tokens]    

    provisioner "local-exec" {
        command = "scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${var.digitalocean_private_key}  root@${digitalocean_droplet.microk8s-controller.ipv4_address}:/client.config /tmp/"
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
  value = digitalocean_droplet.microk8s-controller.ipv4_address
}


