# CKA Study Repo — Design Spec

**Date:** 2026-07-07
**Tracks:** CKA curriculum v1.35 (Kubernetes 1.35)
**Author context:** User has already passed CKAD; this repo focuses on *new* CKA material while flagging carried-over CKAD knowledge.

---

## 1. Purpose & Goals

Build a self-study repository for the Certified Kubernetes Administrator (CKA) exam,
modeled on the format of [dgkanatsios/CKAD-exercises](https://github.com/dgkanatsios/CKAD-exercises)
— the format that worked for the user studying CKAD.

**Core principles:**
- **Hands-on over reading.** Real tasks the user types against a live cluster, not prose notes.
- **The docs are the notes.** Each section leads with curated kubernetes.io breadcrumb links to
  read *before* attempting the tasks. Only kubernetes.io docs are allowed in the exam, so this
  doubles as exam-day muscle memory.
- **CKAD context is separated, not inlined.** Carried-over knowledge lives in one recap file;
  each new-material file has a single "New/deeper vs CKAD" callout at the top. No per-task tags.
- **Leverage the real cluster.** The user has a self-hosted multi-node `kubeadm` cluster
  (Raspberry Pi nodes = `arm64`, one PC node = `amd64`). This is a first-class asset:
  it *is* the Installation/Cluster-Management lab, and it powers troubleshooting drills.

**Success criteria:** full v1.35 curriculum coverage, exercises drillable against the real
cluster, exam-prep machinery (speed setup, mock cadence, bookmarks) kept separate from the
exercises themselves.

---

## 2. Exam Reference (for the README)

Performance-based, 2 hours, ~66% to pass, multiple clusters, kubernetes.io docs allowed,
tracks Kubernetes v1.35. Official domains and weights:

| Domain | Weight |
|---|---|
| Troubleshooting | 30% |
| Cluster Architecture, Installation & Configuration | 25% |
| Services & Networking | 20% |
| Workloads & Scheduling | 15% |
| Storage | 10% |

The repo re-slices these into work-oriented files (below); the README maps each file back to
the official domain(s) so nothing is missed.

---

## 3. Top-Level Structure

```
cka-roadmap/
├── README.md                        # Roadmap: how-to-use, exam format, domain-map → official 5
│                                    #   (+weights), version banner, progress + 🔴🟡🟢 confidence tracker
├── TEMPLATE.md                      # Exercise format guide — keeps files consistent as repo grows
├── .gitignore                       # Never commit real cluster secrets (see §7)
│
├── cluster-setup/                   # The real Pi+PC kubeadm cluster as reusable artifacts
│   ├── README.md                    #   build/reset/upgrade notes, mixed arm64/amd64 gotchas
│   ├── kubeadm-config.yaml
│   ├── install-cni.sh
│   ├── join-node.sh
│   ├── reset-cluster.sh
│   └── backup-etcd.sh
│
├── cka-exercises/                   # dgkanatsios-style: Quick-Ref doc links + tasks + <details> solutions
│   ├── README.md                    #   section index + weights + "New vs CKAD" legend
│   ├── 00-ckad-knowledge.md         #   recap of carried-over CKAD topics (refresher, no drills)
│   ├── 01-cluster-architecture.md
│   ├── 02-installation-cluster-mgmt.md
│   ├── 03-networking.md
│   ├── 04-node-administration.md
│   ├── 05-security.md
│   ├── 06-storage.md
│   ├── 07-workloads-scheduling.md
│   └── 08-troubleshooting.md
│
└── practice/                        # Exam-prep machinery, kept separate from exercises
    ├── README.md
    ├── exam-setup.md                # aliases, dry-run, kubectl explain, JSONPath/custom-columns, vim/tmux
    ├── exam-bookmarks.md            # curated, ordered kubernetes.io URLs to bookmark in-exam
    ├── mock-exams.md                # timed scenario sets + killer.sh / killercoda pointers & cadence
    ├── day-of-exam.md               # logistics checklist (ID, PSI scan, allowed tabs, time strategy)
    ├── gotchas.md                   # running log of the user's own mistakes for exam-week review
    └── break-fix/                   # scripts that deliberately break the cluster for troubleshooting drills
        └── README.md
```

---

## 4. Exercise File Format (per `cka-exercises/*.md`)

Each domain file follows this exact structure (defined canonically in `TEMPLATE.md`):

```markdown
# Cluster Architecture

> **New/deeper vs CKAD:** control-plane internals, etcd ops, CRDs & operators, extension interfaces.

## Quick Reference — Documentation
kubernetes.io > Documentation > Tasks > Administer a Cluster > [Operating etcd Clusters](url)
kubernetes.io > Documentation > Reference > kubectl CLI > [kubectl Cheat Sheet](url)

### Back up the etcd datastore to /opt/etcd-backup.db  ⭐⭐
<details><summary>show</summary>
<p>

​```bash
ETCDCTL_API=3 etcdctl snapshot save /opt/etcd-backup.db \
  --endpoints=https://127.0.0.1:2379 --cacert=... --cert=... --key=...
​```

​```bash
# verify
ETCDCTL_API=3 etcdctl --write-out=table snapshot status /opt/etcd-backup.db
​```

</p>
</details>
```

**Conventions:**
- **Task headings** are imperative statements (`### Do X...`), phrased like exam tasks.
- **Difficulty badge** after the heading: `⭐` easy / `⭐⭐` moderate / `⭐⭐⭐` hard.
- **Solutions** hidden in `<details><summary>show</summary>` with fenced `bash`/`yaml` blocks.
  Show imperative-first approaches; alternatives welcome (as in dgkanatsios).
- **Verify step** — included **only where it catches real mistakes** (end-state non-obvious or
  common failure mode): etcd restore, RBAC (`kubectl auth can-i`), NetworkPolicy connectivity,
  cluster upgrade, cert/CSR, storage binding. Skipped on trivial create tasks.
- **No inline CKAD tags.** The top-of-file callout is the only CKAD signal.

`00-ckad-knowledge.md` is a lighter refresher (topic → key commands → gotchas), no drills:
Pods, Deployments, Services, ConfigMaps, Secrets, Jobs/CronJobs, Probes, Volumes/PVCs,
Resource Limits, NetworkPolicies, Helm basics, RBAC basics, Multi-container Pods,
Init Containers, Security Contexts, Troubleshooting Applications.

---

## 5. Content Coverage (per exercise file)

Maps the user's work-oriented groupings to full v1.35 coverage. ⭐ = new in the 2025 refresh.

- **01 Cluster Architecture** — control-plane components, etcd, kubelet, kube-proxy, container
  runtime, scheduler, controller-manager, ⭐CRDs & operators, extension interfaces (CNI/CSI/CRI).
- **02 Installation & Cluster Management** — kubeadm, join nodes, upgrade cluster, backup etcd,
  restore etcd, certificates, manage node roles, ⭐Helm & Kustomize (installing components).
  *(Exercises run against the real `cluster-setup/` cluster.)*
- **03 Networking** — CNI, pod networking, CoreDNS, kube-proxy, service routing, Ingress,
  ⭐Gateway API, network troubleshooting.
- **04 Node Administration** — taints & tolerations, affinity, drain, cordon/uncordon,
  static pods, DaemonSets.
- **05 Security** — TLS certificates, RBAC (advanced), service accounts, kubeconfig,
  secrets encryption, admission controllers, image policies, **CSR approval** (create/approve
  user certs, wire up RBAC).
- **06 Storage** — PV/PVC, StorageClass, CSI, volume expansion, **reclaim policies & access
  modes (explicit)**, troubleshooting.
- **07 Workloads & Scheduling** — rolling updates/rollbacks, ⭐HPA autoscaling, **manual
  scheduling (`nodeName`), `nodeSelector`, PriorityClass & preemption, topology spread
  constraints**, **ResourceQuota / LimitRange / namespaces**.
- **08 Troubleshooting** — node NotReady, pod Pending, DNS issues, networking, scheduler,
  kubelet, control plane, etcd, **`crictl`** (node-level container inspection),
  **`journalctl`/`systemctl`** for kubelet debugging.

---

## 6. Study-Plan Machinery (`practice/`)

- **exam-setup.md** — the speed layer: `alias k=kubectl`, `export do='--dry-run=client -o yaml'`,
  `kubectl explain`, shell autocompletion, `vim`/`tmux` config, JSONPath / custom-columns /
  `--sort-by`. *Do this first.*
- **exam-bookmarks.md** — consolidated, ordered kubernetes.io URLs to bookmark in the exam
  browser (fed by the per-file Quick-Reference boxes).
- **mock-exams.md** — timed scenario sets plus pointers to the 2 free killer.sh simulator
  sessions and killercoda scenarios; suggested read → drill → timed-mock cadence.
- **day-of-exam.md** — logistics checklist: ID, PSI environment scan, allowed tabs,
  time strategy, flag-and-move-on discipline.
- **gotchas.md** — running personal log of mistakes made while drilling (also absorbs any
  spaced-repetition review notes).
- **break-fix/** — small scripts that deliberately break the real cluster (stop kubelet,
  corrupt a static-pod manifest, misconfigure a Service) so Troubleshooting (30%) can be
  rehearsed on real hardware, then reset via `cluster-setup/reset-cluster.sh`.

---

## 7. Repo Hygiene & Safety

Because the repo touches a real cluster, **never commit real secrets.** `.gitignore` excludes:
```
*.db            # etcd snapshots
*.kubeconfig
kubeconfig
admin.conf
pki/
*.key
*.crt
```
`cluster-setup/` artifacts are committed as **templates/scripts with placeholders**, never with
real cluster certs, tokens, or endpoints baked in.

---

## 8. README as Tracker

The top-level `README.md` is the entry point and progress tracker:
- Version banner ("Tracks CKA v1.35 / Kubernetes 1.35").
- How-to-use (read Quick-Ref docs → drill tasks → verify → log gotchas).
- Exam format table + domain map (work-file → official domain + weight).
- A checklist with a **🔴/🟡/🟢 confidence column** per topic, linking into both
  `cka-exercises/` and `practice/`.

---

## 9. Explicitly Out of Scope (YAGNI)

- Separate `PROGRESS.md` (the README tracker suffices).
- Standalone spaced-repetition log (folded into `gotchas.md`).
- Per-topic subfolders / nested trees (the flat one-file-per-domain model is *why* the
  reference repo worked — do not reintroduce nesting).
- Long-form written concept notes (replaced by curated doc links + hands-on tasks).
