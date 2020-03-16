variable "digitalocean_token" {}

variable "digitalocean_ssh_fingerprint" {}

variable "digitalocean_pub_key" {}

variable "digitalocean_private_key" {}

variable "cluster-token" {
    type    = "string"
    default = "VSF6JF49IPOZCXR6KEN6"
    description = "The cluster token to use to join a node."
}

variable "worker_node_count" {
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
    type    = "string"
    default = "ubuntu-18-04-x64"
    description = "The operating system slug name in Digitalocean."
}

variable "region" {
    type    = "string"
    default = "sgp1"
    description = "The region where the droplets will be hosted."
}

variable "controller_size" {
    type    = "string"
    default = "s-4vcpu-8gb"
    description = "The size of the controller droplet."
}

variable "controller_disksize" {
    type    = "string"
    default = "100"
    description = "The size of the controller storage."
}

variable "worker_size" {
    type    = "string"
    default = "s-4vcpu-8gb"
    description = "The size of the worker droplet."
}

variable "worker_disksize" {
    type    = "string"
    default = "100"
    description = "The size of the worker storage."
}

variable "cluster_name" {
  type = "string"
  default = "cetacean"
}

variable "microk8s_channel" {
  type = "string"
  default = "stable"
  description = "The MicroK8s channel to use"
}

