# Bash command to populate /etc/hosts file on each instances

resource "null_resource" "provision_node_hosts_file" {
  count = var.node_count
  triggers = {
    rerun = random_id.cluster_token.hex
  }  
  connection {
        host        = element(digitalocean_droplet.microk8s-node.*.ipv4_address, count.index)
        user        = "root"
        type        = "ssh"
        private_key = file(var.digitalocean_private_key)
        timeout     = "2m"
  }  

  provisioner "remote-exec" {
    inline = [
      "echo '${join("\n", formatlist("%v", digitalocean_droplet.microk8s-node.*.ipv4_address_private))}' | awk 'BEGIN{ print \"\\n\\n# Node members:\" }; { print $0 \" microk8s-node-${var.cluster_name}-\"  NR-1}' | sudo tee -a /etc/hosts > /dev/null",
"echo '${join("\n", formatlist("%v", digitalocean_droplet.microk8s-worker-node.*.ipv4_address_private))}' | awk 'BEGIN{ print \"\\n\\n# Worker node members:\" }; { print $0 \" microk8s-worker-${var.cluster_name}-\"  NR-1}' | sudo tee -a /etc/hosts > /dev/null",      
    ]
  }
}


resource "null_resource" "provision_worker_hosts_file" {
  count = var.worker_node_count
  triggers = {
    rerun = random_id.cluster_token.hex
  }  
  connection {
        host        = element(digitalocean_droplet.microk8s-worker-node.*.ipv4_address, count.index)
        user        = "root"
        type        = "ssh"
        private_key = file(var.digitalocean_private_key)
        timeout     = "2m"
  }  

  provisioner "remote-exec" {
    inline = [
      "echo '${join("\n", formatlist("%v", digitalocean_droplet.microk8s-node.*.ipv4_address_private))}' | awk 'BEGIN{ print \"\\n\\n# Node members:\" }; { print $0 \" microk8s-node-${var.cluster_name}-\"  NR-1}' | sudo tee -a /etc/hosts > /dev/null",
      "echo '${join("\n", formatlist("%v", digitalocean_droplet.microk8s-worker-node.*.ipv4_address_private))}' | awk 'BEGIN{ print \"\\n\\n# Worker node members:\" }; { print $0 \" microk8s-worker-${var.cluster_name}-\"  NR-1}' | sudo tee -a /etc/hosts > /dev/null",
    ]
  }
}