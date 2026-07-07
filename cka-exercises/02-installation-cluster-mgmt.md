# Installation & Cluster Management

> **New/deeper vs CKAD:** bootstrapping, joining nodes, cluster upgrades, etcd backup/restore, certificate renewal, and installing components with Helm/Kustomize — the operational core of CKA. Run these against the real cluster in cluster-setup/.

## Quick Reference — Documentation
kubernetes.io > Documentation > Tasks > Administer a Cluster > [Upgrading kubeadm clusters](https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade/)
kubernetes.io > Documentation > Tasks > Administer a Cluster > [Operating etcd Clusters for Kubernetes](https://kubernetes.io/docs/tasks/administer-cluster/configure-upgrade-etcd/)
kubernetes.io > Documentation > Tasks > Administer a Cluster > [Certificate Management with kubeadm](https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-certs/)
kubernetes.io > Documentation > Reference > kubectl CLI > [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/quick-reference/)

---

### Generate a new join command with a fresh token on the control plane `(easy)`
<details><summary>show</summary>
<p>

```bash
# Run on the control-plane node.
# kubeadm token create generates a 24-hour bootstrap token and prints the full join command.
kubeadm token create --print-join-command

# Example output:
# kubeadm join 192.168.1.10:6443 --token abcdef.0123456789abcdef \
#   --discovery-token-ca-cert-hash sha256:<hash>

# To list existing tokens (and their TTL):
kubeadm token list

# To create a token that never expires (use sparingly — for automation):
kubeadm token create --ttl 0 --print-join-command
```

</p>
</details>

---

### Join a worker node to the cluster `(med)`
<details><summary>show</summary>
<p>

```bash
# Prerequisites:
#   - containerd (or another CRI) installed on the worker
#   - kubelet and kubeadm packages installed (same minor version as the control plane)
#   - swap disabled: swapoff -a  and remove/comment swap from /etc/fstab
#   - required ports open (10250, 30000-32767 for NodePort)

# Step 1: on the control plane, generate the join command
kubeadm token create --print-join-command
# Copy the output — it looks like:
#   kubeadm join <CP-IP>:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash>

# Step 2: run that command on the worker node (as root / sudo)
sudo kubeadm join 192.168.1.10:6443 \
  --token abcdef.0123456789abcdef \
  --discovery-token-ca-cert-hash sha256:<hash>

# Step 3: on the control plane, confirm the node joined
kubectl get nodes
# The new node appears with status Ready (may take 30–60 s while CNI initialises)
```

</p>
</details>

---

### Upgrade the control-plane node to the next patch version with kubeadm `(hard)`
<details><summary>show</summary>
<p>

```bash
# Target version example: v1.35.1  (replace with the actual available patch)
# Run all steps below on the CONTROL-PLANE node.

# Step 1: drain the control-plane node
kubectl drain <control-plane-node> --ignore-daemonsets

# Step 2: upgrade the kubeadm package
# Debian/Ubuntu:
apt-mark unhold kubeadm
apt-get update
apt-get install -y kubeadm=1.35.1-*
apt-mark hold kubeadm

# RHEL/CentOS:
# yum install -y kubeadm-1.35.1 --disableexcludes=kubernetes

# Step 3: verify the new kubeadm version
kubeadm version

# Step 4: review the upgrade plan (shows available versions and what will change)
kubeadm upgrade plan

# Step 5: apply the upgrade to the control-plane components
kubeadm upgrade apply v1.35.1
# Type 'y' when prompted; kubeadm upgrades kube-apiserver, kube-controller-manager,
# kube-scheduler, kube-proxy, and CoreDNS static-pod manifests.

# Step 6: upgrade kubelet and kubectl
apt-mark unhold kubelet kubectl
apt-get install -y kubelet=1.35.1-* kubectl=1.35.1-*
apt-mark hold kubelet kubectl

# Step 7: restart kubelet
systemctl daemon-reload
systemctl restart kubelet

# Step 8: uncordon the node
kubectl uncordon <control-plane-node>
```

```bash
# verify
kubectl get nodes
# The control-plane node should show VERSION v1.35.1
```

</p>
</details>

---

### Upgrade a worker node (drain → upgrade kubelet → uncordon) `(hard)`
<details><summary>show</summary>
<p>

```bash
# Run drain and uncordon from the CONTROL PLANE.
# Run the package and kubelet steps on the WORKER NODE itself.

# Step 1: drain the worker node from the control plane
kubectl drain <worker-node> --ignore-daemonsets --delete-emissary-data
# --delete-emissary-data evicts pods that use emptyDir volumes (older flag: --delete-local-data)

# Step 2: on the WORKER NODE — upgrade kubeadm
apt-mark unhold kubeadm
apt-get update
apt-get install -y kubeadm=1.35.1-*
apt-mark hold kubeadm

# Step 3: on the WORKER NODE — upgrade node config (does NOT upgrade control-plane components)
kubeadm upgrade node

# Step 4: on the WORKER NODE — upgrade kubelet and kubectl
apt-mark unhold kubelet kubectl
apt-get install -y kubelet=1.35.1-* kubectl=1.35.1-*
apt-mark hold kubelet kubectl

# Step 5: on the WORKER NODE — restart kubelet
systemctl daemon-reload
systemctl restart kubelet

# Step 6: from the CONTROL PLANE — uncordon the worker
kubectl uncordon <worker-node>
```

```bash
# verify
kubectl get nodes
# All nodes should now show VERSION v1.35.1 and STATUS Ready
```

</p>
</details>

---

### Back up the etcd datastore to `/opt/etcd-backup.db` `(med)`
<details><summary>show</summary>
<p>

```bash
# Run on the control-plane node as root (or with sudo).
# etcdctl reads the API version from ETCDCTL_API; always set it to 3.

# Find the etcd TLS paths from the static pod manifest:
grep -E 'cert-file|key-file|trusted-ca-file|listen-client' /etc/kubernetes/manifests/etcd.yaml

# Take the snapshot:
ETCDCTL_API=3 etcdctl snapshot save /opt/etcd-backup.db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key
```

```bash
# verify
ETCDCTL_API=3 etcdctl snapshot status --write-out=table /opt/etcd-backup.db
# Expect a table with: HASH | REVISION | TOTAL KEYS | TOTAL SIZE
# Total keys should be several hundred (proves the snapshot is non-empty)
```

</p>
</details>

---

### Restore etcd from a snapshot and point the static pod at the restored data-dir `(hard)`
<details><summary>show</summary>
<p>

```bash
# Step 1: restore the snapshot into a new data directory
ETCDCTL_API=3 etcdctl snapshot restore /opt/etcd-backup.db \
  --data-dir=/var/lib/etcd-restore
# etcdctl writes a new etcd data directory at /var/lib/etcd-restore

# Step 2: edit the etcd static pod manifest to point at the new data directory.
# The manifest is at /etc/kubernetes/manifests/etcd.yaml.
# Find the volume named "etcd-data" and change its hostPath:
#
# Before:
#   hostPath:
#     path: /var/lib/etcd
#     type: DirectoryOrCreate
#
# After:
#   hostPath:
#     path: /var/lib/etcd-restore
#     type: DirectoryOrCreate

# Edit it with your preferred editor:
vi /etc/kubernetes/manifests/etcd.yaml
# Change ONLY the path under volumes > name: etcd-data > hostPath > path.
# Leave --data-dir and volumeMounts.mountPath UNCHANGED (both stay /var/lib/etcd).
# The restored host directory is bind-mounted into the container at the same
# in-container path etcd already uses, so no other edits are needed.

# Step 3: kubelet detects the manifest change and recreates the etcd pod automatically.
# Wait 30–60 s for the API server to reconnect to etcd.
```

```bash
# verify
kubectl get pods -A
# All system pods (kube-apiserver, kube-controller-manager, etc.) should return to Running.
# If kubectl is temporarily unreachable, wait ~60 s for etcd to start and retry.

# Confirm etcd is healthy:
ETCDCTL_API=3 etcdctl endpoint health \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key
```

</p>
</details>

---

### Renew all control-plane certificates with kubeadm and confirm expiry dates `(med)`
<details><summary>show</summary>
<p>

```bash
# Run on the control-plane node.
# kubeadm certs renew all regenerates every certificate in /etc/kubernetes/pki/
# and updates the kubeconfig files under /etc/kubernetes/*.conf.

# Step 1: check current expiry dates before renewal
kubeadm certs check-expiration

# Step 2: renew all certificates (requires root / sudo)
kubeadm certs renew all

# Step 3: restart the static pod components so they reload the new certs.
# The simplest approach is to move and restore the manifests (forces kubelet to
# stop and restart each control-plane pod):
mv /etc/kubernetes/manifests/{kube-apiserver,kube-controller-manager,kube-scheduler,etcd}.yaml /tmp/
# Wait ~20 s for pods to terminate, then restore:
mv /tmp/{kube-apiserver,kube-controller-manager,kube-scheduler,etcd}.yaml /etc/kubernetes/manifests/

# Alternatively, on kubeadm clusters you can use:
# crictl rm -f $(crictl ps -q --name kube-apiserver)   # etc., one by one
```

```bash
# verify
kubeadm certs check-expiration
# All certificates should now show an expiry ~1 year from today.
# Example output line:
#   admin.conf   Dec 31, 2026 00:00 UTC   364d   ...   no
```

</p>
</details>

---

### ⭐ Install a component with Helm (add repo, install a chart into a namespace) `(med)`
<details><summary>show</summary>
<p>

```bash
# Helm is not installed by default — install it first if needed:
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
helm version

# Example: install metrics-server from the metrics-server Helm repo.
# (Substitute any chart/repo that the exam task specifies.)

# Step 1: add the upstream repository
helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/

# Step 2: fetch the latest index from the repo
helm repo update

# Step 3: install the chart into a dedicated namespace (create it if it doesn't exist)
helm install metrics-server metrics-server/metrics-server \
  --namespace monitoring \
  --create-namespace

# Common flags:
#   --set key=value                  override a single chart value
#   --values custom-values.yaml      supply a values file
#   --version 3.12.0                 pin a specific chart version

# List installed releases:
helm list -A

# Check a release's status:
helm status metrics-server -n monitoring

# Upgrade an existing release (e.g., after adding --set flags):
helm upgrade metrics-server metrics-server/metrics-server -n monitoring

# Uninstall:
helm uninstall metrics-server -n monitoring
```

</p>
</details>

---

### ⭐ Deploy a component with Kustomize (`kubectl apply -k`) using a base + overlay `(med)`
<details><summary>show</summary>
<p>

```bash
# Kustomize is built into kubectl (no separate install needed).
# Directory layout used in this example:
#
#   kustomize-demo/
#   ├── base/
#   │   ├── kustomization.yaml
#   │   └── deployment.yaml
#   └── overlays/
#       └── prod/
#           └── kustomization.yaml

# --- Step 1: create the base ---
mkdir -p /tmp/kustomize-demo/base
```

```yaml
# /tmp/kustomize-demo/base/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
        - name: nginx
          image: nginx:1.25
```

```yaml
# /tmp/kustomize-demo/base/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - deployment.yaml
```

```bash
# --- Step 2: create the prod overlay ---
mkdir -p /tmp/kustomize-demo/overlays/prod
```

```yaml
# /tmp/kustomize-demo/overlays/prod/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namePrefix: prod-
namespace: production
resources:
  - ../../base
patches:
  - patch: |-
      - op: replace
        path: /spec/replicas
        value: 3
    target:
      kind: Deployment
      name: nginx
images:
  - name: nginx
    newTag: "1.27"
```

```bash
# --- Step 3: preview what will be applied (dry-run) ---
kubectl kustomize /tmp/kustomize-demo/overlays/prod

# --- Step 4: apply the overlay ---
kubectl create namespace production --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -k /tmp/kustomize-demo/overlays/prod

# Verify: the Deployment should be named "prod-nginx" with 3 replicas and image nginx:1.27
kubectl get deployment -n production
kubectl get deployment prod-nginx -n production -o jsonpath='{.spec.replicas}'
```

</p>
</details>
