# Day-of-Exam Checklist

## Before You Start

- [ ] **Government-issued photo ID** — passport or driver's license, must match the name on your exam registration exactly.
- [ ] **Clean desk** — nothing on the desk except your ID and the computer. No notebooks, sticky notes, or extra monitors.
- [ ] **Room scan** — the PSI proctor will ask you to do a 360-degree webcam scan of the room. Remove:
  - Books, binders, and printed notes
  - Second screens (unplug or turn face-down)
  - Headphones (earbuds are usually fine; ask proctor)
  - Phones off the desk entirely
- [ ] **Stable internet** — use a wired connection if possible. Know your hotspot as a backup.
- [ ] **Browser ready** — PSI Secure Browser must be installed and tested in advance at [https://syscheck.bridge.psiexams.com](https://syscheck.bridge.psiexams.com).
- [ ] **Only one tab allowed** — the PSI browser locks you to a single extra tab, which must be on **kubernetes.io** (including docs, blog, and reference pages). No Stack Overflow, no GitHub personal repos.
- [ ] **Check in 15 minutes early** — the proctor queue can be slow; late check-in eats into prep time.

---

## Environment

| Item | Detail |
|------|--------|
| Exam platform | PSI Secure Browser (remote proctored) |
| Allowed sites | kubernetes.io (docs, reference, blog) |
| Terminal | Pre-configured Linux terminal in the exam UI |
| Kubernetes version | v1.35 |
| Duration | 2 hours |
| Tasks | ~17 performance-based |
| Passing score | 66% |

---

## Time Budget

With ~17 tasks and 120 minutes: **average ~7 minutes per task**.

| Strategy | Guidance |
|----------|----------|
| First pass | Quickly scan all tasks and do the ones you know cold first (1-2 min or less). |
| Flag and move | If a task takes more than 8–9 minutes with no clear path forward, flag it and move on — revisit at the end. |
| Easy points first | Namespace/label tasks, simple pod creates, RBAC bindings — grab these quickly. |
| Hard tasks last | etcd restore and kubeadm upgrade are slow but worth many points; budget 10-15 min each. |
| Leave 5 min | Reserve the last 5 minutes for a final review of flagged tasks. |

---

## At the Start of EVERY Task

```bash
# Step 1: Switch to the cluster context specified in the task
kubectl config use-context <context-name>

# Step 2: If the task specifies a namespace, set it as default
kubectl config set-context --current --namespace=<namespace>

# Step 3: Verify you're in the right context
kubectl config current-context
```

> Forgetting the context switch is one of the most common ways to lose points — you may complete the task perfectly but in the wrong cluster.

---

## During the Exam

- Use `kubectl explain` heavily — it is faster than switching to the docs.
- Use `$do` (`--dry-run=client -o yaml`) to generate manifests, then edit with `vi`.
- Use `$now` (`--force --grace-period=0`) when deleting pods to save time.
- Do not spend time on formatting — the exam grades by state, not YAML aesthetics.
- `kubectl get events -n <ns> --sort-by='.lastTimestamp'` is your first debugging move.
- `journalctl -u kubelet -f` and `crictl ps -a` are your second debugging moves.

---

## After Submitting

- Results are emailed within **24 hours** (often much faster).
- If you fail, you get one free retake — review your score report and target the weakest domains.
