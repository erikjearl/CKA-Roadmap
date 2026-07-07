# CKA Study Repo Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a hands-on CKA (v1.35) study repo modeled on dgkanatsios/CKAD-exercises — flat per-domain exercise files with curated kubernetes.io doc links and collapsible solutions, plus separated exam-prep machinery and real-cluster artifacts.

**Architecture:** Pure content repo. A format contract (`TEMPLATE.md`) is authored first; every exercise file conforms to it. Exercise files live flat in `cka-exercises/`, exam-prep tooling in `practice/`, and reusable cluster artifacts in `cluster-setup/`. A standalone `PROGRESS.md` tracks confidence. No build system, no app — verification is structural (required sections present, scripts pass `bash -n`, links well-formed).

**Tech Stack:** Markdown, Bash, kubernetes.io docs. Target: Kubernetes v1.35 / CKA v1.35 curriculum. Cluster is multi-node kubeadm (Raspberry Pi `arm64` + one PC `amd64`).

## Global Constraints

- **Tracks CKA v1.35 / Kubernetes 1.35** — state this version in README and keep content aligned to it.
- **Exercise format is canonical** — every file in `cka-exercises/` matches `TEMPLATE.md`: top-of-file `> **New/deeper vs CKAD:**` callout, a `## Quick Reference — Documentation` breadcrumb list, then `### <imperative task>` headings each with a `(easy)`/`(med)`/`(hard)` text badge and a `<details><summary>show</summary>` solution.
- **Stars (`⭐`) mean "new in the 2025 refresh"** — never reuse `⭐` for difficulty. Difficulty is text: `(easy)`/`(med)`/`(hard)`. Confidence uses `🔴/🟡/🟢` and appears only in `PROGRESS.md`.
- **Verify steps only where they catch real mistakes** — etcd restore, RBAC (`kubectl auth can-i`), NetworkPolicy connectivity, cluster upgrade, cert/CSR, storage binding. Skip on trivial create tasks.
- **No inline CKAD tags** — the top-of-file callout is the only CKAD signal in exercise files.
- **Never commit real cluster secrets** — `cluster-setup/` artifacts ship as templates with placeholders (`<CONTROL_PLANE_IP>`, `<TOKEN>`, etc.), never real certs/tokens/endpoints. `.gitignore` blocks snapshots, kubeconfigs, and keys.
- **Doc links use the breadcrumb style** — `kubernetes.io > Documentation > ... > [Page Title](https://kubernetes.io/docs/...)`.

---

## File Structure

```
cka-roadmap/
├── README.md                 # orientation + version banner + domain map; links to PROGRESS.md   (Task 15)
├── PROGRESS.md               # standalone checklist + 🔴🟡🟢 confidence column                     (Task 16)
├── TEMPLATE.md               # canonical exercise format contract                                 (Task 1)
├── .gitignore                # secret/artifact exclusions                                          (Task 1)
├── cluster-setup/            # real Pi+PC kubeadm cluster artifacts                                (Task 2)
│   ├── README.md · kubeadm-config.yaml · install-cni.sh · join-node.sh · reset-cluster.sh · backup-etcd.sh
├── cka-exercises/
│   ├── README.md             # section index + weights + legend                                   (Task 12)
│   ├── 00-ckad-knowledge.md  # refresher, no drills                                                (Task 3)
│   ├── 01-cluster-architecture.md                                                                  (Task 4)
│   ├── 02-installation-cluster-mgmt.md                                                             (Task 5)
│   ├── 03-networking.md                                                                            (Task 6)
│   ├── 04-node-administration.md                                                                   (Task 7)
│   ├── 05-security.md                                                                              (Task 8)
│   ├── 06-storage.md                                                                               (Task 9)
│   ├── 07-workloads-scheduling.md                                                                  (Task 10)
│   └── 08-troubleshooting.md                                                                       (Task 11)
└── practice/
    ├── README.md · exam-setup.md · exam-bookmarks.md · mock-exams.md · day-of-exam.md · gotchas.md (Task 13)
    └── break-fix/README.md + break/reset scripts                                                   (Task 14)
```

**Build order rationale:** the format contract (Task 1) comes first because every exercise file depends on it. Exercise files (Tasks 3–11) come before the `cka-exercises/README.md` index and top-level `README.md`/`PROGRESS.md` (Tasks 12, 15, 16) so those can link to anchors that already exist and be verified.

---

### Task 1: Repo scaffold, `.gitignore`, and `TEMPLATE.md` (format contract)

**Files:**
- Create: `.gitignore`
- Create: `TEMPLATE.md`
- Create directories: `cluster-setup/`, `cka-exercises/`, `practice/break-fix/`

**Interfaces:**
- Produces: `TEMPLATE.md` — the exercise format that Tasks 3–11 consume verbatim. Defines: the `> **New/deeper vs CKAD:**` callout, `## Quick Reference — Documentation` breadcrumb block, `### <task>` headings with `(easy)/(med)/(hard)` badges, and the `<details><summary>show</summary>` / `<p>` / fenced-code / `</p></details>` solution wrapper (optionally including a `# verify` block).

