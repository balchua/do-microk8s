# Digitalocean Terraform Microk8s

Bootstrap a multi node Microk8s in digitalocean with Terraform.

For example to bootstrap 1 controller and 1 worker.

```yaml

module "microk8s" {
    source = "git::https://github.com/balchua/do-microk8s"
    worker_node_count = "1"
    os_image = "ubuntu-18-04-x64"
    controller_size = "s-4vcpu-8gb"
    region = "sgp1"
    worker_size = "s-4vcpu-8gb"
    digitalocean_ssh_fingerprint = "${var.digitalocean_ssh_fingerprint}"
    digitalocean_private_key = "${var.digitalocean_private_key}"
    digitalocean_token = "${var.digitalocean_token}"
    digitalocean_pub_key = "${var.digitalocean_pub_key}"
}

```
## Digitalocean TF environment variables

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

Login to the `master` node using `ssh root@masterip`, then issue the command below.

```shell

root@microk8s-controller-cetacean:~# microk8s.kubectl get no
NAME                           STATUS   ROLES    AGE   VERSION
10.130.123.80                  Ready    <none>   42s   v1.17.2
microk8s-controller-cetacean   Ready    <none>   67s   v1.17.2
```

