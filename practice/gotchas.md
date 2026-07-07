# Gotchas & Spaced-Repetition Log

This file is a running log of mistakes made during drills and mock exams, plus review notes from spaced repetition. Add a row every time you make an error that cost you time or points.

**Review cadence:** skim the whole table before each mock exam session. Any "Fix / Lesson" you can't recite from memory is a drill target.

---

## Mistake Log

| Date | Mistake | Fix / Lesson |
|------|---------|--------------|
| — | Forgot `-n <namespace>` on `kubectl get` or `kubectl apply`, operated in the wrong namespace | Always check `kubectl config current-context` and `kubectl config view --minify` first. Set namespace with `kubectl config set-context --current --namespace=<ns>` or pass `-n` explicitly on every command. |
| — | Tried to edit a mirror static pod via `kubectl edit pod` — changes silently discarded | Mirror pods (those in `/etc/kubernetes/manifests/`) are managed by kubelet, not the API server. SSH to the node and edit the manifest file directly: `vi /etc/kubernetes/manifests/<pod>.yaml`. kubelet will re-create the pod automatically. |
| — | etcd restore — forgot to update the `--data-dir` in the static pod manifest after restoring | After `etcdctl snapshot restore --data-dir=/var/lib/etcd-restore`, update `/etc/kubernetes/manifests/etcd.yaml` to point `--data-dir` and the `hostPath` volume at the new path, then wait for etcd pod to restart. |

---

## Spaced-Repetition Notes

Add brief "card-style" notes here for concepts that keep tripping you up.

### RBAC — roleRef is immutable

Once a RoleBinding or ClusterRoleBinding is created, the `roleRef` field cannot be changed. Delete and re-create the binding if you need to change the role it points to.

### kubeadm upgrade sequence

```
# Control plane
kubectl drain <cp-node> --ignore-daemonsets
apt-mark unhold kubeadm && apt-get install kubeadm=1.35.x-* && apt-mark hold kubeadm
kubeadm upgrade plan
kubeadm upgrade apply v1.35.x
apt-mark unhold kubelet kubectl && apt-get install kubelet=1.35.x-* kubectl=1.35.x-* && apt-mark hold kubelet kubectl
systemctl daemon-reload && systemctl restart kubelet
kubectl uncordon <cp-node>

# Each worker (repeat per node)
kubectl drain <node> --ignore-daemonsets --delete-emissive-data
ssh <node>
apt-mark unhold kubeadm && apt-get install kubeadm=1.35.x-* && apt-mark hold kubeadm
kubeadm upgrade node
apt-mark unhold kubelet kubectl && apt-get install kubelet=1.35.x-* kubectl=1.35.x-* && apt-mark hold kubelet kubectl
systemctl daemon-reload && systemctl restart kubelet
exit
kubectl uncordon <node>
```

### NetworkPolicy — default deny must be explicit

An empty `podSelector: {}` with no `ingress`/`egress` rules selects all pods but allows nothing. You must create a separate default-deny policy; simply not having a policy means all traffic is allowed.

### CSR approval

```bash
kubectl certificate approve <csr-name>
# Then extract the cert
kubectl get csr <csr-name> -o jsonpath='{.status.certificate}' | base64 -d > user.crt
```