- [ ] **Step 1: Create directories**

```bash
mkdir -p cluster-setup cka-exercises practice/break-fix
```

- [ ] **Step 2: Write `.gitignore`**

```gitignore
# Never commit real cluster secrets or artifacts
*.db            # etcd snapshots
*.kubeconfig
kubeconfig
admin.conf
pki/
*.key
*.crt
*.pem
*.token

# OS / editor
.DS_Store
*.swp
```

- [ ] **Step 3: Write `TEMPLATE.md`**

````markdown
# Exercise Format (canonical)

Every file in `cka-exercises/` follows this structure. Copy it when adding a section.

```markdown
# <Domain Title>

> **New/deeper vs CKAD:** <one line: what in this file is new or goes deeper than CKAD>

## Quick Reference — Documentation
kubernetes.io > Documentation > Tasks > <Area> > [<Page Title>](https://kubernetes.io/docs/...)
kubernetes.io > Documentation > Reference > kubectl CLI > [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)

### <Imperative task phrased like an exam prompt>  `(med)`
<details><summary>show</summary>
<p>

```bash
# imperative-first solution
kubectl ...
```

```bash
# verify   <-- include ONLY when end-state is non-obvious (see rules below)
kubectl ...
```

</p>
</details>
```

## Rules
- **Difficulty badge** after each `###` heading: `(easy)` / `(med)` / `(hard)`. Never use `⭐` for difficulty — `⭐` marks a topic that is new in the CKA 2025 refresh.
- **Imperative-first** solutions; add alternative approaches below the primary when useful.
- **Verify block** only for tasks where "the command ran" ≠ "it worked": etcd restore, RBAC (`kubectl auth can-i`), NetworkPolicy connectivity, cluster upgrade, cert/CSR, storage binding. Skip it on trivial create tasks.
- **No inline CKAD tags.** The top-of-file callout is the only CKAD signal.
- Confidence tracking (`🔴/🟡/🟢`) lives in `PROGRESS.md`, not here.
````

- [ ] **Step 4: Verify structure and contract**

Run:
```bash
ls -d cluster-setup cka-exercises practice/break-fix && \
grep -q "New/deeper vs CKAD" TEMPLATE.md && \
grep -q "details><summary>show" TEMPLATE.md && \
grep -q "(easy)" TEMPLATE.md && echo "OK"
```
Expected: prints the three directories then `OK`.

- [ ] **Step 5: Commit**

```bash
git add .gitignore TEMPLATE.md
git commit -m "Add repo scaffold, gitignore, and exercise format contract"
```

---

### Task 2: `cluster-setup/` — real Pi+PC kubeadm artifacts

**Files:**
- Create: `cluster-setup/README.md`, `cluster-setup/kubeadm-config.yaml`, `cluster-setup/install-cni.sh`, `cluster-setup/join-node.sh`, `cluster-setup/reset-cluster.sh`, `cluster-setup/backup-etcd.sh`

**Interfaces:**
- Produces: `cluster-setup/reset-cluster.sh` and `cluster-setup/backup-etcd.sh` — referenced by Task 14 (break-fix drills reset via `reset-cluster.sh`) and by exercise Task 5 (etcd backup/restore practice).

- [ ] **Step 1: Write `cluster-setup/kubeadm-config.yaml`** (placeholders, no real values)

```yaml
# kubeadm cluster config — mixed arch (Pi arm64 + PC amd64)
# Replace <PLACEHOLDER> values before use. Do NOT commit real tokens/IPs.
apiVersion: kubeadm.k8s.io/v1beta4
kind: InitConfiguration
localAPIEndpoint:
  advertiseAddress: "<CONTROL_PLANE_IP>"
  bindPort: 6443
---
apiVersion: kubeadm.k8s.io/v1beta4
kind: ClusterConfiguration
kubernetesVersion: "v1.35.0"
networking:
  podSubnet: "10.244.0.0/16"   # matches Flannel default; change if using another CNI
```

- [ ] **Step 2: Write `cluster-setup/install-cni.sh`**

```bash
#!/usr/bin/env bash
# Install a CNI that supports arm64 + amd64. Flannel shown; swap for Calico if preferred.
set -euo pipefail
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
echo "CNI applied. Watch nodes become Ready: kubectl get nodes -w"
```

- [ ] **Step 3: Write `cluster-setup/join-node.sh`**

```bash
#!/usr/bin/env bash
# Run on a worker (Pi or PC) to join the cluster.
# Get the real join command from the control plane with:
#   kubeadm token create --print-join-command
set -euo pipefail
JOIN_CMD="${1:-}"
if [[ -z "$JOIN_CMD" ]]; then
  echo "Usage: sudo ./join-node.sh 'kubeadm join <IP>:6443 --token <TOKEN> --discovery-token-ca-cert-hash sha256:<HASH>'"
  exit 1
fi
eval "sudo $JOIN_CMD"
```

- [ ] **Step 4: Write `cluster-setup/backup-etcd.sh`**

