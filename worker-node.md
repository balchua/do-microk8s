# Add a worker node only with MicroK8s

This document describes the steps on how to join a worker node only into your Highly Available MicroK8s.  This has the main advantage that, you can avoid the resource overhead of the control plane.  The overhead can go up to GBs and several CPU cycles.  These cycles are best allocated to your workload instead of Kubernetes.

Before you begin, you need to have the following in place:

* An HA cluster, example 3 node HA MicroK8s cluster
* Load balancer to front the apiserver.

##  Setup a 3 node HA MicroK8s 

Follow the instructions in MicroK8s [documentation](https://microk8s.io/docs/high-availability).

## Load balancer IP

On each of your HA MicroK8s node, add the load balancer IP into the file `/var/snap/microk8s/current/certs/cs.conf.template`

For example:

```
[ req ]
default_bits = 2048
prompt = no
default_md = sha256
req_extensions = req_ext
distinguished_name = dn

[ dn ]
C = GB
ST = Canonical
L = Canonical
O = Canonical
OU = Canonical
CN = 127.0.0.1

[ req_ext ]
subjectAltName = @alt_names

[ alt_names ]
DNS.1 = kubernetes
DNS.2 = kubernetes.default
DNS.3 = kubernetes.default.svc
DNS.4 = kubernetes.default.svc.cluster
DNS.5 = kubernetes.default.svc.cluster.local
IP.1 = 127.0.0.1
IP.2 = 10.152.183.1
IP.99 = 167.172.5.46
#MOREIPS

[ v3_ext ]
authorityKeyIdentifier=keyid,issuer:always
basicConstraints=CA:FALSE
keyUsage=keyEncipherment,dataEncipherment,digitalSignature
extendedKeyUsage=serverAuth,clientAuth
subjectAltName=@alt_names

```
Note that **IP.99 = 167.172.5.46** is the Load balancer IP

## Install MicroK8s

On your worker node, install MicroK8s like usual.

```
snap install microk8s --classic --channel 1.20/stable
```

### Stopping the services

You need to stop all the services on this worker node.

```
systemctl stop snap.microk8s.daemon-apiserver
systemctl stop snap.microk8s.daemon-apiserver-kicker.service 
systemctl stop snap.microk8s.daemon-controller-manager.service 
systemctl stop snap.microk8s.daemon-control-plane-kicker.service 
systemctl stop snap.microk8s.daemon-scheduler.service 
systemctl stop snap.microk8s.daemon-kubelet.service 
systemctl stop snap.microk8s.daemon-proxy.service
```

### Token generation and known_tokens

On each worker node run the following:

Example:

```
# openssl rand -base64 32 | base64
KzVIdjBkUWFNYStQc01xb09lMXM1VEFRUVAxSHIxQ3I5UHk5bjZiSVdidz0K
```
_Keep the generated random string._

On each of your **control plane** nodes:

Edit the file `/var/snap/microk8s/current/credentials/known_tokens.csv` to add the kubelet and kube-proxy tokens:

```
KzVIdjBkUWFNYStQc01xb09lMXM1VEFRUVAxSHIxQ3I5UHk5bjZiSVdidz0K,system:kube-proxy,kube-proxy
KzVIdjBkUWFNYStQc01xb09lMXM1VEFRUVAxSHIxQ3I5UHk5bjZiSVdidz0K,system:node:worker-1,kubelet-1,"system:nodes"
```

Restart each control plane api server.

`systemctl restart snap.microk8s.daemon-apiserver`

### Copy certificates to the worker node

```console
scp root@controlplanenode:/var/snap/microk8s/current/certs/ca.crt /tmp/ca.crt
scp root@controlplanenode:/var/snap/microk8s/current/credentials/kubelet.config /tmp/kubelet.config
scp root@controlplanenode:/var/snap/microk8s/current/credentials/proxy.config /tmp/proxy.config

#copy the files to the worker nodes
scp /tmp/ca.crt root@workernode:/var/snap/microk8s/current/certs/ca.crt
scp /tmp/kubelet.config root@workernode:/var/snap/microk8s/current/credentials/kubelet.config
scp /tmp/proxy.config root@workernode:/var/snap/microk8s/current/credentials/proxy.config

```

### Modify the config tokens

Before starting the kubelet and proxy, you need to modify the token located in `/var/snap/microk8s/current/credentials/kubelet.config` and `/var/snap/microk8s/current/credentials/proxy.config`.

As an example:

```yaml
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURBVENDQWVtZ0F3SUJBZ0lKQUpGcnFTaDNvTThWTUEwR0NTcUdTSWIzRFFFQkN3VUFNQmN4RlRBVEJnTlYKQkFNTURERXdMakUxTWk0eE9ETXVNVEFlRncweU1UQXlNVEl3TVRBME5ERmFGdzB6TVRBeU1UQXdNVEEwTkRGYQpNQmN4RlRBVEJnTlZCQU1NRERFd0xqRTFNaTR4T0RNdU1UQ0NBU0l3RFFZSktvWklodmNOQVFFQkJRQURnZ0VQCkFEQ0NBUW9DZ2dFQkFONTh6V2JlODdPK0FDUE9sbnlJVnlUWU0zaHZDTWQ0VGNucnVQcFllVHhwSzlLT1o5djEKc0pYeWNZejBEQ293TThnUEcydlRSRWI5UHg2OU0zZmhWV053Z0hMLzhUZnlKTkxpZUE1SmhtMXcrMUdOQkxvSgpkOEdXTE1LaDcwK1JWQlNzblhLSXRxUTY0aFhoZVVZV1J3QW1IU0ZCL3ZkL1B4ZWwvelN6M3loRXA0YXlhbjhMCjVVUEVpL0tkWVdwK0dJTWpJSzROQmEzMW9oVlYwQnBlLzlzTGdlNEcyNzM0em50NjdZSS9seWg4LzR1UnpuZnEKTndHRVdEeDhlV1ZWNjMrUWltNmIzRklUdG5nS0Y3UUlaV2hXN0xzMlZ2aGkrMGp1RFFSRmZNY1JYaXJpZ3lCMwoxNURzWnAwMFFzb3VQTHVPRGRlbE9waVdQR1hvUzlMSmJpY0NBd0VBQWFOUU1FNHdIUVlEVlIwT0JCWUVGSnBRCnlEaGJGK3hnSDJOL216ZjdQanpvNDdzak1COEdBMVVkSXdRWU1CYUFGSnBReURoYkYreGdIMk4vbXpmN1Bqem8KNDdzak1Bd0dBMVVkRXdRRk1BTUJBZjh3RFFZSktvWklodmNOQVFFTEJRQURnZ0VCQUZ3SDNvOU9hUnQ0NDlNdQppRUxBenRKQVE1ZHhjSWM2STBUdkhvVVBYOWwvemJRQ3hPQ3ExT1Z4a2M0TXRHTXA3TktlMDZ2UWFVSzAzVnhTCm5yMktYeFdwckVxNGFTMUdHc21vOEVDQUtZOEpUVXpjUkNBa0lNcjBPcHlWM0RKc3NXNWVHRGVvaVJESGY1RnAKc3d3VUZ4REVSWFFlb0ZNV1FDYWJMQTNzdVl0enBQZVdWLzJQeHVsbEJMaXBseFhEMk8wcllLUHVzT0FTeDk1MApVSnRTMmwzTFpENXRoTUM2eG1LT2FYSDNhT0FLWjNZMEhVWUN6VGhPaUdLMXV6cDFIcjI5LzRweUQrbGVVeHNyCkZWMDZYZ1JESStYNFZTaWNVYVEzeG16U1EyYm1qVVFNc3RTdytId0VaR2tRTS9OZ1BqaURxZ2tqbHhoVDJndmQKWnFLMFhZRT0KLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo=
    server: https://your-load-balancer-ip
  name: microk8s-cluster
contexts:
- context:
    cluster: microk8s-cluster
    user: kubelet
  name: microk8s
current-context: microk8s
kind: Config
preferences: {}
users:
- name: kubelet
  user:
    token: KzVIdjBkUWFNYStQc01xb09lMXM1VEFRUVAxSHIxQ3I5UHk5bjZiSVdidz0K
```
### Additional Kubelet configuration

When enabling the DNS,  you need to start the worker node's kubelet with these additional arguments/parameters.

From the file `/var/snap/microk8s/current/args/kubelet`  add at the bottom of the file the following.

```
--cluster-domain=cluster.local
--cluster-dns=10.152.183.10
```


### Start the kubelet and proxy

In each of the worker node

```
systemctl start snap.microk8s.daemon-kubelet.service
systemctl start snap.microk8s.daemon-proxy.service
```

## Check the cluster

From one of the master node.

Cordon off the control plane nodes.

`microk8s kubectl cordon microk8s-worker-cetacean-1 microk8s-worker-cetacean-0 microk8s-controller-cetacean`


```console
# microk8s kubectl get no -o wide
NAME                           STATUS                     ROLES    AGE     VERSION                     INTERNAL-IP      EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION     CONTAINER-RUNTIME
microk8s-worker-cetacean-1     Ready,SchedulingDisabled   <none>   5h58m   v1.20.2-34+350770ed07a558   159.65.3.0       <none>        Ubuntu 20.04.1 LTS   5.4.0-51-generic   containerd://1.3.7
microk8s-controller-cetacean   Ready,SchedulingDisabled   <none>   6h23m   v1.20.2-34+350770ed07a558   159.65.11.73     <none>        Ubuntu 20.04.1 LTS   5.4.0-51-generic   containerd://1.3.7
worker-1                       Ready                      <none>   3h23m   v1.20.2-34+350770ed07a558   188.166.212.46   <none>        Ubuntu 20.04.1 LTS   5.4.0-51-generic   containerd://1.3.7
microk8s-worker-cetacean-0     Ready,SchedulingDisabled   <none>   6h      v1.20.2-34+350770ed07a558   159.65.3.42      <none>        Ubuntu 20.04.1 LTS   5.4.0-51-generic   containerd://1.3.7
worker-0                       Ready                      <none>   4h42m   v1.20.2-34+350770ed07a558   178.128.24.42    <none>        Ubuntu 20.04.1 LTS   5.4.0-51-generic   containerd://1.3.7
```

Below shows the utilization of kubelet and kube-proxy.  Running on a 1 CPU and 2 GB VM.  As you can see, the node is very much dedicated to your workloads and not kubernetes.

![Utilization](docs/assets/worker-1.png)

