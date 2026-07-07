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
