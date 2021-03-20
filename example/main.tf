module "microk8s" {
  #source = "git::https://github.com/balchua/do-microk8s?ref=v0.1.0"
  source                       = "../"
  node_count                   = "7"
  os_image                     = "ubuntu-20-04-x64"
  node_size                    = "s-2vcpu-4gb"
  node_disksize                = "2"
  region                       = "sgp1"
  dns_zone                     = "geeks.sg"
  microk8s_channel             = "latest/edge"
  cluster_token                = "PoiuyTrewQasdfghjklMnbvcxz123409"
  cluster_token_ttl_seconds    = 3600
  digitalocean_ssh_fingerprint = var.digitalocean_ssh_fingerprint
  digitalocean_private_key     = var.digitalocean_private_key
  digitalocean_token           = var.digitalocean_token
  digitalocean_pub_key         = var.digitalocean_pub_key
}

