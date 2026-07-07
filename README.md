# CKA Roadmap

> **Tracks CKA v1.35 / Kubernetes 1.35**

This repo is a hands-on CKA study plan for someone who has already passed CKAD. The focus is on material that is new or goes significantly deeper than CKAD — cluster bootstrapping, etcd backup/restore, advanced networking (CNI, NetworkPolicy, Gateway API), node administration, security hardening, and troubleshooting under time pressure. CKAD-overlap topics (core workloads, basic RBAC, Services) are recapped in `cka-exercises/00-ckad-knowledge.md` so you can confirm existing knowledge quickly and move on.

Track your confidence across all exercises in **[PROGRESS.md](PROGRESS.md)**.

---

## How to use

1. **Set up your shell first.** Run through [`practice/exam-setup.md`](practice/exam-setup.md) once on your study cluster — aliases, autocompletion, and `.vimrc` must be second nature before exam day.
2. **Read the Quick-Reference docs** at the top of each exercise file before drilling. These are the exact kubernetes.io paths you will use in the exam.
3. **Drill the tasks** in `cka-exercises/` in order. Do not skip the verify step; it mirrors how the exam auto-grades.
4. **Log every mistake** in [`practice/gotchas.md`](practice/gotchas.md) with the date and the lesson. Review the log before each mock exam.
5. **Run timed mocks** using the schedule in [`practice/mock-exams.md`](practice/mock-exams.md) once you have covered all domains.

---

## Exam format

| Attribute | Detail |
|---|---|
| Format | Performance-based (live cluster tasks — no multiple choice) |
| Duration | 2 hours |
| Pass score | ~66% |
| Clusters | Multiple (context switch required per task — see `day-of-exam.md`) |
| Kubernetes version | 1.35 |
| Allowed docs | [kubernetes.io/docs](https://kubernetes.io/docs) and [kubernetes.io/blog](https://kubernetes.io/blog) only |

---

## Domain map

| Domain | Official weight |
|---|---|
| Troubleshooting | 30% |
| Cluster Architecture, Installation & Configuration | 25% |
| Services & Networking | 20% |
| Workloads & Scheduling | 15% |
| Storage | 10% |

---

## Directory guide

| Path | Purpose |
|---|---|
| [`cka-exercises/`](cka-exercises/) | Domain drills — one file per topic area. Start here. See [`cka-exercises/README.md`](cka-exercises/README.md) for the full exercise map. |
| [`practice/`](practice/) | Exam-prep layer — setup script, bookmarks, mock-exam cadence, day-of checklist, and mistake log. See [`practice/README.md`](practice/README.md). |
| [`cluster-setup/`](cluster-setup/) | Scripts and notes for standing up a local multi-node study cluster (kubeadm on a mixed-arch Raspberry Pi + PC lab, adaptable to VMs or kind). |
| [`PROGRESS.md`](PROGRESS.md) | Confidence tracker — red / yellow / green per exercise, updated as you drill. |

---

## Credits & license

Exercise format inspired by [dgkanatsios/CKAD-exercises](https://github.com/dgkanatsios/CKAD-exercises). Licensed under the [MIT License](LICENSE).

*Kubernetes and CKA are trademarks of the Linux Foundation / CNCF. This is an independent study project, not affiliated with or endorsed by either.*
