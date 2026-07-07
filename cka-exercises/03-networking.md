# Networking

> **New/deeper vs CKAD:** CNI internals, CoreDNS config, Service routing/endpoints, Ingress, the Gateway API, NetworkPolicy enforcement, and network troubleshooting — deeper than CKAD's app-level networking.

## Quick Reference — Documentation
kubernetes.io > Documentation > Concepts > Services, Load Balancing, and Networking > [Service](https://kubernetes.io/docs/concepts/services-networking/service/)
kubernetes.io > Documentation > Concepts > Services, Load Balancing, and Networking > [Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
kubernetes.io > Documentation > Concepts > Services, Load Balancing, and Networking > [Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)
kubernetes.io > Documentation > Concepts > Services, Load Balancing, and Networking > [Gateway API](https://kubernetes.io/docs/concepts/services-networking/gateway/)
kubernetes.io > Documentation > Reference > kubectl CLI > [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/quick-reference/)

---

### Expose a Deployment as ClusterIP and inspect its Endpoints/EndpointSlice `(easy)`
<details><summary>show</summary>
<p>

```bash
# Create a demo deployment (skip if one already exists)
kubectl create deployment nginx --image=nginx:1.25 --replicas=2

# Expose the deployment as a ClusterIP Service
kubectl expose deployment nginx --port=80 --target-port=80 --type=ClusterIP

# Inspect the Service
kubectl get service nginx
kubectl describe service nginx

# Inspect Endpoints (classic object; one per Service; shows all ready pod IPs)
kubectl get endpoints nginx
kubectl describe endpoints nginx

# Inspect EndpointSlices (newer, sharded for large Services)
kubectl get endpointslices -l kubernetes.io/service-name=nginx
kubectl describe endpointslice -l kubernetes.io/service-name=nginx
```

</p>
</details>

---

### Expose a Deployment as NodePort and curl it from a node `(easy)`
<details><summary>show</summary>
<p>

```bash
# Expose as NodePort (Kubernetes assigns a port in the 30000-32767 range)
kubectl expose deployment nginx --port=80 --target-port=80 --type=NodePort --name=nginx-np

# Find the assigned NodePort
kubectl get service nginx-np
# Look for the port mapping: 80:<NodePort>/TCP

# Get a node's external/internal IP
kubectl get nodes -o wide
# Use INTERNAL-IP or EXTERNAL-IP (whichever is reachable)

# Curl from the node or any host that can reach the node IP (replace placeholders)
curl http://<node-ip>:<nodeport>
# Expected: nginx welcome page HTML

# Alternatively, retrieve the NodePort programmatically and curl in one step
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
NODE_PORT=$(kubectl get service nginx-np -o jsonpath='{.spec.ports[0].nodePort}')
curl http://"$NODE_IP":"$NODE_PORT"
```

</p>
</details>

---

### Inspect and edit the CoreDNS ConfigMap; add a rewrite/stub domain `(med)`
<details><summary>show</summary>
<p>

```bash
# View the current CoreDNS Corefile
kubectl -n kube-system get configmap coredns -o yaml

# Open the ConfigMap for editing
kubectl -n kube-system edit configmap coredns

# Inside the editor, locate the .:53 { ... } block.
# Example: add a name rewrite so requests for old.example.com resolve as new.example.com:
#
#   .:53 {
#       rewrite name old.example.com new.example.com   # <-- add this line
#       forward . /etc/resolv.conf
#       ...
#   }
#
# Example: add a stub zone to forward an internal domain to a private DNS server:
#
#   corp.internal:53 {
#       errors
#       cache 30
#       forward . 10.0.0.1
#   }
#
# Save and exit the editor.

# Restart CoreDNS so the new Corefile takes effect
kubectl -n kube-system rollout restart deploy/coredns
```

```bash
# verify
kubectl -n kube-system rollout status deploy/coredns
# Expected: Waiting for deployment "coredns" rollout to finish: ...
#           deployment "coredns" successfully rolled out
```

</p>
</details>

---

### Create an Ingress routing two paths to two Services `(med)`
<details><summary>show</summary>
<p>

```bash
# Prerequisites:
#   - An Ingress controller must be installed (e.g., ingress-nginx).
#   - Two Services must exist: svc-a and svc-b, each listening on port 80.

# Create two demo Services if needed
kubectl create deployment app-a --image=nginx:1.25
kubectl expose deployment app-a --port=80 --name=svc-a

kubectl create deployment app-b --image=nginx:1.25
kubectl expose deployment app-b --port=80 --name=svc-b

# Create the Ingress with two path-based backends
kubectl apply -f - <<'EOF'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: demo-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - host: demo.example.com
    http:
      paths:
      - path: /app-a
        pathType: Prefix
        backend:
          service:
            name: svc-a
            port:
              number: 80
      - path: /app-b
        pathType: Prefix
        backend:
          service:
            name: svc-b
            port:
              number: 80
EOF

# Inspect the Ingress (ADDRESS populates once the controller assigns a load-balancer IP)
kubectl get ingress demo-ingress
kubectl describe ingress demo-ingress
```

</p>
</details>

---

### ⭐ Create a Gateway + HTTPRoute directing traffic to a Service `(hard)`
<details><summary>show</summary>
<p>

```bash
# The Gateway API requires:
#   1. The standard Gateway API CRDs installed in the cluster.
#   2. A compatible controller running (e.g., Envoy Gateway, Contour, Istio, Cilium).
# These are NOT present by default — install them if missing.

# Install the standard Gateway API CRDs (idempotent; safe to re-run)
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.1/standard-install.yaml  # CRDs pre-installed on exam clusters

# Verify a GatewayClass is available (provided by the installed controller)
kubectl get gatewayclass
# Example output: eg   envoy-gateway-system/envoy   True   ...

# Step 1: create a Gateway that opens an HTTP listener on port 80
kubectl apply -f - <<'EOF'
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: demo-gateway
  namespace: default
spec:
  gatewayClassName: eg          # replace with the name shown by "kubectl get gatewayclass"
  listeners:
  - name: http
    protocol: HTTP
    port: 80
EOF

# Step 2: create an HTTPRoute that routes all traffic to the nginx Service
kubectl apply -f - <<'EOF'
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: demo-route
  namespace: default
spec:
  parentRefs:
  - name: demo-gateway           # binds this route to the Gateway above
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /
    backendRefs:
    - name: nginx                # must be an existing Service in the same namespace
      port: 80
EOF

# Check the Gateway's programmed status and assigned address
kubectl get gateway demo-gateway
kubectl describe gateway demo-gateway

# Check the HTTPRoute's parent binding status
kubectl get httproute demo-route
kubectl describe httproute demo-route
# Look for: Parents > Conditions > type: Accepted and type: ResolvedRefs — both should be True
```

</p>
</details>

---

### Diagnose why a Service returns no endpoints (selector/label mismatch) `(med)`
<details><summary>show</summary>
<p>

```bash
# Step 1: create a scenario with a deliberate selector/label mismatch
kubectl create deployment web --image=nginx:1.25
# The deployment creates pods with label: app=web

# Create a Service that selects the WRONG label (app=webapp instead of app=web)
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: web-svc
spec:
  selector:
    app: webapp          # intentional mismatch — no pods have this label
  ports:
  - port: 80
    targetPort: 80
EOF

# Step 2: observe that no endpoints are registered
kubectl get endpoints web-svc
# ENDPOINTS column shows: <none>

# Step 3: diagnose
# Compare the Service selector with the pod labels
kubectl get service web-svc -o jsonpath='{.spec.selector}'
# Output: {"app":"webapp"}

kubectl get pods -l app=web --show-labels
# Pods exist with label app=web, not app=webapp — mismatch confirmed

# Step 4: fix — patch the Service selector to match the pod labels
kubectl patch service web-svc -p '{"spec":{"selector":{"app":"web"}}}'

# Alternative fix: relabel the pods to match the existing Service selector
# kubectl label pods -l app=web app=webapp --overwrite
```

```bash
# verify
kubectl get endpoints web-svc
# The ENDPOINTS column should now show one or more IP:80 entries (not <none>)

kubectl get endpointslices -l kubernetes.io/service-name=web-svc
# EndpointSlice should list the pod IPs with ready: true
```

</p>
</details>

---

### Verify pod-to-pod connectivity across nodes and identify the CNI in use `(med)`
<details><summary>show</summary>
<p>

```bash
# Step 1: identify the active CNI plugin
# Method A — inspect the CNI config directory on a node (requires node shell access)
ls /etc/cni/net.d/
# Config filenames reveal the plugin, e.g.:
#   10-calico.conflist    → Calico
#   10-flannel.conflist   → Flannel
#   05-cilium.conflist    → Cilium
#   10-weave.conf         → Weave Net
cat /etc/cni/net.d/<config-file>

# Method B — identify by the CNI DaemonSet/pods running in kube-system (no node access needed)
kubectl get pods -n kube-system
# Look for: calico-node, weave-net, cilium, kube-flannel, etc.

# Step 2: launch two pods (the scheduler may place them on different nodes)
kubectl run pod-a --image=busybox:1.36 --restart=Never -- sleep 3600
kubectl run pod-b --image=busybox:1.36 --restart=Never -- sleep 3600

# Wait for both pods to be Running
kubectl get pods -o wide
# Note the NODE column — confirm they landed on different nodes for a true cross-node test

# Step 3: ping pod-b from pod-a
POD_B_IP=$(kubectl get pod pod-b -o jsonpath='{.status.podIP}')
kubectl exec pod-a -- ping -c 3 "$POD_B_IP"
# Three successful ICMP replies confirm the CNI is providing cross-node connectivity

# Cleanup
kubectl delete pod pod-a pod-b
```

</p>
</details>

---

### Resolve a Service DNS name from inside a pod and troubleshoot a DNS failure `(med)`
<details><summary>show</summary>
<p>

```bash
# Step 1: resolve a Service DNS name from a temporary pod
# drop -t if not in an interactive terminal
kubectl run test --image=busybox:1.36 --rm -it --restart=Never -- nslookup nginx.default.svc.cluster.local
# Expected: returns the ClusterIP of the nginx Service in the default namespace

# Fully-qualified DNS name patterns for Services:
#   <svc>.<namespace>.svc.cluster.local   fully qualified (always works from any namespace)
#   <svc>.<namespace>.svc                 works via cluster DNS search domain
#   <svc>.<namespace>                     works via cluster DNS search domain
#   <svc>                                 works only from within the same namespace

# Step 2: troubleshoot a DNS failure

# Check that CoreDNS pods are running
kubectl -n kube-system get pods -l k8s-app=kube-dns

# Check CoreDNS logs for error messages (loop, forward failures, etc.)
kubectl -n kube-system logs -l k8s-app=kube-dns --tail=50

# Verify the kube-dns Service exists and has endpoints
kubectl -n kube-system get service kube-dns
kubectl -n kube-system get endpoints kube-dns

# Inspect /etc/resolv.conf inside a pod — it must point to the CoreDNS ClusterIP
kubectl run dns-debug --image=busybox:1.36 --rm -it --restart=Never -- sh
# Inside the pod:
#   cat /etc/resolv.conf
#   # Should show: nameserver <CoreDNS-ClusterIP>  (typically 10.96.0.10)
#   nslookup kubernetes.default
#   nslookup nginx.default.svc.cluster.local

# If CoreDNS has a bad Corefile, check and fix the ConfigMap then restart:
kubectl -n kube-system edit configmap coredns
kubectl -n kube-system rollout restart deploy/coredns
```

</p>
</details>

---

### Apply a default-deny ingress NetworkPolicy to a namespace and prove traffic is blocked `(med)`
<details><summary>show</summary>
<p>

```bash
# NOTE: NetworkPolicies are only enforced if the CNI supports them.
# Calico and Cilium enforce them; Flannel does NOT (policies are silently ignored).
# On the Pi lab cluster, install Calico instead of Flannel to drill these.

# Setup: a namespace with a web pod and service
kubectl create namespace np-demo
kubectl -n np-demo run web --image=nginx:1.27 --labels=app=web --port=80
kubectl -n np-demo expose pod web --port=80
```

```yaml
# Default-deny ALL ingress to every pod in the namespace:
# empty podSelector selects all pods; Ingress in policyTypes with no rules = deny all.
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-ingress
  namespace: np-demo
spec:
  podSelector: {}
  policyTypes:
    - Ingress
```

```bash
# verify — the request must TIME OUT (blocked), not connect
kubectl -n np-demo run test --image=busybox:1.36 --restart=Never --rm -it -- \
  wget -qO- --timeout=2 http://web
# Expected: "wget: download timed out" (exit code 1) — ingress is blocked
```

</p>
</details>

---

### Allow ingress to app=web pods only from a specific namespace on TCP 80 `(hard)`
<details><summary>show</summary>
<p>

```bash
# Setup: a client namespace (in addition to np-demo from the previous exercise)
kubectl create namespace frontend
```

```yaml
# Allow rule layered on top of the default-deny policy.
# kubernetes.io/metadata.name is set automatically on every namespace —
# use it to select namespaces without labeling them yourself.
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-to-web
  namespace: np-demo
spec:
  podSelector:
    matchLabels:
      app: web
  policyTypes:
    - Ingress
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: frontend
      ports:
        - protocol: TCP
          port: 80
```

```bash
# verify — allowed from frontend, still blocked from np-demo itself
# (web.np-demo is the cross-namespace Service short form: <svc>.<namespace>)
kubectl -n frontend run test --image=busybox:1.36 --restart=Never --rm -it -- \
  wget -qO- --timeout=2 http://web.np-demo
# Expected: nginx welcome HTML (allowed)

kubectl -n np-demo run test --image=busybox:1.36 --restart=Never --rm -it -- \
  wget -qO- --timeout=2 http://web
# Expected: timeout (np-demo pods do not match the allow rule)
```

</p>
</details>

---

### Restrict a pod's egress to DNS only and prove other egress is blocked `(hard)`
<details><summary>show</summary>
<p>

```bash
# Prerequisite: the np-demo namespace and app=web pod from the
# default-deny exercise above.
```

```yaml
# Lock a pod down so it can resolve names but cannot open other connections.
# Without the DNS exception, an egress policy breaks ALL name resolution —
# a classic exam trap when asked to "restrict egress".
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: egress-dns-only
  namespace: np-demo
spec:
  podSelector:
    matchLabels:
      app: web
  policyTypes:
    - Egress
  egress:
    - to:
        - namespaceSelector: {}          # any namespace…
          podSelector:
            matchLabels:
              k8s-app: kube-dns          # …but only the CoreDNS pods
      ports:
        - protocol: UDP
          port: 53
        - protocol: TCP
          port: 53
```

```bash
# verify — run a throwaway pod carrying the SAME app=web label so the egress
# policy applies to it (nginx itself ships no nslookup/curl to test with)
kubectl -n np-demo run egress-test --image=busybox:1.36 --labels=app=web \
  --restart=Never --rm -it -- nslookup kubernetes.default
# Expected: resolves successfully (DNS egress allowed)

# Non-DNS egress: try a raw TCP connect to the API server's ClusterIP:443
# (find it with: kubectl get svc kubernetes)
kubectl -n np-demo run egress-test --image=busybox:1.36 --labels=app=web \
  --restart=Never --rm -it -- sh -c 'nc -z -w 2 10.96.0.1 443 && echo REACHABLE || echo BLOCKED'
# Expected: BLOCKED (without the policy this prints REACHABLE)
```

</p>
</details>
