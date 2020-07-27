# Bash command to populate /etc/hosts file on each instances

resource "null_resource" "provision_worker_hosts_file" {
  count = var.worker_node_count
  connection {
        host        = element(digitalocean_droplet.microk8s-worker.*.ipv4_address, count.index)
        user        = "root"
        type        = "ssh"
        private_key = file(var.digitalocean_private_key)
        timeout     = "2m"
  }  

  provisioner "remote-exec" {
    inline = [
      # Adds controlplane private IP addresses to /etc/hosts 
      "echo '${join("\n", formatlist("%v", digitalocean_droplet.microk8s-controller.ipv4_address_private))}' | awk 'BEGIN{ print \"\\n\\n# Controlplane:\" }; { print $0 \" microk8s-controller-${var.cluster_name}\"}' | sudo tee -a /etc/hosts > /dev/null",
      # Adds all nodes members' private IP addresses to /etc/hosts
      "echo '${join("\n", formatlist("%v", digitalocean_droplet.microk8s-worker.*.ipv4_address_private))}' | awk 'BEGIN{ print \"\\n\\n# Node members:\" }; { print $0 \" microk8s-worker-${var.cluster_name}-\"  NR-1}' | sudo tee -a /etc/hosts > /dev/null",
    ]
  }
}

resource "null_resource" "provision_controlplane_hosts_file" {
  count = 1

  connection {
        host        = digitalocean_droplet.microk8s-controller.ipv4_address
        user        = "root"
        type        = "ssh"
        private_key = file(var.digitalocean_private_key)
        timeout     = "2m"
  }  

  provisioner "remote-exec" {
    inline = [
      # Adds controlplane private IP addresses to /etc/hosts 
      "echo '${join("\n", formatlist("%v", digitalocean_droplet.microk8s-controller.ipv4_address_private))}' | awk 'BEGIN{ print \"\\n\\n# Controlplane:\" }; { print $0 \" microk8s-controller-${var.cluster_name}\" }' | sudo tee -a /etc/hosts > /dev/null",
      # Adds all nodes members' private IP addresses to /etc/hosts
      "echo '${join("\n", formatlist("%v", digitalocean_droplet.microk8s-worker.*.ipv4_address_private))}' | awk 'BEGIN{ print \"\\n\\n# Node members:\" }; { print $0 \" microk8s-worker-${var.cluster_name}-\"  NR-1}' | sudo tee -a /etc/hosts > /dev/null",
    ]
  }
}