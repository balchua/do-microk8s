terraform {
  required_providers {
    template = "~> 2.2"
    null     = "~> 3.1"

    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.7.0"
    }
    random = {
      source = "hashicorp/random"
      version = "~>3.1.0"
    }
  }
 
}