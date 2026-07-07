# CKA Mock Exam 01 — Solutions

> **Stop here if you have not yet run the grader.**
> Open this file only after completing `bash practice/mocks/grade-mock-01.sh`.

---

## Task 1 — Deployment with resource requests/limits (12%)

<details><summary>show</summary>

```bash
# Create namespace
kubectl create namespace mock01-web

# Create Deployment (imperative draft, then patch resources)
kubectl create deployment web \
  --image=nginx:1.27 \
  --replicas=3 \
  --namespace=mock01-web \
  --dry-run=client -o yaml > /tmp/web-deploy.yaml
```

Edit `/tmp/web-deploy.yaml` to add resources under `containers[0]`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
  namespace: mock01-web
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
      - name: web
        image: nginx:1.27
        resources:
          requests:
            cpu: 100m
            memory: 64Mi
          limits:
            memory: 128Mi
```

```bash
kubectl apply -f /tmp/web-deploy.yaml

# Verify
kubectl rollout status deployment/web -n mock01-web
kubectl get deployment web -n mock01-web
```

</details>

---

## Task 2 — RBAC (15%)

<details><summary>show</summary>

```bash
# Create namespace
kubectl create namespace mock01-rbac

# ServiceAccount
kubectl create serviceaccount app-sa -n mock01-rbac

# Role — only get and list on pods
kubectl create role pod-reader \
  --verb=get,list \
  --resource=pods \
  -n mock01-rbac

# RoleBinding
kubectl create rolebinding app-sa-binding \
  --role=pod-reader \
  --serviceaccount=mock01-rbac:app-sa \
  -n mock01-rbac

# Verify
kubectl auth can-i get pods \
  --as=system:serviceaccount:mock01-rbac:app-sa \
  -n mock01-rbac   # should print: yes

kubectl auth can-i delete pods \
  --as=system:serviceaccount:mock01-rbac:app-sa \
  -n mock01-rbac   # should print: no
```

</details>

---

## Task 3 — NetworkPolicy (18%)

<details><summary>show</summary>

The fastest approach is a YAML file — there is no imperative command for NetworkPolicy.

```yaml
# /tmp/web-netpol.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: web-allow-frontend
  namespace: mock01-web
spec:
  podSelector:
    matchLabels:
      app: web
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          role: frontend
    ports:
    - protocol: TCP
      port: 80
```

```bash
kubectl apply -f /tmp/web-netpol.yaml

# Verify
kubectl get networkpolicy web-allow-frontend -n mock01-web -o yaml
```

**Key points:**
- `policyTypes: [Ingress]` with no additional ingress rules beyond the one listed means all other ingress is denied.
- `from.podSelector` without `namespaceSelector` restricts to the same namespace only.

</details>

---

## Task 4 — PersistentVolume + PersistentVolumeClaim (15%)

<details><summary>show</summary>

PV and PVC must be created from YAML (no full imperative command for PV).

```yaml
# /tmp/mock01-pv.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: mock01-pv
spec:
  capacity:
    storage: 1Gi
  accessModes:
  - ReadWriteOnce
  storageClassName: manual
  hostPath:
    path: /mnt/mock01
```

```bash
kubectl apply -f /tmp/mock01-pv.yaml

# Create namespace
kubectl create namespace mock01-data
```

```yaml
# /tmp/data-pvc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: data-pvc
  namespace: mock01-data
spec:
  accessModes:
  - ReadWriteOnce
  storageClassName: manual
  resources:
    requests:
      storage: 1Gi
```

```bash
kubectl apply -f /tmp/data-pvc.yaml

# Verify binding
kubectl get pvc data-pvc -n mock01-data
# STATUS should be Bound, VOLUME should be mock01-pv
```

</details>

---

## Task 5 — PriorityClass + Pod (20%)

<details><summary>show</summary>

```bash
# PriorityClass — imperative
kubectl create priorityclass mock01-high \
  --value=100000 \
  --global-default=false \
  --description="High priority class for mock exam"
```

Or YAML equivalent:

```yaml
# /tmp/mock01-pc.yaml
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: mock01-high
value: 100000
globalDefault: false
description: "High priority class for mock exam"
```

```bash
# Pod using the PriorityClass
kubectl run important \
  --image=nginx:1.27 \
  --namespace=mock01-web \
  --dry-run=client -o yaml > /tmp/important-pod.yaml
```

Edit `/tmp/important-pod.yaml` to add `priorityClassName`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: important
  namespace: mock01-web
spec:
  priorityClassName: mock01-high
  containers:
  - name: important
    image: nginx:1.27
```

```bash
kubectl apply -f /tmp/important-pod.yaml

# Verify
kubectl get pod important -n mock01-web -o jsonpath='{.spec.priorityClassName}'
# Output: mock01-high
kubectl get pod important -n mock01-web -o jsonpath='{.spec.priority}'
# Output: 100000
```

</details>

---

## Task 6 — HorizontalPodAutoscaler (20%)

<details><summary>show</summary>

```bash
# Imperative (autoscaling/v2 is default in v1.35)
kubectl autoscale deployment web \
  --namespace=mock01-web \
  --name=web \
  --min=2 \
  --max=5 \
  --cpu-percent=50
```

Or YAML (autoscaling/v2):

```yaml
# /tmp/web-hpa.yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: web
  namespace: mock01-web
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: web
  minReplicas: 2
  maxReplicas: 5
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 50
```

```bash
kubectl apply -f /tmp/web-hpa.yaml

# Verify
kubectl get hpa web -n mock01-web
kubectl get hpa web -n mock01-web -o yaml
```

</details>