```bash
#!/usr/bin/env bash
# Snapshot etcd. Run on the control-plane node.
set -euo pipefail
OUT="${1:-/opt/etcd-backup-$(date +%Y%m%d-%H%M%S).db}"
sudo ETCDCTL_API=3 etcdctl snapshot save "$OUT" \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key
sudo ETCDCTL_API=3 etcdctl --write-out=table snapshot status "$OUT"
echo "Snapshot at $OUT"
```

- [ ] **Step 5: Write `cluster-setup/reset-cluster.sh`**

```bash
#!/usr/bin/env bash
# Reset a node to pre-kubeadm state. DESTRUCTIVE — use on lab nodes only.
set -euo pipefail
read -r -p "This will 'kubeadm reset' THIS node. Continue? [y/N] " ans
[[ "$ans" == "y" ]] || { echo "aborted"; exit 1; }
sudo kubeadm reset -f
sudo rm -rf /etc/cni/net.d ~/.kube/config
echo "Node reset. Re-init (control plane) or re-run join-node.sh (worker)."
```

- [ ] **Step 6: Write `cluster-setup/README.md`**

Content must cover: purpose (this cluster IS the Installation/Cluster-Mgmt lab), the mixed-arch caveat (use multi-arch images; etcd on SD cards is slow but fine), the bootstrap sequence (`kubeadm init --config kubeadm-config.yaml` → `install-cni.sh` → `kubeadm token create --print-join-command` → `join-node.sh` on each worker), and a safety note pointing at `.gitignore` (never commit real certs/tokens). Include a one-line description of each script.

- [ ] **Step 7: Verify scripts parse and README references each artifact**

Run:
```bash
chmod +x cluster-setup/*.sh && \
for s in cluster-setup/*.sh; do bash -n "$s" || exit 1; done && \
grep -q "kubeadm init" cluster-setup/README.md && echo "OK"
```
Expected: `OK` (all scripts pass syntax check).

- [ ] **Step 8: Commit**

```bash
git add cluster-setup
git commit -m "Add cluster-setup artifacts for the Pi+PC kubeadm lab"
```

---

### Task 3: `cka-exercises/00-ckad-knowledge.md` — CKAD refresher (no drills)

**Files:**
- Create: `cka-exercises/00-ckad-knowledge.md`

**Interfaces:**
- Consumes: `TEMPLATE.md` header style (callout + Quick Reference), but this file is a *refresher table*, not a drill file — no `<details>` exercises.

- [ ] **Step 1: Write the file**

Structure: `# CKAD Knowledge (Already Known)` heading; a one-line intro noting this is a fast refresher of carried-over topics, not exercises. Then one `##` subsection per topic below, each a compact "key commands + gotchas" block (2–6 lines, code-fenced where useful):
Pods, Deployments, Services, ConfigMaps, Secrets, Jobs/CronJobs, Probes, Volumes/PVCs, Resource Limits, NetworkPolicies, Helm basics, RBAC basics, Multi-container Pods, Init Containers, Security Contexts, Troubleshooting Applications.

Include a `## Quick Reference — Documentation` block linking at minimum:
```
kubernetes.io > Documentation > Reference > kubectl CLI > [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
kubernetes.io > Documentation > Concepts > Workloads > [Pods](https://kubernetes.io/docs/concepts/workloads/pods/)
```

- [ ] **Step 2: Verify all 16 topics present**

Run:
```bash
for t in Pods Deployments Services ConfigMaps Secrets Jobs Probes Volumes "Resource Limits" NetworkPolicies Helm RBAC "Multi-container" "Init Containers" "Security Contexts" "Troubleshooting"; do
  grep -qi "$t" cka-exercises/00-ckad-knowledge.md || { echo "MISSING: $t"; exit 1; }
done && echo "OK"
```
Expected: `OK`.

- [ ] **Step 3: Commit**

```bash
git add cka-exercises/00-ckad-knowledge.md
git commit -m "Add CKAD knowledge refresher"
```

---

### Tasks 4–11: Exercise files (one per domain)

Each of Tasks 4–11 creates one `cka-exercises/NN-*.md` file conforming to `TEMPLATE.md`. Each has the **same step shape**, so it is written out fully once here and referenced by the per-task exercise lists that follow:

**Per-file step shape (apply to each of Tasks 4–11):**

- [ ] **Step A: Write the file** with: the `# Title`, the `> **New/deeper vs CKAD:**` callout (text given per task), the `## Quick Reference — Documentation` breadcrumb block (links given per task), then one `### <task>` per exercise in that task's list, each with its `(easy)/(med)/(hard)` badge and a `<details><summary>show</summary><p>` solution containing correct `kubectl`/`yaml`. Add a `# verify` block only on exercises flagged **[verify]**.
- [ ] **Step B: Verify structure** —
  ```bash
  f=cka-exercises/NN-name.md
  grep -q "New/deeper vs CKAD" "$f" && \
  grep -q "Quick Reference — Documentation" "$f" && \
  test "$(grep -c '<details><summary>show' "$f")" -ge <N_EXERCISES> && echo "OK"
  ```
  Expected: `OK` (one `<details>` per exercise).
