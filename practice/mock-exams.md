# Mock Exams & Practice Cadence

## The Read → Drill → Timed-Mock Loop

The CKA is performance-based — typing speed and recall both matter. Work through this cycle for each domain:

1. **Read** — study the concept in `cka-exercises/`, `docs/`, or the Kubernetes docs.
2. **Drill** — do the exercises in `cka-exercises/` from memory (no peeking at answers until stuck).
3. **Timed mock** — simulate exam conditions: 2-hour window, no notes, only kubernetes.io open.
4. **Review** — immediately after time expires, go through every task you flagged or got wrong. Log mistakes in `gotchas.md`.
5. **Repeat** — cycle back to Drill on weak domains before the next full mock.

Aim for at least **two complete timed mocks** before exam day.

---

## Free Simulator Resources

### killer.sh (Included with Exam Registration)

Every CKA exam purchase includes **2 free simulator sessions** on [killer.sh](https://killer.sh).

- Sessions are time-limited (36 hours access per activation) — do NOT activate until you feel ready.
- The killer.sh environment is harder than the real exam by design; a 65-70% score there is a good sign for exam day.
- After time expires, the killer.sh solutions remain visible — study them thoroughly.
- Activate session 1 about one week before your exam; activate session 2 1-2 days before as a final check.

### Killercoda CKA Scenarios

[killercoda.com/killer-shell-cka](https://killercoda.com/killer-shell-cka) offers free, browser-based scenarios that match CKA domains. No account required for many scenarios.

Use these for targeted drill on weak areas — they are shorter (15–30 min) and can be repeated.

### Other Recommended Practice

| Resource | Notes |
|----------|-------|
| `cka-exercises/` in this repo | Domain-organized drills with answers |
| `break-fix/` in this repo | Intentionally broken clusters to diagnose |
| [Kubernetes docs interactive tutorial](https://kubernetes.io/docs/tutorials/) | Lightweight, good for new concepts |

---

## Mock Exam Score Log

Copy a row for each timed mock. Honest tracking reveals patterns.

| Date | Platform | Score (%) | Time Used | Flagged Tasks | Weak Domains | Notes |
|------|----------|-----------|-----------|---------------|--------------|-------|
| YYYY-MM-DD | killer.sh #1 | — | — | — | — | First attempt |
| YYYY-MM-DD | killer.sh #2 | — | — | — | — | Final check |
| YYYY-MM-DD | killercoda | — | — | — | — | Targeted drill |

---

## Weak-Area Tracker

After each mock, identify the 1-2 domains where you lost the most points and schedule a focused drill session.

| Domain | Mock Date | Issue | Planned Fix | Resolved? |
|--------|-----------|-------|-------------|-----------|
| Cluster Setup | — | kubeadm upgrade steps out of order | Re-drill `02-installation-cluster-mgmt.md` | [ ] |
| Security | — | RBAC roleRef typo | Review RBAC field names | [ ] |

---

## Passing Score

The CKA passing score is **66%** (as of 2025). The exam is 2 hours with ~17 performance-based tasks across a live multi-node Kubernetes environment running **v1.35**.
