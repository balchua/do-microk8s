terraform {
  required_version = "~> 0.14"
  required_providers {
    template = "~> 2.2"
    null     = "~> 3.1"

    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.7.0"
    }
  }
 
}