- [ ] **Step C: Commit** — `git add "$f" && git commit -m "Add <domain> exercises"`

---

### Task 4: `01-cluster-architecture.md`

**Callout:** `control-plane internals, etcd operations, CRDs & operators, and cluster extension interfaces — all new/deeper than CKAD.`

**Quick Reference links (minimum):**
- `kubernetes.io > Documentation > Concepts > Overview > [Kubernetes Components](https://kubernetes.io/docs/concepts/overview/components/)`
- `kubernetes.io > Documentation > Tasks > Administer a Cluster > [Operating etcd Clusters for Kubernetes](https://kubernetes.io/docs/tasks/administer-cluster/configure-upgrade-etcd/)`
- `kubernetes.io > Documentation > Tasks > Extend Kubernetes > [Custom Resources / CustomResourceDefinitions](https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definitions/)`

**Exercises (headings, badge, [verify] flags):**
1. List all control-plane static pod manifests on the control-plane node `(easy)`
2. Identify which component the kube-scheduler talks to and inspect its static pod spec `(easy)`
3. Inspect the kube-apiserver flags currently in effect `(med)`
4. Explain the role of the controller-manager and list the controllers it runs `(easy)`
5. Show the container runtime in use and its socket via `kubectl get nodes -o wide` and `crictl info` `(med)`
6. ⭐ Create a CustomResourceDefinition for a `Widget` resource, then create a `Widget` instance `(hard)` **[verify]** (`kubectl get widgets`)
7. ⭐ Explain the difference between a CRD and an operator; identify a running operator's controller pod `(med)`
8. ⭐ List the extension interfaces (CNI, CSI, CRI) and identify which implementation each node uses `(med)`

---

### Task 5: `02-installation-cluster-mgmt.md`

**Callout:** `bootstrapping, joining nodes, cluster upgrades, etcd backup/restore, certificate renewal, and installing components with Helm/Kustomize — the operational core of CKA. Run these against the real cluster in cluster-setup/.`

**Quick Reference links (minimum):**
- `kubernetes.io > Documentation > Tasks > Administer a Cluster > [Upgrading kubeadm clusters](https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade/)`
- `kubernetes.io > Documentation > Tasks > Administer a Cluster > [Operating etcd Clusters for Kubernetes](https://kubernetes.io/docs/tasks/administer-cluster/configure-upgrade-etcd/)`
- `kubernetes.io > Documentation > Tasks > Administer a Cluster > [Certificate Management with kubeadm](https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-certs/)`

**Exercises:**
1. Generate a new join command with a fresh token on the control plane `(easy)`
2. Join a worker node to the cluster `(med)`
3. Upgrade the control-plane node to the next patch version with kubeadm `(hard)` **[verify]** (`kubectl get nodes` shows new version)
4. Upgrade a worker node (drain → upgrade kubelet → uncordon) `(hard)` **[verify]**
5. Back up the etcd datastore to `/opt/etcd-backup.db` `(med)` **[verify]** (`etcdctl snapshot status`)
6. Restore etcd from a snapshot and point the static pod at the restored data-dir `(hard)` **[verify]** (`kubectl get pods -A` recovers)
7. Renew all control-plane certificates with kubeadm and confirm expiry dates `(med)` **[verify]** (`kubeadm certs check-expiration`)
8. ⭐ Install a component with Helm (add repo, install a chart into a namespace) `(med)`
9. ⭐ Deploy a component with Kustomize (`kubectl apply -k`) using a base + overlay `(med)`

---

### Task 6: `03-networking.md`

**Callout:** `CNI internals, CoreDNS config, Service routing/endpoints, Ingress, the Gateway API, and network troubleshooting — deeper than CKAD's app-level networking.`

**Quick Reference links (minimum):**
- `kubernetes.io > Documentation > Concepts > Services, Load Balancing, and Networking > [Service](https://kubernetes.io/docs/concepts/services-networking/service/)`
- `kubernetes.io > Documentation > Concepts > Services, Load Balancing, and Networking > [Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)`
- `kubernetes.io > Documentation > Concepts > Services, Load Balancing, and Networking > [Gateway API](https://kubernetes.io/docs/concepts/services-networking/gateway/)`

**Exercises:**
1. Expose a Deployment as ClusterIP and inspect its Endpoints/EndpointSlice `(easy)`
2. Expose a Deployment as NodePort and curl it from a node `(easy)`
3. Inspect and edit the CoreDNS ConfigMap; add a rewrite/stub domain `(med)` **[verify]** (`kubectl -n kube-system rollout status deploy/coredns`)
4. Create an Ingress routing two paths to two Services `(med)`
5. ⭐ Create a Gateway + HTTPRoute directing traffic to a Service `(hard)`
6. Diagnose why a Service returns no endpoints (selector/label mismatch) `(med)` **[verify]** (endpoints populate)
7. Verify pod-to-pod connectivity across nodes and identify the CNI in use `(med)`
8. Resolve a Service DNS name from inside a pod and troubleshoot a DNS failure `(med)`

