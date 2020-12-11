terraform {
  required_version = "~> 0.14"
  required_providers {
    template = "~> 2.1"
    null     = "~> 2.1"

    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 1.22"
    }
  }
 
}