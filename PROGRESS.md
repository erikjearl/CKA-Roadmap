# CKA Study Progress

**Confidence key:** 🔴 not started / 🟡 shaky / 🟢 confident

---

## Prerequisites

Before drilling exercises, complete these first:

| Resource | Purpose |
|---|---|
| [Exam setup](practice/exam-setup.md) | Terminal config, aliases, docs tab — do this before any timed practice |
| [Mock exams](practice/mock-exams.md) | Cadence guide for timed full-length runs |

---

## 00 — CKAD Recap  ([reference](cka-exercises/00-ckad-knowledge.md))

| Topic | Confidence |
|---|---|
| Pods (run, exec, logs, debug shell) | 🔴 |
| Deployments (create, set image, scale) | 🔴 |
| Services (ClusterIP, NodePort, expose) | 🔴 |
| ConfigMaps | 🔴 |
| Secrets | 🔴 |
| Jobs & CronJobs | 🔴 |
| Probes (liveness, readiness, startup) | 🔴 |
| Volumes & PVCs | 🔴 |
| Resource limits & QoS classes | 🔴 |
| NetworkPolicies | 🔴 |
| Helm basics | 🔴 |
| RBAC basics (Role, RoleBinding, can-i) | 🔴 |
| Multi-container pods (sidecar, ambassador, adapter) | 🔴 |
| Init containers | 🔴 |
| Security contexts | 🔴 |
| Troubleshooting applications (CrashLoopBackOff, ImagePullBackOff) | 🔴 |

---

## 01 — Cluster Architecture  ([exercises](cka-exercises/01-cluster-architecture.md))

| Topic | Confidence |
|---|---|
| Control-plane components (static pod manifests) | 🔴 |
| Scheduler internals (watches apiserver, binding) | 🔴 |
| kube-apiserver flags | 🔴 |
| Controller-manager (embedded controllers) | 🔴 |
| Container runtime & crictl | 🔴 |
| ⭐ CRDs & operators | 🔴 |
| ⭐ Extension interfaces (CNI / CSI / CRI) | 🔴 |

---

## 02 — Installation & Cluster Management  ([exercises](cka-exercises/02-installation-cluster-mgmt.md))

| Topic | Confidence |
|---|---|
| Bootstrap token & node join | 🔴 |
| Control-plane upgrade with kubeadm | 🔴 |
| Worker node upgrade (drain → upgrade → uncordon) | 🔴 |
| etcd backup (etcdctl snapshot save) | 🔴 |
| etcd restore (snapshot restore + manifest edit) | 🔴 |
| Certificate renewal (kubeadm certs renew) | 🔴 |
| ⭐ Helm (add repo, install chart) | 🔴 |
| ⭐ Kustomize (base + overlay, kubectl apply -k) | 🔴 |

---

## 03 — Networking  ([exercises](cka-exercises/03-networking.md))

| Topic | Confidence |
|---|---|
| ClusterIP service & Endpoints / EndpointSlice | 🔴 |
| NodePort service | 🔴 |
| CoreDNS ConfigMap (rewrite, stub zone) | 🔴 |
| Ingress (path-based routing) | 🔴 |
| ⭐ Gateway API (Gateway + HTTPRoute) | 🔴 |
| Service endpoint diagnosis (selector/label mismatch) | 🔴 |
| Pod-to-pod connectivity & CNI identification | 🔴 |
| DNS resolution troubleshooting | 🔴 |
| NetworkPolicy — default-deny ingress | 🔴 |
| NetworkPolicy — namespace-scoped allow rule | 🔴 |
| NetworkPolicy — egress restriction (DNS-only) | 🔴 |

---

## 04 — Node Administration  ([exercises](cka-exercises/04-node-administration.md))

| Topic | Confidence |
|---|---|
| Taints & tolerations | 🔴 |
| Node affinity (requiredDuringScheduling) | 🔴 |
| Cordon & drain (ignore DaemonSets, emptyDir) | 🔴 |
| Uncordon | 🔴 |
| Static pods (kubelet manifests directory) | 🔴 |
| DaemonSets (including control-plane toleration) | 🔴 |

---

## 05 — Security  ([exercises](cka-exercises/05-security.md))

| Topic | Confidence |
|---|---|
| Role & RoleBinding (ServiceAccount) | 🔴 |
| ClusterRole & ClusterRoleBinding | 🔴 |
| CSR workflow (openssl → CertificateSigningRequest → approve) | 🔴 |
| kubeconfig contexts (set-credentials, set-context, use-context) | 🔴 |
| RBAC permission verification (kubectl auth can-i) | 🔴 |
| Encryption at rest (EncryptionConfiguration + apiserver flag) | 🔴 |
| Admission controllers & NodeRestriction | 🔴 |

---

## 06 — Storage  ([exercises](cka-exercises/06-storage.md))

| Topic | Confidence |
|---|---|
| PersistentVolume (hostPath) & PVC static binding | 🔴 |
| StorageClass & dynamic provisioning | 🔴 |
| Reclaim policies (Retain vs Delete) | 🔴 |
| Access modes (RWO / ROX / RWX / RWOP) | 🔴 |
| Volume expansion (allowVolumeExpansion) | 🔴 |
| PVC mount & data persistence across pod recreation | 🔴 |

---

## 07 — Workloads & Scheduling  ([exercises](cka-exercises/07-workloads-scheduling.md))

| Topic | Confidence |
|---|---|
| Rolling update & rollback | 🔴 |
| ⭐ HPA (horizontal pod autoscaling, CPU target) | 🔴 |
| Manual scheduling via nodeName | 🔴 |
| nodeSelector | 🔴 |
| PriorityClass & preemption | 🔴 |
| Topology spread constraints | 🔴 |
| ResourceQuota & LimitRange | 🔴 |

---

## 08 — Troubleshooting  ([exercises](cka-exercises/08-troubleshooting.md))

| Topic | Confidence |
|---|---|
| Node NotReady — kubelet down (systemctl, journalctl) | 🔴 |
| Pod Pending — scheduling failure (taint/resources/affinity) | 🔴 |
| CrashLoopBackOff — logs & previous container logs | 🔴 |
| crictl (node-level inspection when apiserver unavailable) | 🔴 |
| Broken control-plane static pod (manifest repair) | 🔴 |
| DNS resolution failure (CoreDNS down or misconfigured) | 🔴 |
| Service with no endpoints (selector/targetPort mismatch) | 🔴 |
| Resource usage (kubectl top nodes/pods) | 🔴 |
| Deployment stuck mid-rollout (ProgressDeadlineExceeded) | 🔴 |
| OOMKilled diagnosis & resource-limit fix | 🔴 |
| API server unreachable (connection refused recovery) | 🔴 |
| Sorted output to file (--sort-by, jsonpath) | 🔴 |