---

### Task 7: `04-node-administration.md`

**Callout:** `node lifecycle and scheduling controls operators use — taints, affinity, drain/cordon, static pods, DaemonSets.`

**Quick Reference links (minimum):**
- `kubernetes.io > Documentation > Concepts > Scheduling, Preemption and Eviction > [Taints and Tolerations](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/)`
- `kubernetes.io > Documentation > Tasks > Administer a Cluster > [Safely Drain a Node](https://kubernetes.io/docs/tasks/administer-cluster/safely-drain-node/)`
- `kubernetes.io > Documentation > Tasks > Configure Pods and Containers > [Create static Pods](https://kubernetes.io/docs/tasks/configure-pod-container/static-pod/)`

**Exercises:**
1. Taint a node `key=value:NoSchedule` and add a matching toleration to a pod `(med)`
2. Schedule a pod to a specific node using nodeAffinity `(med)`
3. Cordon a node, then drain it ignoring DaemonSets and emptyDir `(med)` **[verify]** (`kubectl get nodes` shows SchedulingDisabled; pods rescheduled)
4. Uncordon the node and confirm it accepts pods again `(easy)`
5. Create a static pod on a node via the kubelet manifests directory `(med)` **[verify]** (mirror pod appears in `kubectl get pods`)
6. Create a DaemonSet that runs one pod per node, tolerating control-plane taint `(med)`

---

### Task 8: `05-security.md`

**Callout:** `cluster-level security — TLS/CSR workflow, advanced RBAC for users and groups, service accounts, kubeconfig contexts, secrets encryption at rest, admission control, and image policy.`

**Quick Reference links (minimum):**
- `kubernetes.io > Documentation > Reference > Access Authn Authz > [Using RBAC Authorization](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)`
- `kubernetes.io > Documentation > Tasks > TLS > [Manage TLS Certificates in a Cluster](https://kubernetes.io/docs/tasks/tls/managing-tls-in-a-cluster/)`
- `kubernetes.io > Documentation > Tasks > Administer a Cluster > [Encrypting Secret Data at Rest](https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/)`

**Exercises:**
1. Create a Role + RoleBinding granting get/list pods in a namespace to a ServiceAccount `(med)` **[verify]** (`kubectl auth can-i list pods --as=system:serviceaccount:...`)
2. Create a ClusterRole + ClusterRoleBinding for read-only cluster-wide access `(med)` **[verify]** (`kubectl auth can-i`)
3. Generate a private key + CSR for a new user, submit a CertificateSigningRequest, approve it, and fetch the signed cert `(hard)` **[verify]** (CSR `Approved,Issued`)
4. Build a kubeconfig context for that user and switch to it `(med)` **[verify]** (`kubectl config current-context`)
5. Bind the new user to a Role and confirm their permissions `(med)` **[verify]** (`kubectl auth can-i ... --as=<user>`)
6. Enable encryption at rest for Secrets via an EncryptionConfiguration `(hard)`
7. Inspect enabled admission controllers on the apiserver and explain one (e.g., NodeRestriction) `(med)`

---

### Task 9: `06-storage.md`

**Callout:** `cluster-side storage — StorageClasses, dynamic provisioning, CSI, volume expansion, and reclaim policies/access modes (lighter in CKAD).`

**Quick Reference links (minimum):**
- `kubernetes.io > Documentation > Concepts > Storage > [Persistent Volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)`
- `kubernetes.io > Documentation > Concepts > Storage > [Storage Classes](https://kubernetes.io/docs/concepts/storage/storage-classes/)`

**Exercises:**
1. Create a PersistentVolume (hostPath) and a matching PVC, and confirm they Bind `(med)` **[verify]** (`kubectl get pvc` shows `Bound`)
2. Create a StorageClass and a PVC that dynamically provisions a PV `(med)` **[verify]** (`Bound`)
3. Set a PV's reclaim policy to `Retain` and observe behavior after PVC deletion `(med)`
4. Explain the access modes (RWO/ROX/RWX/RWOP) and create a PVC requesting RWO `(easy)`
5. Expand a PVC on an expansion-capable StorageClass `(hard)` **[verify]** (capacity increases)
6. Mount a PVC into a pod and write/read a file to confirm persistence `(med)` **[verify]** (data survives pod restart)

---

### Task 10: `07-workloads-scheduling.md`

**Callout:** `workload rollout control plus the scheduling and resource-governance topics the exam adds — HPA autoscaling, manual scheduling, PriorityClass, topology spread, ResourceQuota/LimitRange.`

**Quick Reference links (minimum):**
- `kubernetes.io > Documentation > Tasks > Run Applications > [Horizontal Pod Autoscaling](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)`
- `kubernetes.io > Documentation > Concepts > Scheduling, Preemption and Eviction > [Pod Priority and Preemption](https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/)`
- `kubernetes.io > Documentation > Concepts > Policy > [Resource Quotas](https://kubernetes.io/docs/concepts/policy/resource-quotas/)`

