# Cluster Architecture

> **New/deeper vs CKAD:** control-plane internals, etcd operations, CRDs & operators, and cluster extension interfaces — all new/deeper than CKAD.

## Quick Reference — Documentation
kubernetes.io > Documentation > Concepts > Overview > [Kubernetes Components](https://kubernetes.io/docs/concepts/overview/components/)
kubernetes.io > Documentation > Tasks > Administer a Cluster > [Operating etcd Clusters for Kubernetes](https://kubernetes.io/docs/tasks/administer-cluster/configure-upgrade-etcd/)
kubernetes.io > Documentation > Tasks > Extend Kubernetes > [Custom Resources / CustomResourceDefinitions](https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definitions/)
kubernetes.io > Documentation > Reference > kubectl CLI > [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/quick-reference/)
kubernetes.io > Documentation > Concepts > Cluster Administration > [Proxies in Kubernetes](https://kubernetes.io/docs/concepts/cluster-administration/proxies/)

---

### List all control-plane static pod manifests on the control-plane node `(easy)`
<details><summary>show</summary>
<p>

```bash
# Static pod manifests are stored in /etc/kubernetes/manifests/ on the control-plane node.
# SSH to the control-plane node first, then:
ls -la /etc/kubernetes/manifests/
# You should see: etcd.yaml  kube-apiserver.yaml  kube-controller-manager.yaml  kube-scheduler.yaml

# Alternatively, verify via running pods in the kube-system namespace:
kubectl get pods -n kube-system
```

</p>
</details>

---

### Identify which component the kube-scheduler talks to and inspect its static pod spec `(easy)`
<details><summary>show</summary>
<p>

```bash
# The kube-scheduler watches the kube-apiserver for unscheduled Pods (via the API server —
# it does NOT talk to etcd directly). It writes its binding decision back through the API server.

# Inspect the scheduler static pod spec on the control-plane node:
cat /etc/kubernetes/manifests/kube-scheduler.yaml

# Or view it through kubectl:
kubectl get pod -n kube-system -l component=kube-scheduler -o yaml

# Key flags to note: --leader-elect, --kubeconfig, --bind-address
```

</p>
</details>

---

### Inspect the kube-apiserver flags currently in effect `(med)`
<details><summary>show</summary>
<p>

```bash
# Method 1: read the static pod manifest (most reliable on kubeadm clusters)
cat /etc/kubernetes/manifests/kube-apiserver.yaml

# Method 2: inspect the running process arguments
kubectl get pod -n kube-system -l component=kube-apiserver \
  -o jsonpath='{range .items[0].spec.containers[0].command[*]}{@}{"\n"}{end}'

# Method 3: read live args from the running apiserver process
kubectl exec -n kube-system \
  "$(kubectl get pods -n kube-system -l component=kube-apiserver -o name | head -1)" \
  -- cat /proc/1/cmdline | tr '\0' '\n'

# Important flags to know:
#   --etcd-servers         where etcd lives
#   --service-cluster-ip-range
#   --authorization-mode   e.g. Node,RBAC
#   --enable-admission-plugins
#   --tls-cert-file / --tls-private-key-file
```

</p>
</details>

---

### Explain the role of the controller-manager and list the controllers it runs `(easy)`
<details><summary>show</summary>
<p>

```bash
# The kube-controller-manager is a single binary that embeds all the core Kubernetes
# controllers. It watches the API server for desired-state changes and reconciles
# actual state to match.  Each controller runs as a goroutine inside the same process.

# List controllers compiled in (printed to stdout with --help):
kubectl exec -n kube-system \
  "$(kubectl get pods -n kube-system -l component=kube-controller-manager -o name | head -1)" \
  -- kube-controller-manager --help 2>&1 | grep -A 100 'controllers '

# Key built-in controllers include:
#   node            – marks nodes NotReady, evicts pods
#   replicaset      – maintains pod replica count
#   deployment      – manages rollouts via ReplicaSets
#   statefulset     – ordered pod management
#   job / cronjob   – batch workloads
#   serviceaccount  – auto-creates default SAs
#   namespace       – handles namespace lifecycle
#   persistentvolume-binder – binds PVCs to PVs
#   endpoint        – populates Endpoints objects
#   ttl             – cleans up finished Jobs

# Inspect flags in the static pod manifest:
cat /etc/kubernetes/manifests/kube-controller-manager.yaml
```

</p>
</details>

---

### Show the container runtime in use and its socket via `kubectl get nodes -o wide` and `crictl info` `(med)`
<details><summary>show</summary>
<p>

```bash
# Step 1: identify the container runtime from the CONTAINER-RUNTIME column
kubectl get nodes -o wide
# Example output column: containerd://1.7.x  or  cri-o://1.30.x

# Step 2: find the CRI socket path (kubeadm stores it in the node annotation)
kubectl get node <node-name> -o jsonpath='{.metadata.annotations.kubeadm\.alpha\.kubernetes\.io/cri-socket}'
# Typical values:
#   unix:///run/containerd/containerd.sock
#   unix:///var/run/crio/crio.sock

# Step 3: on the node, use crictl (specify socket if needed)
sudo crictl --runtime-endpoint unix:///run/containerd/containerd.sock info

# crictl quick-reference:
sudo crictl ps          # running containers
sudo crictl pods        # running sandbox pods
sudo crictl images      # cached images
sudo crictl info        # runtime version + config
```

</p>
</details>

---

### ⭐ Create a CustomResourceDefinition for a `Widget` resource, then create a `Widget` instance `(hard)`
<details><summary>show</summary>
<p>

```yaml
# Step 1 — define the CRD (save as widget-crd.yaml)
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: widgets.example.com
spec:
  group: example.com
  names:
    kind: Widget
    listKind: WidgetList
    plural: widgets
    singular: widget
  scope: Namespaced
  versions:
    - name: v1
      served: true
      storage: true
      schema:
        openAPIV3Schema:
          type: object
          properties:
            spec:
              type: object
              properties:
                color:
                  type: string
                size:
                  type: integer
```

```bash
kubectl apply -f widget-crd.yaml

# Wait for the CRD to become established
kubectl wait crd/widgets.example.com --for=condition=Established --timeout=30s
```

```yaml
# Step 2 — create a Widget instance (save as my-widget.yaml)
apiVersion: example.com/v1
kind: Widget
metadata:
  name: my-widget
  namespace: default
spec:
  color: blue
  size: 3
```

```bash
kubectl apply -f my-widget.yaml
```

```bash
# verify
kubectl get widgets
kubectl get widgets my-widget -o yaml
```

</p>
</details>

---

### ⭐ Explain the difference between a CRD and an operator; identify a running operator's controller pod `(med)`
<details><summary>show</summary>
<p>

```bash
# A CustomResourceDefinition (CRD) extends the Kubernetes API with a new resource type.
# It stores custom objects in etcd but provides NO business logic — the API server
# validates and persists objects only.
#
# An Operator is a CRD + a controller (a Pod running in the cluster) that watches those
# custom resources and reconciles external or complex state.  Operators encode operational
# domain knowledge (backup, failover, scaling) that vanilla Kubernetes does not know.
#
# Analogy:
#   CRD  = schema / noun (defines what a "PostgresCluster" looks like)
#   Operator = controller / verb (creates, migrates, backs up the actual Postgres cluster)

# Identify a running operator's controller pod:
# Operators typically install into their own namespace and have "operator" or
# "controller" in the pod name.

kubectl get pods -A | grep -E 'operator|controller-manager'

# For a specific operator (e.g., cert-manager):
kubectl get pods -n cert-manager

# Check what CRDs an operator owns:
kubectl get crd | grep cert-manager.io

# Inspect the controller's reconcile loop via logs:
kubectl logs -n cert-manager deployment/cert-manager --tail=20
```

</p>
</details>

---

### ⭐ List the extension interfaces (CNI, CSI, CRI) and identify which implementation each node uses `(med)`
<details><summary>show</summary>
<p>

```bash
# Kubernetes uses three primary extension interfaces (all implemented as plugins):
#
#   CRI – Container Runtime Interface
#         Defines how kubelet starts/stops containers.
#         Implementations: containerd, CRI-O
#
#   CNI – Container Network Interface
#         Defines how pods get network connectivity and IP addresses.
#         Implementations: Calico, Cilium, Flannel, Weave, aws-vpc-cni
#
#   CSI – Container Storage Interface
#         Defines how volumes are provisioned, attached, and mounted.
#         Implementations: aws-ebs-csi-driver, gce-pd-csi-driver, rook-ceph

# --- Identify CRI ---
kubectl get nodes -o wide
# CONTAINER-RUNTIME column shows e.g. "containerd://1.7.13"

# Or check the node annotation for the exact socket path:
kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.metadata.annotations.kubeadm\.alpha\.kubernetes\.io/cri-socket}{"\n"}{end}'

# --- Identify CNI ---
# The CNI plugin config lives on the node at /etc/cni/net.d/
# SSH to a node and inspect:
ls /etc/cni/net.d/
cat /etc/cni/net.d/*.conf 2>/dev/null || cat /etc/cni/net.d/*.conflist 2>/dev/null

# Or detect via DaemonSets (most CNI plugins run as a DaemonSet):
kubectl get daemonsets -A | grep -v kube-proxy

# --- Identify CSI ---
# CSI drivers register themselves as CSINode objects:
kubectl get csinode
kubectl get csinodes -o wide

# List all installed CSI drivers:
kubectl get csidrivers
```

</p>
</details>
