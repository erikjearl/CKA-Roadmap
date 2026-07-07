# Node Administration

> **New/deeper vs CKAD:** node lifecycle and scheduling controls operators use — taints, affinity, drain/cordon, static pods, DaemonSets.

## Quick Reference — Documentation
kubernetes.io > Documentation > Concepts > Scheduling, Preemption and Eviction > [Taints and Tolerations](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/)
kubernetes.io > Documentation > Tasks > Administer a Cluster > [Safely Drain a Node](https://kubernetes.io/docs/tasks/administer-cluster/safely-drain-node/)
kubernetes.io > Documentation > Tasks > Configure Pods and Containers > [Create static Pods](https://kubernetes.io/docs/tasks/configure-pod-container/static-pod/)
kubernetes.io > Documentation > Reference > kubectl CLI > [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/quick-reference/)

---

### Taint a node `key=value:NoSchedule` and create a pod with a matching toleration `(med)`
<details><summary>show</summary>
<p>

```bash
# Taint the node (replace <node-name> with the actual node name)
kubectl taint nodes <node-name> key=value:NoSchedule

# Confirm the taint was applied
kubectl describe node <node-name> | grep -A5 Taints

# Create a pod that tolerates the taint — without this toleration the pod stays Pending
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: toleration-pod
spec:
  tolerations:
  - key: "key"
    operator: "Equal"
    value: "value"
    effect: "NoSchedule"
  containers:
  - name: nginx
    image: nginx:1.25
EOF

# Remove the taint when no longer needed (trailing "-" removes it)
kubectl taint nodes <node-name> key=value:NoSchedule-
```

</p>
</details>

---

### Schedule a pod to a specific node using nodeAffinity `(med)`
<details><summary>show</summary>
<p>

```bash
# Label the target node
kubectl label nodes <node-name> disktype=ssd

# Verify the label was set
kubectl get nodes --show-labels | grep disktype

# Create a pod that requires the node label via requiredDuringSchedulingIgnoredDuringExecution
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: affinity-pod
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: disktype
            operator: In
            values:
            - ssd
  containers:
  - name: nginx
    image: nginx:1.25
EOF

# Confirm the pod landed on the labeled node
kubectl get pod affinity-pod -o wide
```

</p>
</details>

---

### Cordon a node, then drain it ignoring DaemonSets and emptyDir `(med)`
<details><summary>show</summary>
<p>

```bash
# Cordon the node — marks it SchedulingDisabled so no new pods land here
kubectl cordon <node-name>

# Drain all evictable workload pods off the node
# --ignore-daemonsets: DaemonSet pods cannot be evicted (they re-create on the same node)
# --delete-emptydir-data: allow eviction of pods using emptyDir volumes (data will be lost)
kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data
```

```bash
# verify
# Node status should show SchedulingDisabled in the STATUS column
kubectl get nodes
# Example output: node01   Ready,SchedulingDisabled   <none>   5d   v1.35.0

# Workload pods that were on <node-name> should now be Running on other nodes
kubectl get pods -o wide
```

</p>
</details>

---

### Uncordon the node and confirm it accepts pods again `(easy)`
<details><summary>show</summary>
<p>

```bash
# Uncordon the node — removes the SchedulingDisabled status
kubectl uncordon <node-name>

# Confirm the node is Ready (no SchedulingDisabled suffix)
kubectl get nodes

# Optional: scale a deployment to trigger new pod scheduling on the uncordoned node
kubectl scale deployment nginx --replicas=4
kubectl get pods -o wide
```

</p>
</details>

---

### Create a static pod on a node via the kubelet manifests directory `(med)`
<details><summary>show</summary>
<p>

```bash
# Static pods are managed directly by the kubelet on a node, not via the API server.
# The default staticPodPath is /etc/kubernetes/manifests/.
# The kubelet watches that directory and creates a mirror pod named <pod>-<nodeName>.

# Step 1: open a shell on the target node
# Method A — SSH directly (most exam environments)
ssh <node-name>

# Method B — kubectl debug node (when SSH is unavailable)
# kubectl debug node/<node-name> -it --image=busybox -- chroot /host bash
# image availability varies; ubuntu also works

# Step 2: write the pod manifest to the staticPodPath (run on the node)
cat <<'EOF' > /etc/kubernetes/manifests/static-nginx.yaml
apiVersion: v1
kind: Pod
metadata:
  name: static-nginx
  namespace: default
spec:
  containers:
  - name: nginx
    image: nginx:1.25
EOF

# The kubelet detects the new file and starts the pod immediately — no apply needed.
# Exit the node shell when done.
exit
```

```bash
# verify
# The mirror pod appears in kubectl output on the control plane.
# Name format: static-nginx-<nodeName>
kubectl get pods -o wide
# Expected: a pod named static-nginx-<node-name> in Running state, NODE = <node-name>
```

</p>
</details>

---

### Create a DaemonSet that runs one pod per node, including the control-plane `(med)`
<details><summary>show</summary>
<p>

```bash
# By default, DaemonSets skip the control-plane because it carries a NoSchedule taint:
#   node-role.kubernetes.io/control-plane:NoSchedule
# Add a matching toleration so the DaemonSet pod also runs there.

kubectl apply -f - <<'EOF'
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: node-monitor
  namespace: default
spec:
  selector:
    matchLabels:
      app: node-monitor
  template:
    metadata:
      labels:
        app: node-monitor
    spec:
      tolerations:
      - key: "node-role.kubernetes.io/control-plane"
        operator: "Exists"
        effect: "NoSchedule"
      containers:
      - name: monitor
        image: busybox:1.36
        command: ["sh", "-c", "while true; do sleep 3600; done"]
EOF

# Verify one pod per node (DESIRED == CURRENT == READY == number of nodes)
kubectl get daemonset node-monitor
kubectl get pods -l app=node-monitor -o wide
```

</p>
</details>