**Exercises:**
1. Perform a rolling update of a Deployment's image and watch the rollout `(easy)` **[verify]** (`kubectl rollout status`)
2. Roll back the Deployment to the previous revision `(easy)` **[verify]** (`kubectl rollout history`)
3. ⭐ Create an HPA targeting 50% CPU (requires metrics-server) and generate load `(hard)` **[verify]** (`kubectl get hpa` shows scaling)
4. Manually schedule a pod to a node via `nodeName` (bypassing the scheduler) `(med)`
5. Constrain a pod to nodes with a label via `nodeSelector` `(easy)`
6. Create a PriorityClass and a pod that uses it; observe preemption of a lower-priority pod `(hard)`
7. Apply topology spread constraints to distribute replicas across nodes `(med)`
8. Create a ResourceQuota and a LimitRange in a namespace and observe enforcement `(med)` **[verify]** (over-quota pod is rejected)

---

### Task 11: `08-troubleshooting.md`

**Callout:** `the 30% domain — systematic diagnosis of nodes, control plane, kubelet, networking, and etcd, including node-level tools (crictl, journalctl) beyond kubectl.`

**Quick Reference links (minimum):**
- `kubernetes.io > Documentation > Tasks > Monitoring, Logging, and Debugging > [Troubleshooting Clusters](https://kubernetes.io/docs/tasks/debug/debug-cluster/)`
- `kubernetes.io > Documentation > Tasks > Monitoring, Logging, and Debugging > [Troubleshoot Applications](https://kubernetes.io/docs/tasks/debug/debug-application/)`
- `kubernetes.io > Documentation > Reference > kubectl CLI > [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)`

**Exercises:**
1. Diagnose and fix a node stuck in `NotReady` (kubelet down) using `systemctl`/`journalctl` `(hard)` **[verify]** (`kubectl get nodes` Ready)
2. Diagnose a pod stuck in `Pending` (unschedulable: taint/resources/nodeSelector) `(med)` **[verify]** (pod Runs)
3. Diagnose a `CrashLoopBackOff` pod from its logs and previous-container logs `(med)`
4. Use `crictl` on a node to list pods/containers and pull container logs when the apiserver is unhelpful `(hard)`
5. Fix a broken control-plane static pod (bad manifest under `/etc/kubernetes/manifests`) `(hard)` **[verify]** (component pod Runs)
6. Diagnose a DNS resolution failure in the cluster (CoreDNS down/misconfigured) `(med)` **[verify]** (resolution succeeds)
7. Diagnose a Service with no endpoints and restore connectivity `(med)` **[verify]** (endpoints populate)
8. Inspect resource usage with `kubectl top` after confirming metrics-server is running `(easy)`

---

### Task 12: `cka-exercises/README.md` — section index

**Files:**
- Create: `cka-exercises/README.md`

**Interfaces:**
- Consumes: the eight exercise files (Tasks 4–11) and `00-ckad-knowledge.md` (Task 3) — links to each must resolve to real files.

- [ ] **Step 1: Write the index** containing: a one-line intro; a legend (`⭐` = new in 2025 refresh; `(easy)/(med)/(hard)` = difficulty; confidence tracked in `../PROGRESS.md`); and a table mapping each file → the official CKA domain(s) it covers → weight, with a markdown link to each file:

| File | Official domain(s) | Weight |
|---|---|---|
| `00-ckad-knowledge.md` | (CKAD recap) | — |
| `01-cluster-architecture.md` | Cluster Architecture | 25% |
| `02-installation-cluster-mgmt.md` | Cluster Architecture | 25% |
| `03-networking.md` | Services & Networking | 20% |
| `04-node-administration.md` | Workloads & Scheduling / Cluster Arch | 15%/25% |
| `05-security.md` | Cluster Architecture | 25% |
| `06-storage.md` | Storage | 10% |
| `07-workloads-scheduling.md` | Workloads & Scheduling | 15% |
| `08-troubleshooting.md` | Troubleshooting | 30% |

- [ ] **Step 2: Verify every linked file exists**

Run:
```bash
cd cka-exercises && for f in $(grep -oE '[0-9]{2}-[a-z-]+\.md' README.md | sort -u); do test -f "$f" || { echo "BROKEN LINK: $f"; exit 1; }; done && echo "OK"; cd ..
```
Expected: `OK`.

- [ ] **Step 3: Commit**

```bash
git add cka-exercises/README.md
git commit -m "Add cka-exercises index with domain map"
```

---

### Task 13: `practice/` core files

**Files:**
- Create: `practice/README.md`, `practice/exam-setup.md`, `practice/exam-bookmarks.md`, `practice/mock-exams.md`, `practice/day-of-exam.md`, `practice/gotchas.md`

- [ ] **Step 1: Write `practice/exam-setup.md`** — the speed layer. Include, as copy-paste blocks:
  ```bash
  alias k=kubectl
  export do='--dry-run=client -o yaml'   # usage: k create deploy web --image=nginx $do
  export now='--force --grace-period=0'  # fast delete
  source <(kubectl completion bash) && complete -o default -F __start_kubectl k
  ```
  Plus: `kubectl explain <resource> --recursive`, JSONPath examples (`-o jsonpath='{.items[*].metadata.name}'`), `--sort-by`, custom-columns, and a minimal `~/.vimrc` (`set number expandtab shiftwidth=2 tabstop=2`) and tmux basics.

