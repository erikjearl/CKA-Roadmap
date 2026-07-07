# CKA Mock Exam 01

**Kubernetes version:** v1.35  
**Time budget:** 45 minutes  
**Passing score:** 66 / 100

---

## Rules

1. **Allowed resources:** [kubernetes.io/docs](https://kubernetes.io/docs) only — no local notes.
2. **Order:** Tasks may be completed in any order. Harder tasks are worth more; skip and return if stuck.
3. **Grading:** When time expires (or sooner), run the auto-grader:
   ```bash
   bash practice/mocks/grade-mock-01.sh
   ```
4. **Retake:** To reset all resources and start fresh:
   ```bash
   bash practice/mocks/reset-mock-01.sh
   ```
5. **Solutions:** Only open `practice/mocks/mock-01-solutions.md` after grading.

---

## Scoring Table

| Task | Topic | Weight |
|------|-------|--------|
| 1 | Deployment with resource requests/limits | 12% |
| 2 | RBAC — ServiceAccount, Role, RoleBinding | 15% |
| 3 | NetworkPolicy — default-deny + allow rule | 18% |
| 4 | PersistentVolume + PersistentVolumeClaim | 15% |
| 5 | PriorityClass + Pod using it | 20% |
| 6 | HorizontalPodAutoscaler | 20% |
| **Total** | | **100%** |

---

## Task 1 — 12%
**Namespace:** `mock01-web` (create it)

Create a Deployment named `web` in namespace `mock01-web` with the following specification:

- **Image:** `nginx:1.27`
- **Replicas:** 3
- Each container must have:
  - Resource **request**: `cpu: 100m`, `memory: 64Mi`
  - Resource **limit**: `memory: 128Mi`

All 3 replicas must reach `Ready` state.

---

## Task 2 — 15%
**Namespace:** `mock01-rbac` (create it)

In namespace `mock01-rbac`, create:

1. A **ServiceAccount** named `app-sa`.
2. A **Role** named `pod-reader` that allows only `get` and `list` on `pods`.
3. A **RoleBinding** named `app-sa-binding` that grants the `pod-reader` Role to the `app-sa` ServiceAccount.

The ServiceAccount must **not** be able to `delete` pods.

---

## Task 3 — 18%
**Namespace:** `mock01-web`

Create a **NetworkPolicy** named `web-allow-frontend` in namespace `mock01-web` with these requirements:

- Select pods with label `app=web`.
- Deny **all** other ingress traffic to those pods.
- Allow ingress on **TCP port 80** from pods labeled `role=frontend` in the **same namespace**.

Use `policyTypes: [Ingress]` so that all ingress not explicitly allowed is denied.

---

## Task 4 — 15%

Create the following storage resources:

1. A **PersistentVolume** named `mock01-pv`:
   - `hostPath`: `/mnt/mock01`
   - Capacity: `1Gi`
   - Access mode: `ReadWriteOnce`
   - `storageClassName`: `manual`

2. A **Namespace** named `mock01-data` (create it), then a **PersistentVolumeClaim** named `data-pvc` in that namespace:
   - Requested storage: `1Gi`
   - Access mode: `ReadWriteOnce`
   - `storageClassName`: `manual`

The PVC must reach **Bound** status and bind to `mock01-pv`.

---

## Task 5 — 20%

1. Create a **PriorityClass** named `mock01-high`:
   - `value`: `100000`
   - `globalDefault`: `false` (must **not** be the global default)

2. In namespace `mock01-web`, create a **Pod** named `important`:
   - Image: `nginx:1.27`
   - Must reference `priorityClassName: mock01-high`

---

## Task 6 — 20%
**Namespace:** `mock01-web`

Create a **HorizontalPodAutoscaler** named `web` in namespace `mock01-web` that autoscales the `web` Deployment with:

- `minReplicas`: 2
- `maxReplicas`: 5
- Target **CPU average utilization**: 50%

---

*When finished, run: `bash practice/mocks/grade-mock-01.sh`*
