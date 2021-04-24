resource "random_id" "cluster_token" {
  byte_length = 16
}

resource "digitalocean_volume" "microk8s-node" {
  region                  = var.region
  count                   = var.node_count
  name                    = "microk8s-node-fs-${count.index}"
  size                    = var.node_disksize
  description             = "A volume to attach to the worker.  Can be used for Rook Ceph"
}

resource "digitalocean_droplet" "microk8s-node" {
  image              = var.os_image
  name               = "microk8s-node-${var.cluster_name}-${count.index}"
  region             = var.region
  size               = var.node_size
  count              = var.node_count
  private_networking = true

 tags = [
    digitalocean_tag.microk8s-node.id
  ]

  ssh_keys = [
    var.digitalocean_ssh_fingerprint,
  ]
  user_data = element(data.template_file.node_config.*.rendered, count.index)
  volume_ids = [element(digitalocean_volume.microk8s-node.*.id, count.index)]
  
}

# Tag to label nodes
resource "digitalocean_tag" "microk8s-node" {
  name = "microk8s-node-${var.cluster_name}"
}

# node user-config
data "template_file" "node_config" {
  template = file("${path.module}/templates/node.yaml.tmpl")
  vars = {
    microk8s_channel = var.microk8s_channel
  }  
}


resource "null_resource" "setup_tokens" {
    depends_on = [null_resource.provision_node_hosts_file]
    triggers = {
      rerun = random_id.cluster_token.hex
    }
    connection {
        host        = digitalocean_droplet.microk8s-node[0].ipv4_address
        user        = "root"
        type        = "ssh"
        private_key = file(var.digitalocean_private_key)
        timeout     = "2m"
    }

    provisioner "local-exec" {
        interpreter = ["bash", "-c"]
        command = "echo \"1\" > /tmp/current_joining_node.txt"
    }

    provisioner "file" {
        content     = templatefile("${path.module}/templates/add-node.sh", 
            {
                dns_zone = var.dns_zone
                cluster_token = random_id.cluster_token.hex
                cluster_token_ttl_seconds = var.cluster_token_ttl_seconds
            })
        destination = "/usr/local/bin/add-node.sh"
    }

    provisioner "remote-exec" {
        inline = [
            "sh /usr/local/bin/add-node.sh",
            "/snap/bin/microk8s.config -l > /client.config",
            "echo 'updating kubeconfig'; sed -i 's/127.0.0.1:16443/microk8s-cluster.${var.dns_zone}/g' /client.config",
        ]
    }
}


resource "null_resource" "join_nodes" {
    count           = var.node_count - 1 < 1 ? 0 : var.node_count - 1
    depends_on      = [null_resource.setup_tokens]
    triggers = {
      rerun = random_id.cluster_token.hex
    }    
    connection {
        host        = element(digitalocean_droplet.microk8s-node.*.ipv4_address, count.index + 1)
        user        = "root"
        type        = "ssh"
        private_key = file(var.digitalocean_private_key)
        timeout     = "20m"
    }  

    provisioner "local-exec" {
        interpreter = ["bash", "-c"]
        command = "while [[ $(cat /tmp/current_joining_node.txt) != \"${count.index +1}\" ]]; do echo \"${count.index +1} is waiting...\";sleep 5;done"
    }

    provisioner "file" {
        content     = templatefile("${path.module}/templates/join.sh", 
            {
                dns_zone = var.dns_zone
                cluster_token = random_id.cluster_token.hex
                main_node_ip = digitalocean_droplet.microk8s-node[0].ipv4_address_private
            })
        destination = "/usr/local/bin/join.sh"
    }    

    provisioner "remote-exec" {
        inline = [
            "sh /usr/local/bin/join.sh"
        ]
    }

    provisioner "local-exec" {
        interpreter = ["bash", "-c"]
        command = "echo \"${count.index+2}\" > /tmp/current_joining_node.txt"
    }    
}


# Discrete DNS records for each controller's private IPv4 for ingress usage
resource "digitalocean_record" "microk8s-node" {
  count   = var.node_count
  # DNS zone where record should be created
  domain  = var.dns_zone

  # DNS record (will be prepended to domain)
  name    = "microk8s-node-${count.index}"
  type    = "A"
  ttl     = 300

  value = element(digitalocean_droplet.microk8s-node.*.ipv4_address, count.index)
}

resource "null_resource" "get_kubeconfig" {
    depends_on = [null_resource.setup_tokens]    

    provisioner "local-exec" {
        command = "scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${var.digitalocean_private_key}  root@${digitalocean_droplet.microk8s-node[0].ipv4_address}:/client.config /tmp/"
    }
}