- [ ] **Step 2: Write `practice/exam-bookmarks.md`** — a curated, ordered list of kubernetes.io URLs to bookmark in the exam browser, grouped by domain. Seed it from the Quick-Reference links used in Tasks 4–11 (etcd operations, kubeadm upgrade, RBAC, TLS/CSR, NetworkPolicy, Ingress, Gateway API, StorageClasses, HPA, debug-cluster, kubectl cheat sheet).

- [ ] **Step 3: Write `practice/mock-exams.md`** — the read → drill → timed-mock cadence; pointer to the 2 free killer.sh simulator sessions included with the exam and to killercoda CKA scenarios; a template for recording mock scores and weak areas.

- [ ] **Step 4: Write `practice/day-of-exam.md`** — logistics checklist: government ID, PSI/proctor environment scan, clean desk, allowed browser tabs (kubernetes.io only), time budget (~8 min/task avg), flag-and-move-on discipline, `kubectl config use-context` at the start of every task.

- [ ] **Step 5: Write `practice/gotchas.md`** — a seeded running log (headed table: date · mistake · fix/lesson) with 2–3 example rows (e.g., "forgot `-n <ns>` → wrong namespace", "edited a mirror static pod in the API instead of the manifest file"). Note it also absorbs spaced-repetition review notes.

- [ ] **Step 6: Write `practice/README.md`** — one-paragraph orientation + a bulleted index linking to the five files above and to `break-fix/` (created next task).

- [ ] **Step 7: Verify**

Run:
```bash
for f in README exam-setup exam-bookmarks mock-exams day-of-exam gotchas; do test -f "practice/$f.md" || { echo "MISSING $f"; exit 1; }; done && \
grep -q "alias k=kubectl" practice/exam-setup.md && \
grep -q "killer.sh" practice/mock-exams.md && echo "OK"
```
Expected: `OK`.

- [ ] **Step 8: Commit**

```bash
git add practice/README.md practice/exam-setup.md practice/exam-bookmarks.md practice/mock-exams.md practice/day-of-exam.md practice/gotchas.md
git commit -m "Add practice exam-prep files"
```

---

### Task 14: `practice/break-fix/` — troubleshooting drills

**Files:**
- Create: `practice/break-fix/README.md`, `practice/break-fix/break-kubelet.sh`, `practice/break-fix/break-static-pod.sh`, `practice/break-fix/break-service-selector.sh`

**Interfaces:**
- Consumes: `cluster-setup/reset-cluster.sh` (referenced in README as the recovery path for destructive breaks).

- [ ] **Step 1: Write `practice/break-fix/break-kubelet.sh`**

```bash
#!/usr/bin/env bash
# DRILL: stop the kubelet so the node goes NotReady. Practice diagnosing with
# systemctl/journalctl, then FIX by starting it again. Lab nodes only.
set -euo pipefail
echo "Stopping kubelet on $(hostname). Diagnose with: systemctl status kubelet; journalctl -u kubelet"
sudo systemctl stop kubelet
echo "FIX when done:  sudo systemctl start kubelet && kubectl get nodes"
```

- [ ] **Step 2: Write `practice/break-fix/break-static-pod.sh`**

```bash
#!/usr/bin/env bash
# DRILL: corrupt a control-plane static pod manifest. Practice restoring it.
# Backs the manifest up first so you can recover.
set -euo pipefail
M=/etc/kubernetes/manifests/kube-scheduler.yaml
sudo cp "$M" "/tmp/$(basename "$M").bak"
echo "  invalid: yaml: [broken" | sudo tee -a "$M" >/dev/null
echo "Broke $M (backup at /tmp/$(basename "$M").bak). Diagnose the scheduler pod, then restore."
```

- [ ] **Step 3: Write `practice/break-fix/break-service-selector.sh`**

```bash
#!/usr/bin/env bash
# DRILL: patch a Service selector to a non-matching label so endpoints empty out.
# Usage: ./break-service-selector.sh <namespace> <service>
set -euo pipefail
NS="${1:?namespace}"; SVC="${2:?service}"
kubectl -n "$NS" patch svc "$SVC" -p '{"spec":{"selector":{"app":"does-not-exist"}}}'
echo "Broke $NS/$SVC selector. Diagnose empty endpoints with: kubectl -n $NS get endpoints $SVC"
```

- [ ] **Step 4: Write `practice/break-fix/README.md`** — explain the break → diagnose → fix → reset loop; one line per script; a prominent warning that these are DESTRUCTIVE and for lab nodes only; and that a full node recovery path is `../../cluster-setup/reset-cluster.sh` followed by re-join.

- [ ] **Step 5: Verify scripts parse and README warns**

