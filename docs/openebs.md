# Using OpenEBS

**If you are using MicroK8s v1.21+, OpenEBS is included as an addon**

Pre-requisites:

* `iscsi-client` must be installed on every node.
  
  Verify if the client is installed.  
  More information from [OpenEBS site](https://docs.openebs.io/docs/next/prerequisites.html#ubuntu)
  
  ```console
  sudo cat /etc/iscsi/initiatorname.iscsi | grep InitiatorName
  sudo systemctl is-enabled iscsid | grep enabled
  ```

  If it is not active, run `sudo systemctl enable iscsid`.

* If going to use **cStor** or **Jiva**, one must have a free Block device available.
  
Steps:

* Enable rbac `microk8s enable rbac`
* Enable dns `microk8s enable dns`
* Enable helm3 `microk8s enable helm3`
* Create `openebs` namespace
  
  ```console
  $ microk8s kubectl create ns openebs

  ```
* Add `openebs` chart repository

```console
$ microk8s helm3 repo add openebs https://openebs.github.io/charts
$ microk8s helm3 repo update
$ microk8s helm3 -n openebs install openebs openebs/openebs \
    --set varDirectoryPath.baseDir="/var/snap/microk8s/common/var/openebs/" \
    --set jiva.defaultStoragePath="/var/snap/microk8s/common/var/openebs/"
```

* Verify OpenEBS

```console

$ microk8s kubectl -n openebs get pods

NAME                                          READY   STATUS    RESTARTS   AGE
openebs-ndm-qz42t                             1/1     Running   0          53s
openebs-ndm-bzdgb                             1/1     Running   0          53s
openebs-ndm-hbp56                             1/1     Running   0          53s
openebs-localpv-provisioner-d9786794d-28g7n   1/1     Running   0          53s
openebs-admission-server-79f9f888d7-rwlqx     1/1     Running   0          53s
openebs-ndm-operator-55d7c755d5-28jvx         1/1     Running   0          53s
openebs-apiserver-59d979b7f6-jwvw8            1/1     Running   2          53s
openebs-snapshot-operator-7b886dccdb-gx8bj    2/2     Running   0          53s
openebs-provisioner-694bd9755c-hswtd          1/1     Running   0          53s

```

You should see that each `ndm` is available on each node.

Check the `StorageClass`

```console
$ microk8s kubectl get sc
NAME                        PROVISIONER                                                RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
openebs-jiva-default        openebs.io/provisioner-iscsi                               Delete          Immediate              false                  5m27s
openebs-snapshot-promoter   volumesnapshot.external-storage.k8s.io/snapshot-promoter   Delete          Immediate              false                  5m26s
openebs-hostpath            openebs.io/local                                           Delete          WaitForFirstConsumer   false                  5m26s
openebs-device              openebs.io/local                                           Delete          WaitForFirstConsumer   false                  5m26s
```
## Create custom StorageClass

```
cat <<EOF | microk8s kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: openebs-jiva-microk8s
  annotations:
    openebs.io/cas-type: jiva
    cas.openebs.io/config: |
      - name: ReplicaCount
        value: "1"
      - name: StoragePool
        value: default
provisioner: openebs.io/provisioner-iscsi
EOF
```

Create the PersistentVolumeClaim

```
cat <<EOF | microk8s kubectl apply -f -
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: demo-vol1-claim
spec:
  storageClassName: openebs-jiva-microk8s
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5G
EOF
```

## Use the default StorageClass

Create a PersistentVolumeClaim using the default Jiva, make sure you have 3 nodes available in the cluster.  Otherwise it will not be able to mount the volumve to your pod.

```
cat <<EOF | microk8s kubectl apply -f -
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: demo-vol1-claim
spec:
  storageClassName: openebs-jiva-default
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5G
EOF
```


### Test the persistent volume

Using busybox, let us see if we can mount the volume to the pod.

```console
$ cat <<EOF | microk8s kubectl apply -f - 

apiVersion: apps/v1
kind: Deployment
metadata:
 name: busybox
 labels:
   app: busybox
spec:
 replicas: 1
 strategy:
   type: RollingUpdate
 selector:
   matchLabels:
     app: busybox
 template:
   metadata:
     labels:
       app: busybox
   spec:
     containers:
     - resources:
          limits:
           cpu: 0.5
       name: busybox
       image: busybox
       command: ['sh', '-c', 'echo Container 1 is Running ; sleep 3600']
       imagePullPolicy: IfNotPresent
       ports:
        - containerPort: 3306
          name: busybox
       volumeMounts:
       - mountPath: /my-data
         name: demo-vol1
     volumes:
      - name: demo-vol1
        persistentVolumeClaim:
         claimName: demo-vol1-claim
EOF
```

Check if the pod is up.

```console
microk8s kubectl get pod
NAME                      READY   STATUS    RESTARTS   AGE
busybox-b4ff57999-v7v7v   1/1     Running   0          41s

```

Go inside the pod

```
$ microk8s kubectl exec -it busybox-b4ff57999-v7v7v -- sh

/ # df -h
Filesystem                Size      Used Available Use% Mounted on
overlay                 154.9G      3.4G    151.5G   2% /
tmpfs                    64.0M         0     64.0M   0% /dev
tmpfs                     3.9G         0      3.9G   0% /sys/fs/cgroup
/dev/sdb                  4.9G     20.0M      4.8G   0% /my-data
/dev/vda1               154.9G      3.4G    151.5G   2% /etc/hosts
/dev/vda1               154.9G      3.4G    151.5G   2% /dev/termination-log
/dev/vda1               154.9G      3.4G    151.5G   2% /etc/hostname
/dev/vda1               154.9G      3.4G    151.5G   2% /etc/resolv.conf
shm                      64.0M         0     64.0M   0% /dev/shm
tmpfs                     3.9G     12.0K      3.9G   0% /var/run/secrets/kubernetes.io/serviceaccount
tmpfs                     3.9G         0      3.9G   0% /proc/acpi
tmpfs                    64.0M         0     64.0M   0% /proc/kcore
tmpfs                    64.0M         0     64.0M   0% /proc/keys
tmpfs                    64.0M         0     64.0M   0% /proc/timer_list
tmpfs                    64.0M         0     64.0M   0% /proc/sched_debug
tmpfs                     3.9G         0      3.9G   0% /proc/scsi
tmpfs                     3.9G         0      3.9G   0% /sys/firmware

```

You should see the `/my-data` directory.

Write a file into the `/my-data`.

```
echo "hello" > /my-data/test.txt
/ # ls -l /my-data/test.txt 
-rw-r--r--    1 root     root             6 Mar  6 02:36 /my-data/test.txt
/ # cat /my-data/test.txt 
hello
```

Verify that it survives a pod deletion.

```console
$ microk8s kubectl delete po busybox-b4ff57999-v7v7v 
pod "busybox-b4ff57999-v7v7v" deleted
$ microk8s kubectl exec -it busybox-b4ff57999-n5r6v -- sh
/ # cat /my-data/
lost+found/  test.txt
/ # cat /my-data/
lost+found/  test.txt
/ # cat /my-data/test.txt 
hello
/ # 
```

As you can see the data is still there.

#### Set default storage class

```
microk8s kubectl patch storageclass openebs-jiva-default -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```

# Use real disk with cStor
// TODO

## Setting up cStor Storage Engine

### Check BlockDevices

Verify that OpenEBS detects block devices.

```console
# microk8s kubectl get blockdevices -n openebs
NAME                                           NODENAME                       SIZE          CLAIMSTATE   STATUS   AGE
blockdevice-ad86896ae637c8a127778e7406f548ad   microk8s-controller-cetacean   10737418240   Unclaimed    Active   2m1s
blockdevice-b96c2231fbff89065c890d3e835ac536   microk8s-worker-cetacean-0     10737418240   Unclaimed    Active   2m1s
blockdevice-dce08466dd122734cd053548a9ad1efb   microk8s-worker-cetacean-1     10737418240   Unclaimed    Active   2m1s
```

These are the block devices that cStor can use.  OpenEBS can find all unused block devices.

### Create StoragePool

Block devices must be manually listed in the `StoragePoolClaim`

```console

cat <<EOF | microk8s kubectl apply -f -
#Use the following YAMLs to create a cStor Storage Pool.
apiVersion: openebs.io/v1alpha1
kind: StoragePoolClaim
metadata:
  name: cstor-disk-pool
  annotations:
    cas.openebs.io/config: |
      - name: PoolResourceRequests
        value: |-
            memory: 2Gi
      - name: PoolResourceLimits
        value: |-
            memory: 4Gi
spec:
  name: cstor-disk-pool
  type: disk
  poolSpec:
    poolType: striped
  blockDevices:
    blockDeviceList:
    - blockdevice-ad86896ae637c8a127778e7406f548ad
    - blockdevice-b96c2231fbff89065c890d3e835ac536
    - blockdevice-dce08466dd122734cd053548a9ad1efb
---
EOF
```

# Uninstalling

Follow the steps in (https://docs.openebs.io/docs/next/uninstall.html)

microk8s helm3 uninstall -n openebs openebs

```
microk8s kubectl delete validatingwebhookconfigurations  openebs-validation-webhook-cfg
microk8s kubectl delete crd castemplates.openebs.io
microk8s kubectl delete crd cstorpools.openebs.io
microk8s kubectl delete crd cstorpoolinstances.openebs.io
microk8s kubectl delete crd cstorvolumeclaims.openebs.io
microk8s kubectl delete crd cstorvolumereplicas.openebs.io
microk8s kubectl delete crd cstorvolumepolicies.openebs.io
microk8s kubectl delete crd cstorvolumes.openebs.io
microk8s kubectl delete crd runtasks.openebs.io
microk8s kubectl delete crd storagepoolclaims.openebs.io
microk8s kubectl delete crd storagepools.openebs.io
microk8s kubectl delete crd volumesnapshotdatas.volumesnapshot.external-storage.k8s.io
microk8s kubectl delete crd volumesnapshots.volumesnapshot.external-storage.k8s.io
microk8s kubectl delete crd blockdevices.openebs.io
microk8s kubectl delete crd blockdeviceclaims.openebs.io
microk8s kubectl delete crd cstorbackups.openebs.io
microk8s kubectl delete crd cstorrestores.openebs.io
microk8s kubectl delete crd cstorcompletedbackups.openebs.io
microk8s kubectl delete crd upgradetasks.openebs.io
microk8s kubectl delete crd cstorpoolclusters.cstor.openebs.io
microk8s kubectl delete crd cstorpoolinstances.cstor.openebs.io
microk8s kubectl delete crd cstorvolumeattachments.cstor.openebs.io
microk8s kubectl delete crd cstorvolumeconfigs.cstor.openebs.io
microk8s kubectl delete crd cstorvolumepolicies.cstor.openebs.io
microk8s kubectl delete crd cstorvolumereplicas.cstor.openebs.io
microk8s kubectl delete crd cstorvolumes.cstor.openebs.io
```
