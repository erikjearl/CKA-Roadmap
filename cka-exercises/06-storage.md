# Storage

> **New/deeper vs CKAD:** cluster-side storage — StorageClasses, dynamic provisioning, CSI, volume expansion, and reclaim policies/access modes (lighter in CKAD).

## Quick Reference — Documentation
kubernetes.io > Documentation > Concepts > Storage > [Persistent Volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)
kubernetes.io > Documentation > Concepts > Storage > [Storage Classes](https://kubernetes.io/docs/concepts/storage/storage-classes/)

---

### Create a PersistentVolume (hostPath) and a matching PVC, and confirm they Bind  `(med)`
<details><summary>show</summary>
<p>

```bash
# Create a hostPath PersistentVolume.
# storageClassName: "" disables the default StorageClass so the static PV/PVC pair binds directly
# without interference from a cluster-level default provisioner.
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-hostpath
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Delete
  storageClassName: ""
  hostPath:
    path: /mnt/data
    type: DirectoryOrCreate
EOF

# Create a matching PVC.
# storageClassName, accessModes, and requested storage must align with the PV for static binding.
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-hostpath
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: ""
EOF
```

```bash
# verify
# STATUS should be Bound; VOLUME should show pv-hostpath
kubectl get pvc pvc-hostpath
kubectl get pv pv-hostpath
```

</p>
</details>

---

### Create a StorageClass and a PVC that dynamically provisions a PV  `(med)`
<details><summary>show</summary>
<p>

```bash
# Create a StorageClass backed by the local-path provisioner.
# Note: requires rancher.io/local-path-provisioner to be installed in the cluster.
# It ships as the default provisioner in k3s and common CKA lab environments (e.g. Killer Shell).
# For kubeadm clusters, install it first:
#   kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml
kubectl apply -f - <<EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: local-path-sc
provisioner: rancher.io/local-path
volumeBindingMode: WaitForFirstConsumer
reclaimPolicy: Delete
EOF

# Create a PVC that references the StorageClass — the provisioner creates the backing PV on demand.
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-dynamic
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: local-path-sc
  resources:
    requests:
      storage: 500Mi
EOF
```

```bash
# verify
# With WaitForFirstConsumer, STATUS stays Pending until a pod mounts the PVC.
# Create a consumer pod to trigger binding:
kubectl run pvc-consumer --image=busybox:1.36 --restart=Never \
  --overrides='{
    "spec": {
      "volumes": [{"name":"data","persistentVolumeClaim":{"claimName":"pvc-dynamic"}}],
      "containers": [{"name":"pvc-consumer","image":"busybox:1.36",
        "command":["sleep","3600"],
        "volumeMounts":[{"name":"data","mountPath":"/data"}]}]
    }
  }'
# Once the pod is scheduled, STATUS transitions to Bound
# WaitForFirstConsumer keeps the PVC Pending until the pod is scheduled; wait for Bound:
kubectl wait --for=jsonpath='{.status.phase}'=Bound pvc/pvc-dynamic --timeout=60s
kubectl get pvc pvc-dynamic
```

</p>
</details>

---

### Set a PV's reclaim policy to Retain and observe behavior after PVC deletion  `(med)`
<details><summary>show</summary>
<p>

```bash
# Create a PV with persistentVolumeReclaimPolicy: Retain
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-retain
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: ""
  hostPath:
    path: /mnt/retain-data
    type: DirectoryOrCreate
EOF

# Create a matching PVC and confirm Bound
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-retain
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: ""
EOF

kubectl wait --for=jsonpath='{.status.phase}'=Bound pvc/pvc-retain --timeout=30s

# Delete the PVC
kubectl delete pvc pvc-retain

# Observe the PV — policy Retain means the PV moves to Released, NOT Available or Deleted.
# Underlying data on the host at /mnt/retain-data is preserved.
kubectl get pv pv-retain
# Expected: STATUS=Released   RECLAIM POLICY=Retain

# To make the PV available for a new claim, an admin must manually clear the claimRef:
#   kubectl patch pv pv-retain -p '{"spec":{"claimRef":null}}'
```

</p>
</details>

---

### Explain the access modes (RWO/ROX/RWX/RWOP) and create a PVC requesting ReadWriteOnce  `(easy)`
<details><summary>show</summary>
<p>

```bash
# Access mode reference
# ─────────────────────────────────────────────────────────────────────────────
# ReadWriteOnce    (RWO)  — read/write mount on a SINGLE NODE at a time.
#                           The most common mode; supported by nearly all volume types.
# ReadOnlyMany     (ROX)  — read-only mount on MANY NODES simultaneously.
#                           Useful for shared config or static assets (e.g. NFS read mounts).
# ReadWriteMany    (RWX)  — read/write mount on MANY NODES simultaneously.
#                           Requires a network filesystem: NFS, CephFS, AzureFile, etc.
# ReadWriteOncePod (RWOP) — read/write mount on a SINGLE POD only (stricter than RWO).
#                           Introduced in v1.22, GA in v1.29; CSI driver support required.
# ─────────────────────────────────────────────────────────────────────────────

# Create a PVC requesting ReadWriteOnce
# Note: storageClassName: "" means no dynamic provisioner is used.
# This PVC will remain Pending unless a matching static PV exists or a default StorageClass
# is configured. That is EXPECTED here — the exercise demonstrates access-mode syntax only.
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-rwo
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 256Mi
  storageClassName: ""
EOF
```

</p>
</details>

---

### Expand a PVC on an expansion-capable StorageClass  `(hard)`
<details><summary>show</summary>
<p>

```bash
# Create a StorageClass with allowVolumeExpansion: true
# Note: volume expansion requires a CSI provisioner that implements the NodeExpandVolume RPC.
# hostpath.csi.k8s.io is used here (CSI hostpath driver, suitable for lab clusters).
# On cloud clusters use the cloud CSI driver instead, e.g.:
#   ebs.csi.aws.com  (AWS EBS CSI)
#   pd.csi.storage.gke.io  (GCE PD CSI)
# The Rancher local-path provisioner is NOT a CSI driver and cannot expand volumes.
kubectl apply -f - <<EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: expandable-sc
provisioner: hostpath.csi.k8s.io
volumeBindingMode: WaitForFirstConsumer
reclaimPolicy: Delete
allowVolumeExpansion: true
EOF

# Create a PVC backed by the expandable StorageClass
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-expand
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: expandable-sc
  resources:
    requests:
      storage: 500Mi
EOF

# WaitForFirstConsumer requires a pod to trigger initial binding
kubectl run expand-consumer --image=busybox:1.36 --restart=Never \
  --overrides='{
    "spec": {
      "volumes": [{"name":"data","persistentVolumeClaim":{"claimName":"pvc-expand"}}],
      "containers": [{"name":"expand-consumer","image":"busybox:1.36",
        "command":["sleep","3600"],
        "volumeMounts":[{"name":"data","mountPath":"/data"}]}]
    }
  }'

kubectl wait --for=jsonpath='{.status.phase}'=Bound pvc/pvc-expand --timeout=60s

# Expand the PVC by patching the requested storage to a larger value
kubectl patch pvc pvc-expand -p '{"spec":{"resources":{"requests":{"storage":"1Gi"}}}}'

# Note: patching .spec.resources.requests.storage updates the request immediately,
# but .status.capacity.storage is updated ASYNCHRONOUSLY by the external resizer controller
# and may lag behind. For filesystem-backed volumes (ext4, xfs), the in-pod resize also
# requires the pod to be restarted (or a new pod to mount the volume) before the filesystem
# reflects the new size.
```

```bash
# verify
# CAPACITY may take a moment to reflect the new size — the external resizer is asynchronous.
# Watch until CAPACITY shows 1Gi:
kubectl get pvc pvc-expand -w
# Or poll manually:
# kubectl get pvc pvc-expand
```

</p>
</details>

---

### Mount a PVC into a pod, write a file, and confirm the data survives pod recreation  `(med)`
<details><summary>show</summary>
<p>

```bash
# Uses pvc-hostpath from exercise 1 (create it first if skipped)
# Note: hostPath PVs are node-local. In a multi-node cluster both writer and reader pods
# must land on the SAME node — add a nodeSelector or nodeName to each pod spec to pin them.

# Create a writer pod that mounts pvc-hostpath and writes a test file
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: writer-pod
spec:
  containers:
  - name: writer
    image: busybox:1.36
    command: ["sh", "-c", "echo 'hello-storage' > /data/test.txt && sleep 3600"]
    volumeMounts:
    - name: storage
      mountPath: /data
  volumes:
  - name: storage
    persistentVolumeClaim:
      claimName: pvc-hostpath
EOF

kubectl wait --for=condition=Ready pod/writer-pod --timeout=60s

# Delete the pod — the PVC and its data remain
kubectl delete pod writer-pod

# Recreate a reader pod mounting the same PVC
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: reader-pod
spec:
  containers:
  - name: reader
    image: busybox:1.36
    command: ["sleep", "3600"]
    volumeMounts:
    - name: storage
      mountPath: /data
  volumes:
  - name: storage
    persistentVolumeClaim:
      claimName: pvc-hostpath
EOF

kubectl wait --for=condition=Ready pod/reader-pod --timeout=60s
```

```bash
# verify
# Should print: hello-storage
kubectl exec reader-pod -- cat /data/test.txt
```

</p>
</details>