Run:
```bash
chmod +x practice/break-fix/*.sh && \
for s in practice/break-fix/*.sh; do bash -n "$s" || exit 1; done && \
grep -qi "DESTRUCTIVE\|lab nodes only" practice/break-fix/README.md && echo "OK"
```
Expected: `OK`.

- [ ] **Step 6: Commit**

```bash
git add practice/break-fix
git commit -m "Add break-fix troubleshooting drill scripts"
```

---

### Task 15: Top-level `README.md`

**Files:**
- Create: `README.md`

**Interfaces:**
- Consumes: all directories and `PROGRESS.md` (Task 16) — links must resolve. (Write the `PROGRESS.md` link now; Task 16 creates the file.)

- [ ] **Step 1: Write `README.md`** containing:
  - Title + a **version banner**: "Tracks CKA v1.35 / Kubernetes 1.35".
  - One-paragraph purpose (hands-on CKA study, CKAD already passed).
  - **How to use**: read the Quick-Reference docs → drill the tasks → verify → log mistakes in `practice/gotchas.md`.
  - **Exam format table** (2h, ~66% pass, performance-based, multiple clusters, kubernetes.io docs allowed).
  - **Domain map table** (official 5 domains + weights: Troubleshooting 30, Cluster Arch 25, Networking 20, Workloads 15, Storage 10).
  - A **directory guide** linking to `cka-exercises/`, `practice/`, `cluster-setup/`.
  - A prominent link to **`PROGRESS.md`** as the tracker.

- [ ] **Step 2: Verify**

Run:
```bash
grep -q "v1.35" README.md && grep -q "PROGRESS.md" README.md && \
grep -q "30%" README.md && grep -q "cka-exercises" README.md && echo "OK"
```
Expected: `OK`.

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "Add top-level README with orientation and domain map"
```

---

### Task 16: `PROGRESS.md` — standalone confidence tracker

**Files:**
- Create: `PROGRESS.md`

**Interfaces:**
- Consumes: every exercise file (Tasks 3–11) — each topic row links into the relevant file (and `practice/` where applicable).

- [ ] **Step 1: Write `PROGRESS.md`** — intro line explaining `🔴 not started / 🟡 shaky / 🟢 confident`, then one section per exercise file (in study order), each a table:

```markdown
## 01 — Cluster Architecture  ([exercises](cka-exercises/01-cluster-architecture.md))
| Topic | Confidence |
|---|---|
| Control-plane components | 🔴 |
| etcd operations | 🔴 |
| ⭐ CRDs & operators | 🔴 |
| Extension interfaces (CNI/CSI/CRI) | 🔴 |
```

Cover every topic named in Tasks 3–11 (initialize all to 🔴). Add a top section linking `practice/exam-setup.md` and `practice/mock-exams.md` as prerequisites/cadence.

- [ ] **Step 2: Verify links and confidence legend**

Run:
```bash
grep -q "🔴" PROGRESS.md && grep -q "🟢" PROGRESS.md && \
for f in $(grep -oE 'cka-exercises/[0-9]{2}-[a-z-]+\.md' PROGRESS.md | sort -u); do test -f "$f" || { echo "BROKEN: $f"; exit 1; }; done && echo "OK"
```
Expected: `OK`.

- [ ] **Step 3: Commit**

```bash
git add PROGRESS.md
git commit -m "Add standalone progress/confidence tracker"
```

---

## Self-Review

**1. Spec coverage:**
- §3 top-level structure → Tasks 1, 2, 12–16 (every file/dir accounted for). ✓
- §4 exercise format + `TEMPLATE.md` → Task 1 (contract), Tasks 3–11 (conformance), verify-only-where-useful encoded via **[verify]** flags. ✓
- §5 content coverage (incl. ⭐ new topics: CRDs/operators, Helm/Kustomize, Gateway API, HPA; plus CSR approval, crictl/journalctl, manual scheduling/PriorityClass/topology-spread, ResourceQuota/LimitRange, reclaim policies/access modes) → all present in Tasks 4–11 and flagged. ✓
- §6 practice machinery → Tasks 13 (exam-setup, exam-bookmarks, mock-exams, day-of-exam, gotchas) + 14 (break-fix). ✓
- §7 hygiene (.gitignore, placeholders-only cluster artifacts) → Task 1 (.gitignore) + Task 2 (placeholder artifacts). ✓
- §8 README + PROGRESS split → Tasks 15 + 16. ✓
- §9 YAGNI (no nesting, no long-form notes, spaced-rep folded into gotchas) → respected; flat files, refresher table, gotchas note in Task 13/16. ✓

**2. Placeholder scan:** Exercise *solutions* are authored at execution, but each exercise is fully specified by an exact imperative heading, difficulty, and verify flag — no "TBD/handle edge cases" language. Structural files (.gitignore, TEMPLATE.md, all scripts) contain complete content. ✓

**3. Type/name consistency:** File names are identical across the tree diagram, per-task headers, `cka-exercises/README.md` table (Task 12), and `PROGRESS.md` links (Task 16). `reset-cluster.sh`/`backup-etcd.sh` names match between Task 2 (producer) and Tasks 5/14 (consumers). ✓
