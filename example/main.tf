module "microk8s" {
  #source = "git::https://github.com/balchua/do-microk8s?ref=v0.1.0"
  source                       = "../"
  cluster_name                 = "hades"
  node_count                   = "3"
  worker_node_count            = "2"
  os_image                     = "ubuntu-20-04-x64"
  node_size                    = "s-2vcpu-4gb"
  worker_node_size             = "s-4vcpu-8gb"
  node_disksize                = "30"
  region                       = "sgp1"
  dns_zone                     = "geeks.sg"
  microk8s_channel             = "latest/stable"
  cluster_token_ttl_seconds    = 3600
  digitalocean_ssh_fingerprint = var.digitalocean_ssh_fingerprint
  digitalocean_private_key     = var.digitalocean_private_key
  digitalocean_token           = var.digitalocean_token
  digitalocean_pub_key         = var.digitalocean_pub_key
}

