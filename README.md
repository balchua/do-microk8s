# DigitalOcean Terraform MicroK8s

**This currently works for `1.19+` channel.**

**Use only with terraform v0.14**

Bootstrap a Highly Available MicroK8s cluster in DigitalOcean with Terraform.

For example to bootstrap 1 main node and 1 worker.

```hcl

module "microk8s" {
  source = "git::https://github.com/balchua/do-microk8s?ref=v0.1.0"
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


# Using Longhorn storage

_[Longhorn](https://longhorn.io/docs/1.0.2/what-is-longhorn/) is a lightweight, reliable and easy-to-use distributed block storage system for Kubernetes._

## Pre-requisites

1.  https://longhorn.io/docs/1.0.2/deploy/install/#installation-requirements
2.  Core dns addon 
3.  Helm3 addon
4.  Ingress addon


## Steps: 

_Instructions taken from Longhorn [site](https://longhorn.io/docs/1.0.2/deploy/install/install-with-helm/)._  Tailored with MicroK8s addons.

1. Enable dns addon

```
microk8s enable dns
```

2. Enable helm3 addon

```
microk8s enable helm3
```

3. Add longhorn helm repo 

```
microk8s helm3 repo add longhorn https://charts.longhorn.io
```

4. Helm update

```
microk8s helm3 repo update
```

5. Install Longhorn

```
microk8s kubectl create namespace longhorn-system
microk8s helm3 install longhorn longhorn/longhorn --namespace longhorn-system --set defaultSettings.defaultDataPath="/data-disk/longhorn"
```

6.  Check all pods are `Running`

```
microk8s kubectl -n longhorn-system get pods -A

NAME                                        READY   STATUS    RESTARTS   AGE   IP           NODE                           NOMINATED NODE   READINESS GATES
instance-manager-e-32b33e77                 1/1     Running   0          46m   10.1.39.5    microk8s-worker-cetacean-0     <none>           <none>
instance-manager-r-0d98aaf2                 1/1     Running   0          46m   10.1.39.6    microk8s-worker-cetacean-0     <none>           <none>
engine-image-ei-ee18f965-d2vjd              1/1     Running   0          46m   10.1.39.4    microk8s-worker-cetacean-0     <none>           <none>
engine-image-ei-ee18f965-58hsg              1/1     Running   0          46m   10.1.7.67    microk8s-controller-cetacean   <none>           <none>
longhorn-manager-9m49w                      1/1     Running   0          47m   10.1.39.3    microk8s-worker-cetacean-0     <none>           <none>
longhorn-manager-mvtcp                      1/1     Running   0          47m   10.1.7.66    microk8s-controller-cetacean   <none>           <none>
longhorn-manager-nxqjn                      1/1     Running   2          47m   10.1.98.65   microk8s-worker-cetacean-1     <none>           <none>
engine-image-ei-ee18f965-9zvlf              1/1     Running   0          46m   10.1.98.66   microk8s-worker-cetacean-1     <none>           <none>
instance-manager-e-8130572b                 1/1     Running   0          30m   10.1.98.70   microk8s-worker-cetacean-1     <none>           <none>
instance-manager-r-0b9655bc                 1/1     Running   0          30m   10.1.98.71   microk8s-worker-cetacean-1     <none>           <none>
instance-manager-r-361e6769                 1/1     Running   0          29m   10.1.7.70    microk8s-controller-cetacean   <none>           <none>
instance-manager-e-bc17fd46                 1/1     Running   0          29m   10.1.7.71    microk8s-controller-cetacean   <none>           <none>
longhorn-driver-deployer-658fdf45cc-8sf8r   1/1     Running   0          27m   10.1.7.72    microk8s-controller-cetacean   <none>           <none>
csi-attacher-79d88c7c98-7p9h2               1/1     Running   0          27m   10.1.39.7    microk8s-worker-cetacean-0     <none>           <none>
csi-attacher-79d88c7c98-8xbnn               1/1     Running   0          27m   10.1.98.73   microk8s-worker-cetacean-1     <none>           <none>
csi-attacher-79d88c7c98-xlw7j               1/1     Running   0          27m   10.1.7.73    microk8s-controller-cetacean   <none>           <none>
longhorn-csi-plugin-cqlqm                   2/2     Running   0          27m   10.1.98.74   microk8s-worker-cetacean-1     <none>           <none>
csi-resizer-d8487b59-rrxkl                  1/1     Running   0          27m   10.1.39.8    microk8s-worker-cetacean-0     <none>           <none>
csi-provisioner-5749f9cd4f-22gck            1/1     Running   0          27m   10.1.7.74    microk8s-controller-cetacean   <none>           <none>
csi-provisioner-5749f9cd4f-hrgnn            1/1     Running   0          27m   10.1.98.75   microk8s-worker-cetacean-1     <none>           <none>
longhorn-csi-plugin-6phhz                   2/2     Running   0          27m   10.1.39.9    microk8s-worker-cetacean-0     <none>           <none>
csi-resizer-d8487b59-z24rk                  1/1     Running   0          27m   10.1.7.75    microk8s-controller-cetacean   <none>           <none>
csi-resizer-d8487b59-8wwxd                  1/1     Running   0          27m   10.1.98.76   microk8s-worker-cetacean-1     <none>           <none>
csi-provisioner-5749f9cd4f-ccmwx            1/1     Running   0          27m   10.1.39.10   microk8s-worker-cetacean-0     <none>           <none>
longhorn-csi-plugin-cd4mx                   2/2     Running   0          27m   10.1.7.76    microk8s-controller-cetacean   <none>           <none>
longhorn-ui-7788d4f485-9649z                1/1     Running   0          26m   10.1.39.11   microk8s-worker-cetacean-0     <none>           <none>

