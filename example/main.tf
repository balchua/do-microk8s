module "microk8s" {
  #source = "git::https://github.com/balchua/do-microk8s"
  source                       = "../"
  worker_node_count            = "2"
  os_image                     = "ubuntu-20-04-x64"
  controller_size              = "s-2vcpu-4gb"
  controller_disksize          = "10"
  worker_disksize              = "10"
  region                       = "sgp1"
  worker_size                  = "s-2vcpu-4gb"
  dns_zone                     = "geeks.sg"
  microk8s_channel             = "latest/edge"
  cluster_token                = "PoiuyTrewQasdfghjklMnbvcxz123409"
  cluster_token_ttl_seconds    = 3600
  digitalocean_ssh_fingerprint = var.digitalocean_ssh_fingerprint
  digitalocean_private_key     = var.digitalocean_private_key
  digitalocean_token           = var.digitalocean_token
  digitalocean_pub_key         = var.digitalocean_pub_key
}

