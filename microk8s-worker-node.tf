resource "digitalocean_volume" "microk8s-worker-node" {
  region                  = var.region
  count                   = var.node_count
  name                    = "microk8s-worker-fs-${count.index}"
  size                    = var.worker_node_disksize
  description             = "A volume to attach to the worker"
}

resource "digitalocean_droplet" "microk8s-worker-node" {
  image              = var.os_image
  name               = "microk8s-worker-${var.cluster_name}-${count.index}"
  region             = var.region
  size               = var.worker_node_size
  count              = var.worker_node_count
  private_networking = true

 tags = [
    digitalocean_tag.microk8s-worker.id
  ]

  ssh_keys = [
    var.digitalocean_ssh_fingerprint,
  ]
  user_data = element(data.template_file.node_config.*.rendered, count.index)
  volume_ids = [element(digitalocean_volume.microk8s-worker-node.*.id, count.index)]
  
}

# Tag to label nodes
resource "digitalocean_tag" "microk8s-worker" {
  name = "microk8s-worker-${var.cluster_name}"
}


resource "null_resource" "join_workers" {
    count           = var.worker_node_count
    depends_on      = [null_resource.setup_tokens]
    triggers = {
      rerun = random_id.cluster_token.hex
    }    
    connection {
        host        = element(digitalocean_droplet.microk8s-worker-node.*.ipv4_address, count.index)
        user        = "root"
        type        = "ssh"
        private_key = file(var.digitalocean_private_key)
        timeout     = "20m"
    }  

    provisioner "local-exec" {
        interpreter = ["bash", "-c"]
        command = "while [[ $(cat /tmp/current_joining_worker_node.txt) != \"${count.index}\" ]]; do echo \"${count.index} is waiting...\";sleep 5;done"
    }

    provisioner "file" {
        content     = templatefile("${path.module}/templates/join-worker.sh", 
            {
                dns_zone = var.dns_zone
                cluster_token = random_id.cluster_token.hex
                main_node_ip = digitalocean_droplet.microk8s-node[0].ipv4_address_private
            })
        destination = "/usr/local/bin/join-worker.sh"
    }    

    provisioner "remote-exec" {
        inline = [
            "sh /usr/local/bin/join-worker.sh"
        ]
    }

    provisioner "local-exec" {
        interpreter = ["bash", "-c"]
        command = "echo \"${count.index+1}\" > /tmp/current_joining_worker_node.txt"
    }    
}

# Discrete DNS records for each controller's private IPv4 for ingress usage
resource "digitalocean_record" "microk8s-worker-node" {
  count   = var.worker_node_count
  # DNS zone where record should be created
  domain  = var.dns_zone

  # DNS record (will be prepended to domain)
  name    = "microk8s-worker-worker-node-${count.index}"
  type    = "A"
  ttl     = 300

  value = element(digitalocean_droplet.microk8s-worker-node.*.ipv4_address, count.index)
}
