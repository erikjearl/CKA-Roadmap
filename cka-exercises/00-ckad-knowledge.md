# CKAD Knowledge (Already Known)

Fast refresher of CKAD-covered topics carried into the CKA — key commands and gotchas only, no exercises.

## Quick Reference — Documentation
kubernetes.io > Documentation > Reference > kubectl CLI > [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/quick-reference/)
kubernetes.io > Documentation > Concepts > Workloads > [Pods](https://kubernetes.io/docs/concepts/workloads/pods/)
kubernetes.io > Documentation > Concepts > Workloads > [Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
kubernetes.io > Documentation > Concepts > Services, Load Balancing, and Networking > [Service](https://kubernetes.io/docs/concepts/services-networking/service/)
kubernetes.io > Documentation > Concepts > Configuration > [ConfigMaps](https://kubernetes.io/docs/concepts/configuration/configmap/)
kubernetes.io > Documentation > Concepts > Configuration > [Secrets](https://kubernetes.io/docs/concepts/configuration/secret/)
kubernetes.io > Documentation > Concepts > Workloads > [Jobs](https://kubernetes.io/docs/concepts/workloads/controllers/job/)
kubernetes.io > Documentation > Tasks > Configure Pods and Containers > [Configure Liveness, Readiness and Startup Probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)
kubernetes.io > Documentation > Concepts > Storage > [Persistent Volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)
kubernetes.io > Documentation > Concepts > Configuration > [Resource Management for Pods and Containers](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)
kubernetes.io > Documentation > Concepts > Services, Load Balancing, and Networking > [Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
kubernetes.io > Documentation > Tasks > Configure Pods and Containers > [Configure a Security Context for a Pod or Container](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/)

---

## Pods

```bash
kubectl run nginx --image=nginx --restart=Never --dry-run=client -o yaml > pod.yaml
kubectl run tmp --image=busybox --rm -it --restart=Never -- sh   # ephemeral debug shell
kubectl exec -it <pod> -- /bin/sh
kubectl logs <pod> -c <container> --previous
```

Gotchas: `--restart=Never` sets `restartPolicy: Never` (good for one-off task Pods); omitting it gives `restartPolicy: Always`. Since k8s 1.18 `kubectl run` always creates a Pod — the flag no longer controls resource type.

---

## Deployments

```bash
kubectl create deployment nginx --image=nginx --replicas=3 --dry-run=client -o yaml
kubectl set image deployment/nginx nginx=nginx:1.25
kubectl rollout status deployment/nginx
kubectl rollout undo deployment/nginx
kubectl rollout history deployment/nginx --revision=2
kubectl scale deployment nginx --replicas=5
```

Gotchas: `kubectl set image` requires `<container-name>=<image>` — the container name defaults to the deployment name only if created imperatively.

---

## Services

```bash
kubectl expose deployment nginx --port=80 --target-port=8080 --type=ClusterIP
kubectl expose pod nginx --port=80 --name=svc-nginx
kubectl create service nodeport nginx --tcp=80:80 --node-port=30080
```

Gotchas: `kubectl expose` uses the pod/deployment label selector automatically. `ClusterIP` is the default type. `NodePort` range is 30000–32767 unless changed. DNS pattern: `<svc>.<namespace>.svc.cluster.local`.

---

## ConfigMaps

```bash
kubectl create configmap app-cfg --from-literal=KEY=value --from-file=config.properties
kubectl create configmap app-cfg --from-env-file=.env
```

Consume as env: `envFrom.configMapRef.name` or `env[].valueFrom.configMapKeyRef`. Consume as volume: `volumes[].configMap.name` → `volumeMounts`.

Gotchas: ConfigMap values are always strings. Volume-mounted ConfigMaps update eventually (not instantly); env var values do not live-update.

---

## Secrets

```bash
kubectl create secret generic db-pass --from-literal=password=s3cr3t
kubectl create secret docker-registry regcred --docker-server=... --docker-username=... --docker-password=...
kubectl create secret tls tls-secret --cert=tls.crt --key=tls.key
```

Gotchas: Secrets are base64-encoded, not encrypted at rest by default (CKA adds EncryptionConfiguration). Reference via `secretKeyRef` / `secretRef` the same way as ConfigMaps.

---

## Jobs/CronJobs

```bash
kubectl create job pi --image=perl:5 -- perl -Mbignum=bpi -wle 'print bpi(2000)'
kubectl create cronjob hello --image=busybox --schedule="*/1 * * * *" -- echo hello
```

Key fields: `spec.completions`, `spec.parallelism`, `spec.backoffLimit`, `spec.activeDeadlineSeconds`. CronJob adds `spec.jobTemplate` wrapping the Job spec.

Gotchas: CronJob schedule is UTC. `spec.successfulJobsHistoryLimit` / `spec.failedJobsHistoryLimit` default to 3/1.

---

## Probes

Three probe types: `livenessProbe` (restart if fails), `readinessProbe` (remove from Service endpoints if fails), `startupProbe` (delays liveness/readiness until app starts).

```yaml
livenessProbe:
  httpGet:
    path: /healthz
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 10
  failureThreshold: 3
```

Also supports `exec.command` and `tcpSocket.port`. Gotcha: missing `initialDelaySeconds` on slow-starting apps causes restart loops — use `startupProbe` instead.

---

## Volumes/PVCs

```bash
kubectl get pv,pvc
```

```yaml
# PVC
spec:
  accessModes: [ReadWriteOnce]
  resources:
    requests:
      storage: 1Gi
  storageClassName: standard
```

Mount via `volumes[].persistentVolumeClaim.claimName` + `volumeMounts`. Access modes: `RWO` (single node r/w), `ROX` (multi-node read-only), `RWX` (multi-node r/w). PV reclaim policy: `Retain`, `Delete` (`Recycle` was removed in v1.25 — use dynamic provisioning instead).

Gotchas: PVC stays in `Pending` if no matching PV exists or StorageClass can't provision. Bound PVC cannot change `storageClassName`.

---

## Resource Limits

```yaml
resources:
  requests:
    cpu: "250m"
    memory: "64Mi"
  limits:
    cpu: "500m"
    memory: "128Mi"
```

CPU is compressible (throttled at limit); memory is not (OOMKill at limit). `LimitRange` sets namespace defaults. `ResourceQuota` caps total namespace usage.

Gotchas: Pod QoS class: `Guaranteed` (requests == limits), `Burstable` (some set), `BestEffort` (none set). OOMKilled containers show `OOMKilled` in `kubectl describe`.

---

## NetworkPolicies

```yaml
spec:
  podSelector:
    matchLabels:
      role: db
  policyTypes: [Ingress]
  ingress:
  - from:
    - podSelector:
        matchLabels:
          role: frontend
    ports:
    - protocol: TCP
      port: 5432
```

Gotchas: Policies are additive — multiple policies selecting the same pod are unioned, never overridden. An empty `podSelector: {}` selects ALL pods in the namespace. Requires a CNI that enforces NetworkPolicy (Calico, Cilium, Weave — not Flannel alone).

---

## Helm Basics

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
helm search repo nginx
helm install my-release bitnami/nginx --set service.type=ClusterIP
helm upgrade my-release bitnami/nginx --set replicaCount=2
helm rollback my-release 1
helm uninstall my-release
helm list -n <namespace>
helm get values my-release
```

Gotchas: `helm install` fails if the release name already exists — use `helm upgrade --install` as the canonical idempotent approach. `--replace` only re-uses the name of a previously *deleted* release, not a live one. Values are overridden with `--set` (dot notation) or `--values file.yaml`.

---

## RBAC Basics

```bash
kubectl create role pod-reader --verb=get,list,watch --resource=pods
kubectl create rolebinding read-pods --role=pod-reader --user=jane
kubectl create clusterrole node-reader --verb=get,list --resource=nodes
kubectl create clusterrolebinding read-nodes --clusterrole=node-reader --user=jane
kubectl auth can-i list pods --as=jane -n default
```

`Role`/`RoleBinding` → namespace-scoped. `ClusterRole`/`ClusterRoleBinding` → cluster-scoped. A `ClusterRole` bound with a `RoleBinding` is namespace-scoped.

Gotchas: ServiceAccount RBAC: use `--serviceaccount=<ns>:<sa-name>` in `create rolebinding`.

---

## Multi-container Pods

Patterns: **Sidecar** (auxiliary helper runs alongside), **Ambassador** (proxy for external comms), **Adapter** (normalize output). All containers in a Pod share network (localhost) and can share volumes.

```yaml
spec:
  containers:
  - name: app
    image: nginx
  - name: sidecar
    image: busybox
    command: ["sh", "-c", "while true; do echo log; sleep 5; done"]
```

Gotchas: All containers must be `Running` for the Pod to be `Ready`. If any container crashes, the whole Pod restarts (per `restartPolicy`).

---

## Init Containers

Run to completion sequentially before app containers start. Share volumes with app containers but have separate image/command.

```yaml
spec:
  initContainers:
  - name: wait-for-db
    image: busybox
    command: ["sh", "-c", "until nc -z db 5432; do sleep 2; done"]
  containers:
  - name: app
    image: myapp
```

Gotchas: If an init container fails, the Pod restarts the init sequence from the beginning. Init containers do not support `readinessProbe`. Check init container logs with `kubectl logs <pod> -c wait-for-db`.

---

## Security Contexts

Set at Pod level (`spec.securityContext`) or container level (`spec.containers[].securityContext`). Container level overrides Pod level.

```yaml
spec:
  securityContext:
    runAsUser: 1000
    runAsGroup: 3000
    fsGroup: 2000
  containers:
  - name: app
    securityContext:
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      capabilities:
        drop: ["ALL"]
        add: ["NET_BIND_SERVICE"]
```

Gotchas: `fsGroup` sets the GID on mounted volumes. `runAsNonRoot: true` causes the container to fail if the image's user is root (UID 0).

---

## Troubleshooting Applications

```bash
kubectl get pods -n <ns> -o wide              # overview: status, node, IP
kubectl describe pod <pod> -n <ns>            # events, conditions, probe failures
kubectl logs <pod> -n <ns> -c <container>     # stdout/stderr
kubectl logs <pod> --previous                 # logs from crashed previous container
kubectl exec -it <pod> -- /bin/sh             # shell into running container
kubectl get events --sort-by=.lastTimestamp   # cluster-wide event stream
kubectl top pod <pod>                         # CPU/memory (metrics-server required)
```

Common states: `CrashLoopBackOff` → app exits; check logs. `ImagePullBackOff` → bad image name/tag or missing pull secret. `Pending` → no schedulable node (resources, taints, affinity). `OOMKilled` → raise memory limit.
