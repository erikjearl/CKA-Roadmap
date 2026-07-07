# Exam Bookmarks

The CKA exam allows one browser tab open to **kubernetes.io** (and its sub-domains). Bookmark these URLs in your exam browser before the clock starts. They are grouped by CKA domain so you can navigate fast under pressure.

> Tip: open each URL once before the exam to verify the bookmark resolves. The exam browser uses a whitelist — kubernetes.io/docs, kubernetes.io/blog, and github.com/kubernetes are typically allowed.

---

## 0. Always-Open Reference

| Topic | URL |
|-------|-----|
| kubectl cheat sheet | https://kubernetes.io/docs/reference/kubectl/cheatsheet/ |
| kubectl reference | https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands |
| API resource types | https://kubernetes.io/docs/reference/kubernetes-api/ |

---

## 1. Cluster Architecture, Installation & Configuration (25%)

| Topic | URL |
|-------|-----|
| Cluster components overview | https://kubernetes.io/docs/concepts/overview/components/ |
| kubeadm upgrade | https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade/ |
| kubeadm certs | https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-certs/ |
| etcd backup & restore | https://kubernetes.io/docs/tasks/administer-cluster/configure-upgrade-etcd/ |
| HA topology options | https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/ha-topology/ |
| Kubeconfig & contexts | https://kubernetes.io/docs/concepts/configuration/organize-cluster-access-kubeconfig/ |

---

## 2. Workloads & Scheduling (15%)

| Topic | URL |
|-------|-----|
| Deployments | https://kubernetes.io/docs/concepts/workloads/controllers/deployment/ |
| Pods | https://kubernetes.io/docs/concepts/workloads/pods/ |
| Jobs | https://kubernetes.io/docs/concepts/workloads/controllers/job/ |
| CronJobs | https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/ |
| DaemonSets | https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/ |
| Taints & Tolerations | https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/ |
| Node affinity | https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/ |
| Resource requests/limits | https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/ |
| HPA | https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/ |
| Priority & Preemption | https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/ |
| Static Pods | https://kubernetes.io/docs/tasks/configure-pod-container/static-pod/ |

---

## 3. Services & Networking (20%)

| Topic | URL |
|-------|-----|
| Services | https://kubernetes.io/docs/concepts/services-networking/service/ |
| Network Policies | https://kubernetes.io/docs/concepts/services-networking/network-policies/ |
| Ingress | https://kubernetes.io/docs/concepts/services-networking/ingress/ |
| Ingress controllers | https://kubernetes.io/docs/concepts/services-networking/ingress-controllers/ |
| Gateway API | https://kubernetes.io/docs/concepts/services-networking/gateway/ |
| DNS for Services & Pods | https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/ |
| Cluster networking | https://kubernetes.io/docs/concepts/cluster-administration/networking/ |

---

## 4. Storage (10%)

| Topic | URL |
|-------|-----|
| Persistent Volumes | https://kubernetes.io/docs/concepts/storage/persistent-volumes/ |
| Storage Classes | https://kubernetes.io/docs/concepts/storage/storage-classes/ |
| Volume types | https://kubernetes.io/docs/concepts/storage/volumes/ |
| ConfigMaps (as volumes) | https://kubernetes.io/docs/concepts/configuration/configmap/ |
| Secrets (as volumes) | https://kubernetes.io/docs/concepts/configuration/secret/ |

---

## 5. Security (20%)

| Topic | URL |
|-------|-----|
| RBAC | https://kubernetes.io/docs/reference/access-authn-authz/rbac/ |
| TLS/CSR (managing TLS) | https://kubernetes.io/docs/tasks/tls/managing-tls-in-a-cluster/ |
| Certificate signing requests | https://kubernetes.io/docs/reference/access-authn-authz/certificate-signing-requests/ |
| Security contexts | https://kubernetes.io/docs/tasks/configure-pod-container/security-context/ |
| Service accounts | https://kubernetes.io/docs/concepts/security/service-accounts/ |
| Secrets encryption at rest | https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/ |
| Network Policies (security) | https://kubernetes.io/docs/concepts/services-networking/network-policies/ |
| Resource Quotas | https://kubernetes.io/docs/concepts/policy/resource-quotas/ |

---

## 6. Troubleshooting (10%)

| Topic | URL |
|-------|-----|
| Debug cluster | https://kubernetes.io/docs/tasks/debug/debug-cluster/ |
| Debug application | https://kubernetes.io/docs/tasks/debug/debug-application/ |
| Debug running pods | https://kubernetes.io/docs/tasks/debug/debug-application/debug-running-pod/ |
| Node drain | https://kubernetes.io/docs/tasks/administer-cluster/safely-drain-node/ |
| Liveness / readiness probes | https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/ |
| Cluster proxies | https://kubernetes.io/docs/concepts/cluster-administration/proxies/ |

---

## 7. Extend Kubernetes (bonus / edge tasks)

| Topic | URL |
|-------|-----|
| Custom Resource Definitions | https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definitions/ |
| Admission controllers | https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/ |
