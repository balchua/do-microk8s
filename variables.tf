variable "digitalocean_token" {}

variable "digitalocean_ssh_fingerprint" {}

variable "digitalocean_pub_key" {}

variable "digitalocean_private_key" {}

variable "cluster_token" {
    type    = string
    description = "The cluster token to use to join a node.  Must be 32 alphanumeric long." 
}

variable "cluster_token_ttl_seconds" {
    type    = number
    default = 3600
    description = "The cluster token ttl to use when joining a node, default 3600 seconds."
}

variable "node_count" {
  type        = number
  default     = 3
  description = "Number of workers"
}

variable "dns_zone" {
  type        = string
  default     = "geeks.sg"
  description = "Dns for all ingress"
}

variable "os_image" {
    type    = string
    default = "ubuntu-18-04-x64"
    description = "The operating system slug name in Digitalocean."
}

variable "region" {
    type    = string
    default = "sgp1"
    description = "The region where the droplets will be hosted."
}

variable "node_disksize" {
    type    = string
    default = "100"
    description = "The size of the controller storage."
}

variable "node_size" {
    type    = string
    default = "s-4vcpu-8gb"
    description = "The size of the worker droplet."
}

variable "cluster_name" {
  type = string
  default = "cetacean"
}

variable "microk8s_channel" {
  type = string
  default = "stable"
  description = "The MicroK8s channel to use"
}

