# DigitalOcean Terraform MicroK8s

**This currently works for `1.19+` channel.**

**Use only with terraform v0.14**

Bootstrap a Highly Available MicroK8s cluster in DigitalOcean with Terraform.

For example to bootstrap a 7 node cluster.

```hcl

module "microk8s" {
  source                       = "git::https://github.com/balchua/do-microk8s?ref=master"
  node_count                   = "7"
  os_image                     = "ubuntu-20-04-x64"
  node_size                    = "s-4vcpu-8gb"
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

```

| Fields                        | Description                              | Default values |
| ----------------------------- |:-----------------------------------------| -------------- |
| source                        | The source of the terraform module       | none
| node_count                    | The number of MicroK8s nodes to create   | 3
| os_image                      | DigitalOcean OS images.  <br/>To get the list OS images `doctl compute image list-distribution`| ubuntu-18-04-x64
| node_size                     | DigitalOcean droptlet sizes <br/> To get the list of droplet sizes `doctl compute size list`| s-4vcpu-8gb
| node_disksize                 | Additional volume to add to the droplet.  Size in GB| 100 |
| region                        | DigitalOcean region <br/> To get the list of regions `doctl compute region list`| sgp1
| dns_zone                      | The DNS zone representing your site.  Need to register your domain. | geeks.sg
| microk8s_channel              | Specify the MicroK8s channel to use.  Refer [here](https://snapcraft.io/microk8s)| stable
| cluster_token                 | The bootstrap token to use when joining nodes together, must be 32 alphanumeric characters long.| none
| cluster_token_ttl_seconds     | How long the token validity (in seconds)| 3600
| digitalocean_ssh_fingerprint  | Your DigitalOcean SSH fingerprint to use, so you can seemlessly `ssh` into your nodes| Refer to `TF` environment variables
| digitalocean_private_key      | The private key location to use when connecting to your droplets| Refer to `TF` environment variables
| digitalocean_token            | Your DigitalOcean token| Refer to `TF` environment variables
| digitalocean_pub_key          | The public key to use to connect to the droplet| Refer to `TF` environment variables


## DigitalOcean TF environment variables

You must have these environment variables present.

```shell

TF_VAR_digitalocean_token=<your DO access token>
TF_VAR_digitalocean_ssh_fingerprint=<Your private key fingerprint>
TF_VAR_digitalocean_private_key=<location of your private key>
TF_VAR_digitalocean_pub_key=<location of your public key>

```

## Creating the cluster

Simply run the `terraform plan` and then `terraform apply`

Once terraform completes, you should be able to see the cluster.

Login to one of the node using `ssh root@node`, then issue the command below.

```shell

root@microk8s-node-cetacean-0:~# microk8s kubectl get no
NAME                       STATUS   ROLES    AGE     VERSION
microk8s-node-cetacean-0   Ready    <none>   6m36s   v1.20.4-38+85035ca77e3c6e
microk8s-node-cetacean-2   Ready    <none>   4m33s   v1.20.4-38+85035ca77e3c6e
microk8s-node-cetacean-6   Ready    <none>   4m47s   v1.20.4-38+85035ca77e3c6e
microk8s-node-cetacean-5   Ready    <none>   4m21s   v1.20.4-38+85035ca77e3c6e
microk8s-node-cetacean-4   Ready    <none>   4m15s   v1.20.4-38+85035ca77e3c6e
microk8s-node-cetacean-3   Ready    <none>   4m12s   v1.20.4-38+85035ca77e3c6e
microk8s-node-cetacean-1   Ready    <none>   4m6s    v1.20.4-38+85035ca77e3c6e

```

## Downloading Kube config file

The module automatically downloads the kubeconfig file to your local machine in `/tmp/client.config`
In order to access the Kubernetes cluster from your local machine, simple do `export KUBECONFIG=/tmp/client.config`

This will connect using the load balancer fronting the api servers.  The dns entry will be `microk8s-cluster.<domain name>`

Example:
`microk8s-cluster.geeks.sg`

## MicroK8s High Availability
It requires node counts to be greater than or equal to 3 to form a majority.  Each node can be a control plane, hence there is really no concept of control plane.

Check documentation on [MicroK8s Discuss HA](https://discuss.kubernetes.io/t/high-availability-ha/11731)


## Digitalocean attached volume

This terraform also creates and attach a volume to each droplet.  This will let you setup Rook + Ceph storage.  This way you can freely create volumes that you can share to your pods.

# Persistent Volumes

The following sections describes how to install Rook/Ceph, Longhorn and OpenEBS with MicroK8s

## Using Rook / Ceph

Some instructions on how to use [Rook](docs/rook.md)

## Using Longhorn storage

Some instructions on how to use [Longhorn](docs/longhorn.md)

## Using OpenEBS

Instructions on how to install [OpenEBS](docs/openebs.md)

## Worker node only node

If you want to create a worker node only node, refer to these [instructions](docs/worker-node.md)