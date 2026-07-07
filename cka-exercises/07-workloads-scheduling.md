# Workloads & Scheduling

> **New/deeper vs CKAD:** workload rollout control plus the scheduling and resource-governance topics the exam adds — HPA autoscaling, manual scheduling, PriorityClass, topology spread, ResourceQuota/LimitRange.

## Quick Reference — Documentation
kubernetes.io > Documentation > Tasks > Run Applications > [Horizontal Pod Autoscaling](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)
kubernetes.io > Documentation > Concepts > Scheduling, Preemption and Eviction > [Pod Priority and Preemption](https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/)
kubernetes.io > Documentation > Concepts > Policy > [Resource Quotas](https://kubernetes.io/docs/concepts/policy/resource-quotas/)

---

### Perform a rolling update of a Deployment's image and watch the rollout  `(easy)`
<details><summary>show</summary>
<p>

```bash
# Create a Deployment with an initial image to work with
kubectl create deployment nginx-app --image=nginx:1.25 --replicas=3

# Perform a rolling update to a new image version.
# Syntax: kubectl set image deployment/<name> <container-name>=<image>:<tag>
# The container name defaults to the last path segment of the image when created imperatively.
kubectl set image deployment/nginx-app nginx=nginx:1.27
```

```bash
# verify
# Streams status until all pods are updated and AVAILABLE; exits 0 on success.
kubectl rollout status deployment/nginx-app
# Confirm the new image tag is live in the pod template:
kubectl get deployment nginx-app -o jsonpath='{.spec.template.spec.containers[0].image}'
```

</p>
</details>

---

### Roll back the Deployment to the previous revision  `(easy)`
<details><summary>show</summary>
<p>

```bash
# Inspect the revision history — each kubectl set image creates a new revision.
# CHANGE-CAUSE is populated only when --record was used or the annotation is set manually.
kubectl rollout history deployment/nginx-app

# Roll back to the immediately previous revision (revision N-1)
kubectl rollout undo deployment/nginx-app

# Optionally target a specific revision number visible in the history:
# kubectl rollout undo deployment/nginx-app --to-revision=1
```

```bash
# verify
# The history should show a new head revision reflecting the undo.
kubectl rollout history deployment/nginx-app
# Confirm the pod template image reverted to the previous tag (nginx:1.25):
kubectl get deployment nginx-app -o jsonpath='{.spec.template.spec.containers[0].image}'
```

</p>
</details>

---

### ⭐ Create an HPA targeting 50% CPU utilisation (requires metrics-server) and generate load  `(hard)`
<details><summary>show</summary>
<p>

```bash
# Note: HPA requires metrics-server to collect CPU/memory metrics from kubelets.
# Install if not present (common gap in kubeadm lab clusters):
#   kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
# Exam environments (Killer Shell / PSI) ship with metrics-server pre-installed.

# Create a Deployment with explicit CPU resource requests — the HPA cannot compute a
# percentage target without a request baseline on the pod template.
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cpu-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: cpu-app
  template:
    metadata:
      labels:
        app: cpu-app
    spec:
      containers:
      - name: cpu-app
        image: nginx:1.27
        resources:
          requests:
            cpu: "100m"
          limits:
            cpu: "200m"
EOF

# Expose the Deployment so the load-generator pod can reach it by DNS name
kubectl expose deployment cpu-app --port=80 --name=cpu-app-svc

# Create the HPA — kubectl autoscale creates an autoscaling/v2 HPA object.
# --cpu-percent=50: scale up when average CPU across pods exceeds 50 % of the request.
# --min=1 --max=10: keep replicas within these bounds regardless of load.
kubectl autoscale deployment cpu-app --cpu-percent=50 --min=1 --max=10

# Launch a load-generator pod that loops wget to push CPU usage above the threshold.
# Allow 60-90 s for the metrics pipeline to register the load and trigger scaling.
kubectl run load-gen --image=busybox:1.36 --restart=Never -- \
  /bin/sh -c "while true; do wget -q -O- http://cpu-app-svc; done"
```

```bash
# verify
# TARGETS shows <current%>/<50%>; REPLICAS climbs above 1 when the target is exceeded.
# -w streams updates every few seconds — Ctrl-C once scaling is confirmed.
kubectl get hpa cpu-app -w
# Tear down the load generator after verification:
# kubectl delete pod load-gen
```

</p>
</details>

---

### Manually schedule a pod to a node via `nodeName` (bypassing the scheduler)  `(med)`
<details><summary>show</summary>
<p>

```bash
# Find a node to target
kubectl get nodes

# Setting spec.nodeName places the pod directly on the named node.
# The default-scheduler is completely bypassed — no binding step, no scheduling queue.
# The kubelet on that node picks up the pod spec and starts it.
# Note: the named node must exist and be Ready; if not, the pod stays Pending indefinitely.
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: manual-pod
spec:
  nodeName: <node-name>   # replace with an actual node name from: kubectl get nodes
  containers:
  - name: nginx
    image: nginx:1.27
EOF

# Confirm the pod landed on the intended node (NODE column):
kubectl get pod manual-pod -o wide
```

</p>
</details>

---

### Constrain a pod to nodes with a label via `nodeSelector`  `(easy)`
<details><summary>show</summary>
<p>

```bash
# Label a node to indicate it is SSD-backed.
# Replace <node-name> with an actual node from: kubectl get nodes
kubectl label node <node-name> disktype=ssd

# Confirm the label was applied:
kubectl get node <node-name> --show-labels

# Create a pod with nodeSelector — the scheduler only considers nodes that carry
# ALL the listed labels.  If no node matches, the pod stays Pending.
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: ssd-pod
spec:
  nodeSelector:
    disktype: ssd
  containers:
  - name: nginx
    image: nginx:1.27
EOF

# Confirm the pod was scheduled on the labelled node:
kubectl get pod ssd-pod -o wide
```

</p>
</details>

---

### Create a PriorityClass and a pod that uses it; observe preemption of a lower-priority pod  `(hard)`
<details><summary>show</summary>
<p>

```bash
# Create a high-priority PriorityClass.
# scheduling.k8s.io/v1 is the stable GA API (since v1.14).
# value: 1000000 — well above the system-node-critical class (2000000 is the absolute max).
# globalDefault: false — pods must explicitly reference this class; it is not applied globally.
kubectl apply -f - <<EOF
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: high-priority
value: 1000000
globalDefault: false
description: "High-priority class for critical workloads; may preempt lower-priority pods."
EOF

# Create a low-priority class for comparison
kubectl apply -f - <<EOF
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: low-priority
value: 1000
globalDefault: false
description: "Low-priority background workloads."
EOF

# Create a pod using the high-priority class
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: high-prio-pod
spec:
  priorityClassName: high-priority
  containers:
  - name: nginx
    image: nginx:1.27
    resources:
      requests:
        cpu: "500m"
        memory: "128Mi"
EOF

# Create a pod using the low-priority class
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: low-prio-pod
spec:
  priorityClassName: low-priority
  containers:
  - name: nginx
    image: nginx:1.27
    resources:
      requests:
        cpu: "500m"
        memory: "128Mi"
EOF

# Preemption behaviour:
# When all nodes are fully occupied by low-priority pods and a high-priority pod enters
# the scheduling queue (Pending), the scheduler identifies a node where evicting one or
# more low-priority pods would free sufficient resources.  It EVICTS those pods — they are
# deleted and re-enter the queue as Pending — and then places the high-priority pod.
# Observe preemption events in a resource-constrained cluster:
kubectl get events --sort-by='.lastTimestamp' | grep -i preempt
```

</p>
</details>

---

### Apply topology spread constraints to distribute replicas across nodes  `(med)`
<details><summary>show</summary>
<p>

```bash
# topologySpreadConstraints control how pods are distributed across failure domains.
# topologyKey: kubernetes.io/hostname  — each node is its own domain.
# maxSkew: 1  — the difference in replica count between the most-loaded and least-loaded
#               domain must not exceed 1.
# whenUnsatisfiable: DoNotSchedule  — a pod stays Pending rather than violate the constraint.
#                    Use ScheduleAnyway to allow best-effort spreading without blocking.
# labelSelector  — must match the pod labels so the scheduler counts the right pods.
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: spread-app
spec:
  replicas: 4
  selector:
    matchLabels:
      app: spread-app
  template:
    metadata:
      labels:
        app: spread-app
    spec:
      topologySpreadConstraints:
      - maxSkew: 1
        topologyKey: kubernetes.io/hostname
        whenUnsatisfiable: DoNotSchedule
        labelSelector:
          matchLabels:
            app: spread-app
      containers:
      - name: nginx
        image: nginx:1.27
EOF

# Verify even distribution — NODE column shows pods spread across distinct hostnames:
kubectl get pods -l app=spread-app -o wide
```

</p>
</details>

---

### Create a ResourceQuota and a LimitRange in a namespace and observe enforcement  `(med)`
<details><summary>show</summary>
<p>

```bash
# Create an isolated namespace for quota testing
kubectl create namespace quota-demo

# ResourceQuota sets hard ceilings on aggregate consumption within the namespace.
# Once a quota exists for a resource type, every pod MUST specify requests/limits for it.
kubectl apply -f - <<EOF
apiVersion: v1
kind: ResourceQuota
metadata:
  name: compute-quota
  namespace: quota-demo
spec:
  hard:
    pods: "5"
    requests.cpu: "1"
    requests.memory: 500Mi
    limits.cpu: "2"
    limits.memory: 1Gi
EOF

# LimitRange sets per-container defaults and bounds.
# default / defaultRequest: injected into containers that omit resource fields (required
# when a namespace quota exists and the pod spec does not specify its own values).
# max / min: hard per-container upper and lower bounds the admission controller enforces.
kubectl apply -f - <<EOF
apiVersion: v1
kind: LimitRange
metadata:
  name: container-limits
  namespace: quota-demo
spec:
  limits:
  - type: Container
    default:
      cpu: "200m"
      memory: 64Mi
    defaultRequest:
      cpu: "100m"
      memory: 32Mi
    max:
      cpu: "1"
      memory: 512Mi
    min:
      cpu: "50m"
      memory: 8Mi
EOF

# Create a valid pod that fits within the quota (uses LimitRange defaults for resources)
kubectl run ok-pod --image=nginx:1.27 -n quota-demo

# Attempt to create a pod that exceeds the quota: requests.cpu "2" > remaining quota "1"
kubectl apply -n quota-demo -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: over-quota-pod
spec:
  containers:
  - name: cpu-hog
    image: nginx:1.27
    resources:
      requests:
        cpu: "2"        # 2 cores requested — exceeds the 1-core requests.cpu hard limit
        memory: 128Mi
      limits:
        cpu: "2"
        memory: 256Mi
EOF
# Expected output:
# Error from server (Forbidden): error when creating "STDIN": pods "over-quota-pod" is
# forbidden: exceeded quota: compute-quota, requested: requests.cpu=2, used: requests.cpu=100m,
# limited: requests.cpu=1
```

```bash
# verify
# Confirm the rejected pod was never created — the command returns a non-zero exit code
# and no object is persisted in the API server:
kubectl get pod over-quota-pod -n quota-demo 2>&1 || echo "Pod was rejected — not found (expected)"
# Review current quota consumption vs. hard limits:
kubectl describe resourcequota compute-quota -n quota-demo
```

</p>
</details>
