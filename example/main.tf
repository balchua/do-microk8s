module "microk8s" {
  #source = "git::https://github.com/balchua/do-microk8s"
  source                       = "../"
  worker_node_count            = "4"
  os_image                     = "ubuntu-18-04-x64"
  controller_size              = "s-4vcpu-8gb"
  controller_disksize          = "100"
  worker_disksize              = "100"
  region                       = "sgp1"
  worker_size                  = "s-4vcpu-8gb"
  dns_zone                     = "geeks.sg"
  microk8s_channel             = "latest/edge/ha-preview"
  cluster_token                = "PoiuyTrewQasdfghjklMnbvcxz123409"
  cluster_token_ttl_seconds    = 3600
  digitalocean_ssh_fingerprint = var.digitalocean_ssh_fingerprint
  digitalocean_private_key     = var.digitalocean_private_key
  digitalocean_token           = var.digitalocean_token
  digitalocean_pub_key         = var.digitalocean_pub_key
}

