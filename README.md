# DigitalOcean Terraform MicroK8s

**This currently works for `latest/edge/ha-preview` channel, HA is still in Preview mode.**

Bootstrap a Highly Available MicroK8s cluster in DigitalOcean with Terraform.

For example to bootstrap 1 main node and 1 worker.

```hcl

module "microk8s" {
  source = "git::https://github.com/balchua/do-microk8s"
  worker_node_count            = "2"
  os_image                     = "ubuntu-18-04-x64"
  controller_size              = "s-4vcpu-8gb"
  controller_disksize          = "50"
  worker_disksize              = "50"
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

```

**The `cluster_token` must be 32 alphanumeric characters long.**

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

Login to the `controller` node using `ssh root@controller`, then issue the command below.

```shell

root@microk8s-controller-cetacean:~# microk8s.kubectl get no
NAME                           STATUS   ROLES    AGE     VERSION
microk8s-controller-cetacean   Ready    <none>   4m14s   v1.18.6-33+f8f2b0e0649c65
microk8s-worker-cetacean-0     Ready    <none>   2m7s    v1.18.6-33+f8f2b0e0649c65
microk8s-worker-cetacean-1     Ready    <none>   2m4s    v1.18.6-33+f8f2b0e0649c65

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

Rook manifests are located in the [Rook Manifests](rook/cephfs/) directory.

In order to install rook, you need to perform the following:

On Master node, make sure that the kubernetes API Server allows privileged pods.

Go to the directory `/var/snap/microk8s/current/args`, check the file `kube-apiserver`.

Add `--allow-privileged=true` argument, sample below

```shell
--cert-dir=${SNAP_DATA}/certs
--service-cluster-ip-range=10.152.183.0/24
--authorization-mode=RBAC,Node
--basic-auth-file=${SNAP_DATA}/credentials/basic_auth.csv
--service-account-key-file=${SNAP_DATA}/certs/serviceaccount.key
--client-ca-file=${SNAP_DATA}/certs/ca.crt
--tls-cert-file=${SNAP_DATA}/certs/server.crt
--tls-private-key-file=${SNAP_DATA}/certs/server.key
--kubelet-client-certificate=${SNAP_DATA}/certs/server.crt
--kubelet-client-key=${SNAP_DATA}/certs/server.key
--secure-port=16443
--token-auth-file=${SNAP_DATA}/credentials/known_tokens.csv
--token-auth-file=${SNAP_DATA}/credentials/known_tokens.csv
--etcd-servers='https://127.0.0.1:12379'
--etcd-cafile=${SNAP_DATA}/certs/ca.crt
--etcd-certfile=${SNAP_DATA}/certs/server.crt
--etcd-keyfile=${SNAP_DATA}/certs/server.key
--insecure-port=0
--allow-privileged=true
```

```shell
kubectl apply -f rook/common.yaml
kubectl apply -f rook/operator.yaml

# Wait for the rook operator to become available
kubectl -n rook-ceph get pods
NAME                                                              READY   STATUS      RESTARTS   AGE
rook-ceph-operator-5c8c896d6c-889l7                               1/1     Running     5          32m
rook-discover-9cw89                                               1/1     Running     0          28m
rook-discover-wnzzf                                               1/1     Running     0          28m
rook-discover-wqc4p                                               1/1     Running     0          28m
```

Once you have these pods up and running, you can now start to create the `CephCluster`.

Creating the `CephCluster`, apply the [cluster.yaml](rook/cluster.yaml)

`kubectl apply -f rook/cluster.yaml`

Once you apply that manifest, you should see these pods in the `rook-ceph` namespace.

```shell
NAME                                                              READY   STATUS      RESTARTS   AGE
csi-cephfsplugin-bmtcb                                            3/3     Running     0          34m
csi-cephfsplugin-nlrkd                                            3/3     Running     0          34m
csi-cephfsplugin-provisioner-7b8fbf88b4-j8w5p                     4/4     Running     0          34m
csi-cephfsplugin-provisioner-7b8fbf88b4-rk4qd                     4/4     Running     0          34m
csi-cephfsplugin-zml4q                                            3/3     Running     0          34m
csi-rbdplugin-7fx5j                                               3/3     Running     0          34m
csi-rbdplugin-cbms4                                               3/3     Running     0          34m
csi-rbdplugin-provisioner-6b8b4d558c-6jfbh                        5/5     Running     0          34m
csi-rbdplugin-provisioner-6b8b4d558c-rtlqq                        5/5     Running     0          34m
csi-rbdplugin-t6s26                                               3/3     Running     0          34m
rook-ceph-crashcollector-10.130.17.47-f9b4496bf-sgnlt             1/1     Running     0          32m
rook-ceph-crashcollector-10.130.40.90-f8c7d77dc-vr49j             1/1     Running     0          29m
rook-ceph-crashcollector-microk8s-controller-cetacean-6c894kbbc   1/1     Running     0          29m
rook-ceph-mds-myfs-a-777bf8ffcb-fktwl                             1/1     Running     0          29m
rook-ceph-mds-myfs-b-84fd995775-dlwsl                             1/1     Running     0          29m
rook-ceph-mgr-a-589d8f9d64-n5qql                                  1/1     Running     0          33m
rook-ceph-mon-a-58689c7ffd-l8bbc                                  1/1     Running     0          33m
rook-ceph-operator-5c8c896d6c-889l7                               1/1     Running     5          39m
rook-ceph-osd-0-6b659fdc47-fqzm7                                  1/1     Running     0          32m
rook-ceph-osd-1-7bfbc46cff-46v8c                                  1/1     Running     0          32m
rook-ceph-osd-2-79695c7d56-tsk9t                                  1/1     Running     0          32m
rook-ceph-osd-prepare-10.130.17.47-c5lk9                          0/1     Completed   0          32m
rook-ceph-osd-prepare-10.130.40.90-ttgbr                          0/1     Completed   0          32m
rook-ceph-osd-prepare-microk8s-controller-cetacean-nl9qx          0/1     Completed   0          32m
rook-discover-9cw89                                               1/1     Running     0          35m
rook-discover-wnzzf                                               1/1     Running     0          35m
rook-discover-wqc4p                                               1/1     Running     0          35m
```

Now that you have the `CephCluster` up and running, you can now start to create your own filesystem on top of ceph.

The following example below will create a `CephFileSystem`.

```shell

kubectl apply -f rook/cephfs/myfs.yaml
kubectl apply -f rook/cephfs/storageclass.yaml
kubectl apply -f rook/cephfs/pvc.yaml
```

Finally you can now create a pod which can make use of the Ceph file system using the standard Kubernetes `PersistentVolumeClaim`


