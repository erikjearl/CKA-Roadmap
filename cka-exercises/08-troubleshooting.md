# Troubleshooting

> **New/deeper vs CKAD:** the 30% domain — systematic diagnosis of nodes, control plane, kubelet, networking, and etcd, including node-level tools (crictl, journalctl) beyond kubectl.

## Quick Reference — Documentation
kubernetes.io > Documentation > Tasks > Monitoring, Logging, and Debugging > [Troubleshooting Clusters](https://kubernetes.io/docs/tasks/debug/debug-cluster/)
kubernetes.io > Documentation > Tasks > Monitoring, Logging, and Debugging > [Troubleshoot Applications](https://kubernetes.io/docs/tasks/debug/debug-application/)
kubernetes.io > Documentation > Reference > kubectl CLI > [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/quick-reference/)

---

### Diagnose and fix a node stuck in `NotReady` (kubelet down)  `(hard)`
<details><summary>show</summary>
<p>

```bash
# On the control-plane node, identify which node is NotReady:
kubectl get nodes
# Example output:
#   NAME        STATUS     ROLES    AGE   VERSION
#   worker-01   NotReady   <none>   10d   v1.35.0

# SSH to the affected node, then diagnose:
# Step 1 — check the kubelet service status:
systemctl status kubelet

# Step 2 — read the last 50 kubelet log lines to identify the root cause:
#   - swap enabled (kubelet refuses to start with swap on by default)
#   - bad /var/lib/kubelet/config.yaml (unknown flag, malformed YAML)
#   - container runtime socket unreachable (containerd or crio stopped)
journalctl -u kubelet -n 50

# If the container runtime is suspected, check it separately:
systemctl status containerd

# Step 3 — fix the ROOT CAUSE first (pick what the logs show), THEN start the kubelet:
#   - swap enabled:           swapoff -a   (and comment the swap line in /etc/fstab)
#   - container runtime down: systemctl enable --now containerd
#   - bad kubelet config:     fix /var/lib/kubelet/config.yaml

# Example: if swap is the root cause:
swapoff -a
# Comment out or remove the swap entry in /etc/fstab to persist after reboot.

# Step 4 — AFTER fixing the root cause, start and enable the kubelet:
systemctl enable --now kubelet
```

```bash
# verify
# Run from the control-plane or any host with kubectl access:
kubectl get nodes
# Expected: the previously NotReady node shows STATUS=Ready within ~30 s of kubelet restart
```

</p>
</details>

---

### Diagnose a pod stuck in `Pending` (unschedulable: taint/resources/nodeSelector)  `(med)`
<details><summary>show</summary>
<p>

```bash
# Identify Pending pods across all namespaces:
kubectl get pods -A | grep Pending

# The Events section of describe is the primary diagnostic source for scheduling failures.
# Common messages to look for:
#   "0/3 nodes are available: 3 Insufficient cpu."
#   "0/3 nodes are available: 3 node(s) had untolerated taint {key: value}"
#   "0/3 nodes are available: 3 node(s) didn't match Pod's node affinity/selector"
kubectl describe pod <pod-name>

# --- Fix: Insufficient CPU or memory ---
# Option A — reduce the pod's resource requests in its spec
# Option B — add capacity (a new node or more resources on existing nodes)
# Option C — review ResourceQuota if it caps namespace-wide totals

# --- Fix: Taint without a matching toleration ---
# Check what taints the nodes carry:
kubectl describe nodes | grep -A3 Taints

# Add a toleration to the pod spec so it can land on the tainted node:
# tolerations:
# - key: "key1"
#   operator: "Equal"
#   value: "value1"
#   effect: "NoSchedule"

# Alternatively, remove the taint from a node (if appropriate for the environment):
kubectl taint node <node-name> key1=value1:NoSchedule-

# --- Fix: nodeSelector or affinity mismatch ---
# List node labels to see what is actually present on each node:
kubectl get nodes --show-labels
# Correct the pod's nodeSelector or affinity to match an existing label key/value.
```

```bash
# verify
kubectl get pod <pod-name>
# Expected: STATUS=Running once the root scheduling cause is resolved
```

</p>
</details>

---

### Diagnose a `CrashLoopBackOff` pod from its logs and previous-container logs  `(med)`
<details><summary>show</summary>
<p>

```bash
# Identify CrashLoopBackOff pods across all namespaces:
kubectl get pods -A | grep CrashLoopBackOff

# Read the current container's stdout/stderr:
# (may be empty if the process exits immediately before writing anything)
kubectl logs <pod-name>

# Read logs from the PREVIOUS container instance — essential when the current container
# has already been recycled and its own logs are gone:
kubectl logs <pod-name> --previous

# Inspect the pod for exit codes, restart count, and OOMKill signals:
kubectl describe pod <pod-name>
# Key fields to read in the output:
#   Last State:    Terminated  Reason: OOMKilled / Error / Completed
#   Exit Code:     1/2      → application or entrypoint error
#                 127      → binary not found in the container image
#                 137      → OOMKilled (kernel sent SIGKILL to enforce memory limit)
#                 139      → segmentation fault (SIGSEGV)
#   Restart Count: N       → how many times the container has already restarted

# Common fixes:
#   OOMKilled   → increase the container's memory limit in the pod/deployment spec
#   Bad command → correct the container's command/args field or the application config
#   Missing env → add the required environment variable, ConfigMap ref, or Secret ref
```

</p>
</details>

---

### Use `crictl` on a node to inspect pods and containers when the apiserver is unavailable  `(hard)`
<details><summary>show</summary>
<p>

```bash
# crictl is the CRI-compatible CLI installed by kubeadm on every cluster node.
# It communicates directly with the container runtime, bypassing the apiserver entirely.
# Use it when:
#   - the apiserver is down and kubectl cannot connect
#   - a static pod (etcd, kube-apiserver) is crashing before it registers with kubelet
#   - you need container details that kubectl does not expose

# SSH to the target node.
# If /etc/crictl.yaml is not configured, pass the runtime endpoint explicitly:
crictl --runtime-endpoint unix:///run/containerd/containerd.sock ps -a

# Set the endpoint persistently so subsequent commands omit the flag.
# Create or edit /etc/crictl.yaml:
#   runtime-endpoint: unix:///run/containerd/containerd.sock
#   image-endpoint:   unix:///run/containerd/containerd.sock
#   timeout: 10

# List all containers including stopped and exited ones:
crictl ps -a

# List pod sandboxes (one sandbox entry per pod):
crictl pods

# Stream logs for a container by its CONTAINER ID from `crictl ps -a`:
crictl logs <container-id>

# Show full container config, mounts, state, and exit code:
crictl inspect <container-id>

# List images cached locally on the node:
crictl images
```

</p>
</details>

---

### Fix a broken control-plane static pod (bad manifest under `/etc/kubernetes/manifests/`)  `(hard)`
<details><summary>show</summary>
<p>

```bash
# Static pods are managed by the kubelet directly from manifest files in
# /etc/kubernetes/manifests/ — the kubelet watches this directory and automatically
# creates, updates, or removes pods when the files change.
# A broken manifest (wrong image tag, unknown flag, malformed YAML) causes the
# component to enter CrashLoopBackOff or vanish from the pod list entirely.

# Step 1 — identify which component is broken (run from a working control-plane):
kubectl get pods -n kube-system
# The kube-apiserver, kube-controller-manager, kube-scheduler, or etcd pod
# may be absent or in CrashLoopBackOff.

# Step 2 — if kubectl is unavailable (the apiserver manifest itself is broken),
# use crictl on the control-plane node to see all container states:
crictl ps -a

# Step 3 — check kubelet logs for the precise error describing the manifest problem:
journalctl -u kubelet --no-pager | grep -i "apiserver\|error\|failed" | tail -30

# Step 4 — inspect and correct the manifest file on the control-plane node.
# Default manifest directory:
ls /etc/kubernetes/manifests/
# kube-apiserver.yaml  kube-controller-manager.yaml  kube-scheduler.yaml  etcd.yaml

# Open the broken manifest and fix the issue — e.g. revert a bad image tag,
# remove an unrecognised flag, or repair malformed YAML:
vi /etc/kubernetes/manifests/kube-apiserver.yaml

# The kubelet detects the file change and automatically recreates the static pod
# within a few seconds — no manual service restart is required.
```

```bash
# verify
# Allow ~30 s for the kubelet to pick up the corrected manifest:
kubectl get pods -n kube-system
# Expected: the previously broken component pod shows STATUS=Running
```

</p>
</details>

---

### Diagnose a DNS resolution failure in the cluster (CoreDNS down or misconfigured)  `(med)`
<details><summary>show</summary>
<p>

```bash
# Step 1 — check whether CoreDNS pods are running:
kubectl -n kube-system get pods -l k8s-app=kube-dns

# Step 2 — read CoreDNS logs for errors (plugin panic, upstream timeout, config parse error):
kubectl -n kube-system logs -l k8s-app=kube-dns --tail=50

# Step 3 — verify the kube-dns Service exists and has endpoints:
kubectl -n kube-system get svc kube-dns
kubectl -n kube-system get endpoints kube-dns

# Step 4 — inspect the CoreDNS ConfigMap for syntax errors or missing plugins:
kubectl -n kube-system get configmap coredns -o yaml

# Step 5 — test resolution from an ephemeral pod to confirm the failure:
kubectl run dns-test --image=busybox:1.36 --restart=Never --rm -it -- \
  nslookup kubernetes.default
# non-interactive alternative: kubectl run dns-test --image=busybox:1.36 --restart=Never -- nslookup kubernetes.default; kubectl logs dns-test; kubectl delete pod dns-test
# Expected when healthy: returns the ClusterIP of the kubernetes Service

# Common fixes:
# CoreDNS pods in CrashLoopBackOff due to ConfigMap error → fix the Corefile and rollout restart:
kubectl -n kube-system rollout restart deployment coredns

# kube-dns Service missing → reapply the CoreDNS manifest from the kubeadm defaults
# NetworkPolicy blocking UDP/TCP 53 → review NetworkPolicy objects in kube-system namespace
```

```bash
# verify
kubectl run dns-verify --image=busybox:1.36 --restart=Never --rm -it -- \
  nslookup kubernetes.default
# non-interactive alternative: kubectl run dns-test --image=busybox:1.36 --restart=Never -- nslookup kubernetes.default; kubectl logs dns-test; kubectl delete pod dns-test
# Expected output (healthy):
#   Server:    10.96.0.10:53
#   Address 1: 10.96.0.10 kube-dns.kube-system.svc.cluster.local
#
#   Name:      kubernetes.default
#   Address 1: 10.96.0.1 kubernetes.default.svc.cluster.local
```

</p>
</details>

---

### Diagnose a Service with no endpoints and restore connectivity  `(med)`
<details><summary>show</summary>
<p>

```bash
# Symptom: connections to the Service ClusterIP time out; traffic never reaches the pods.

# Step 1 — check whether the Service has any endpoints:
kubectl get endpoints <svc-name>
# If ENDPOINTS shows <none>, the Service selector is not matching any running pods.

# Step 2 — compare the Service selector against actual pod labels:
kubectl describe svc <svc-name>
# Note the Selector field, e.g.  Selector: app=my-app

kubectl get pods --show-labels
# Identify pods that should back this Service and compare their labels exactly.

# Step 3 — determine the mismatch type.  Common causes:
# a) Typo in Service selector:  app=myapp  vs  pod label app=my-app
# b) Typo in pod label:         pod carries  app=myApp  (case mismatch)
# c) Wrong targetPort:          Service points to port 8080 but container listens on 80

# Step 4a — fix the Service selector (patch in-place):
kubectl patch svc <svc-name> -p '{"spec":{"selector":{"app":"my-app"}}}'

# Step 4b — alternatively, fix the pod label (if the Service selector is correct):
kubectl label pod <pod-name> app=my-app --overwrite

# Step 4c — fix a wrong targetPort by editing the Service:
kubectl edit svc <svc-name>
# Change spec.ports[0].targetPort to the correct port number or named port.
```

```bash
# verify
kubectl get endpoints <svc-name>
# Expected: ENDPOINTS column shows one or more <pod-IP>:<port> entries (not <none>)
```

</p>
</details>

---

### Inspect node and pod resource usage with `kubectl top` (metrics-server required)  `(easy)`
<details><summary>show</summary>
<p>

```bash
# kubectl top requires metrics-server to be running in the cluster.
# Verify it is present before relying on top output:
kubectl get pods -n kube-system | grep metrics-server

# If metrics-server is missing, install it (lab clusters — exam environments ship with it):
# kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Show current CPU and memory consumption per node:
kubectl top nodes

# Show CPU and memory usage per pod across all namespaces:
kubectl top pods -A

# Show usage for pods in a specific namespace, sorted by CPU consumption:
kubectl top pods -n <namespace> --sort-by=cpu

# Show resource usage broken down by individual container within each pod:
kubectl top pods -A --containers
```

</p>
</details>