```
7.  Enable Ingress addon

```
microk8s enable ingress
```

8.  Install Ingress Resource

```
cat <<EOF | microk8s kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: longhorn
  namespace: longhorn-system
spec:
  rules:
  - host: longhorn-ui.geeks.sg
    http:
      paths:
        - path: /
          pathType: Prefix
          backend:
            service:
              name: longhorn-frontend
              port:
                number: 80
EOF
```

9. Access the Longhorn UI.

**Please note that this do not have Authentication in place.**

Go to your browser and access `http://longhorn-ui.geeks.sg` or whatever you have in your ingress.

![Screenshot](docs/assets/longhorn-ui.png)


10. Install sample pod using the longhorn PV

```
cat <<EOF | microk8s kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: longhorn-volv-pvc
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: longhorn
  resources:
    requests:
      storage: 10Gi
---
apiVersion: v1
kind: Pod
metadata:
  name: security-context-demo
spec:
  securityContext:
    runAsUser: 1000
    runAsGroup: 3000
    fsGroup: 2000
  containers:
  - name: sec-ctx-demo
    image: busybox
    command: [ "sh", "-c", "sleep 10h" ]
    livenessProbe:
      exec:
        command:
          - ls
          - /data/lost+found
      initialDelaySeconds: 5
      periodSeconds: 5
    volumeMounts:
    - name: volv
      mountPath: /data
    ports:
    - containerPort: 80
  volumes:
  - name: volv
    persistentVolumeClaim:
      claimName: longhorn-volv-pvc    
    securityContext:
      allowPrivilegeEscalation: false      
EOF
```

11. Create files inside the pod

```
$ microk8s kubectl get pods -o wide
NAME          READY   STATUS    RESTARTS   AGE     IP           NODE                         NOMINATED NODE   READINESS GATES
volume-test   1/1     Running   0          2m56s   10.1.39.13   microk8s-worker-cetacean-0   <none>           <none>

$ microk8s kubectl exec -it volume-test -- sh
/ # cd /data
/data # pwd
/data
/data # ls -l
total 16
drwx------    2 root     root         16384 Dec 11 08:20 lost+found
/data # echo "Hello" > my-file.txt
/data # cat /data/my-file.txt 
Hello
/data # 
```

## Backup to Digitalocean Spaces

Digitalocean Spaces is an S3 compatible object store.

1.  Create `Secret` which contains the DigitalOcean Spaces


```
cat <<EOF | kubectl apply -f -
# same secret for longhorn-system namespace
apiVersion: v1
kind: Secret
metadata:
  name: spaces-secret
  namespace: longhorn-system
type: Opaque
data:
  AWS_ACCESS_KEY_ID: `echo -n $DO_SPACES_ACCESS_KEY | base64 -w 0` # longhorn-test-access-key
  AWS_SECRET_ACCESS_KEY: `echo -n $DO_SPACES_SECRET_KEY | base64 -w 0`
  AWS_ENDPOINTS: `echo -n "https://nyc3.digitaloceanspaces.com/" | base64 -w 0`
  VIRTUAL_HOSTED_STYLE: dHJ1ZQ== # true
EOF
```

2. Setup in `General>Settings`

![Backup Settings](docs/assets/longhorn-backup-settings.png)

3. Create Backup

![Backup Volume](docs/assets/longhorn-backup-volume.png)