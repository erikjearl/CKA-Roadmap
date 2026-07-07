# Security

> **New/deeper vs CKAD:** cluster-level security — TLS/CSR workflow, advanced RBAC for users and groups, service accounts, kubeconfig contexts, secrets encryption at rest, admission control, and image policy.

## Quick Reference — Documentation
kubernetes.io > Documentation > Reference > Access Authn Authz > [Using RBAC Authorization](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
kubernetes.io > Documentation > Tasks > TLS > [Manage TLS Certificates in a Cluster](https://kubernetes.io/docs/tasks/tls/managing-tls-in-a-cluster/)
kubernetes.io > Documentation > Tasks > Administer a Cluster > [Encrypting Secret Data at Rest](https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/)

---

### Create a Role + RoleBinding granting get/list/watch pods in a namespace to a ServiceAccount  `(med)`
<details><summary>show</summary>
<p>

```bash
# Create a namespace and ServiceAccount for testing
kubectl create namespace rbac-test
kubectl create serviceaccount pod-reader-sa -n rbac-test

# Create the Role — grants get, list, watch on pods in rbac-test
kubectl create role pod-reader \
  --verb=get,list,watch \
  --resource=pods \
  -n rbac-test

# Create the RoleBinding — binds the Role to the ServiceAccount
kubectl create rolebinding pr-binding \
  --role=pod-reader \
  --serviceaccount=rbac-test:pod-reader-sa \
  -n rbac-test
```

```bash
# verify
# Should return "yes"
kubectl auth can-i list pods \
  --as=system:serviceaccount:rbac-test:pod-reader-sa \
  -n rbac-test
```

</p>
</details>

---

### Create a ClusterRole + ClusterRoleBinding for read-only cluster-wide access  `(med)`
<details><summary>show</summary>
<p>

```bash
# Create a ServiceAccount to bind
kubectl create serviceaccount cluster-reader-sa -n default

# Create the ClusterRole — read-only access to pods, nodes, and namespaces cluster-wide
kubectl create clusterrole cluster-reader \
  --verb=get,list,watch \
  --resource=pods,nodes,namespaces

# Bind the ClusterRole to the ServiceAccount
kubectl create clusterrolebinding cluster-reader-binding \
  --clusterrole=cluster-reader \
  --serviceaccount=default:cluster-reader-sa
```

```bash
# verify
# Should return "yes" for cluster-wide read access
kubectl auth can-i list nodes \
  --as=system:serviceaccount:default:cluster-reader-sa

kubectl auth can-i list pods \
  --as=system:serviceaccount:default:cluster-reader-sa

# Should return "no" — ClusterRole does not grant write access
kubectl auth can-i delete pods \
  --as=system:serviceaccount:default:cluster-reader-sa
```

</p>
</details>

---

### Generate a private key + CSR for a new user, submit a CertificateSigningRequest, approve it, and fetch the signed cert  `(hard)`
<details><summary>show</summary>
<p>

```bash
# Step 1: generate a 2048-bit RSA private key for user alice
openssl genrsa -out alice.key 2048

# Step 2: create a certificate signing request
# CN=alice becomes the username; O=dev becomes the group in Kubernetes RBAC
openssl req -new -key alice.key -out alice.csr -subj "/CN=alice/O=dev"

# Step 3: encode the CSR as a single-line base64 string (no newlines)
CSR=$(cat alice.csr | base64 | tr -d '\n')

# Step 4: submit the CertificateSigningRequest to the Kubernetes API
# signerName kubernetes.io/kube-apiserver-client issues client TLS certificates
kubectl apply -f - <<EOF
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: alice
spec:
  request: ${CSR}
  signerName: kubernetes.io/kube-apiserver-client
  usages:
  - client auth
EOF

# Step 5: approve the CSR
kubectl certificate approve alice

# Step 6: retrieve and decode the signed certificate
kubectl get csr alice -o jsonpath='{.status.certificate}' | base64 -d > alice.crt
```

```bash
# verify
# STATUS column should show: Approved,Issued
kubectl get csr alice
```

</p>
</details>

---

### Build a kubeconfig context for the new user and switch to it  `(med)`
<details><summary>show</summary>
<p>

```bash
# Retrieve the current cluster name
CLUSTER=$(kubectl config view --minify -o jsonpath='{.clusters[0].name}')

# Add alice's credentials — --embed-certs stores key and cert inline in kubeconfig
kubectl config set-credentials alice \
  --client-key=alice.key \
  --client-certificate=alice.crt \
  --embed-certs=true

# Create a new context pointing to the same cluster with alice's identity
kubectl config set-context alice@cluster \
  --cluster=${CLUSTER} \
  --user=alice

# Switch the active context to alice
kubectl config use-context alice@cluster
```

```bash
# verify
kubectl config current-context
# Expected output: alice@cluster
```

</p>
</details>

---

### Bind the new user to a Role and confirm their permissions  `(med)`
<details><summary>show</summary>
<p>

```bash
# Switch back to an admin context before creating the RoleBinding
kubectl config use-context <admin-context>

# Bind alice to the pod-reader Role created in exercise 1
kubectl create rolebinding alice-binding \
  --role=pod-reader \
  --user=alice \
  -n rbac-test
```

```bash
# verify
# Should return "yes" — alice is bound to pod-reader in rbac-test
kubectl auth can-i list pods --as=alice -n rbac-test

# Should return "no" — alice has no write permissions
kubectl auth can-i delete pods --as=alice -n rbac-test

# Should return "no" — RoleBinding is namespace-scoped, not cluster-wide
kubectl auth can-i list pods --as=alice -n default
```

</p>
</details>

---

### Enable encryption at rest for Secrets via an EncryptionConfiguration  `(hard)`
<details><summary>show</summary>
<p>

```bash
# Step 1: generate a 32-byte base64-encoded AES-CBC key (run on control-plane node)
head -c 32 /dev/urandom | base64
# Copy the output — it becomes the value of secret: below

# Step 2: create the encryption config directory and file on the control-plane node
mkdir -p /etc/kubernetes/enc

cat <<'EOF' > /etc/kubernetes/enc/encryption-config.yaml
apiVersion: apiserver.config.k8s.io/v1
kind: EncryptionConfiguration
resources:
- resources:
  - secrets
  providers:
  - aescbc:
      keys:
      - name: key1
        secret: <base64key>   # replace with output from Step 1
  - identity: {}              # fallback allows reading pre-existing unencrypted secrets
EOF

# Step 3: edit the kube-apiserver static pod manifest to reference the config file.
# The kubelet automatically restarts kube-apiserver when the manifest changes.
# Add to spec.containers[0].command:
#   - --encryption-provider-config=/etc/kubernetes/enc/encryption-config.yaml
#
# Add to spec.containers[0].volumeMounts:
#   - name: enc
#     mountPath: /etc/kubernetes/enc
#     readOnly: true
#
# Add to spec.volumes:
#   - name: enc
#     hostPath:
#       path: /etc/kubernetes/enc
#       type: DirectoryOrCreate

vi /etc/kubernetes/manifests/kube-apiserver.yaml

# Step 4: wait for the apiserver to come back up, then re-encrypt all existing Secrets.
# Secrets written before the config was applied are still stored in plaintext (identity).
# A replace forces the apiserver to re-write each Secret through the new provider (aescbc).
kubectl get secrets -A -o json | kubectl replace -f -
```

</p>
</details>

---

### Inspect enabled admission controllers on the apiserver and explain NodeRestriction  `(med)`
<details><summary>show</summary>
<p>

```bash
# View which admission controllers are enabled in the kube-apiserver static pod manifest
grep -i admission /etc/kubernetes/manifests/kube-apiserver.yaml
# Example output:
#   - --enable-admission-plugins=NodeRestriction

# Alternatively, query the running apiserver pod spec via the API
kubectl -n kube-system get pod -l component=kube-apiserver -o yaml | grep admission

# NodeRestriction — what it does:
# Authenticates a kubelet as system:node:<nodeName>.
# With NodeRestriction enabled, that kubelet can only:
#   - read/write its own Node object
#   - modify pods bound to its own node
# It cannot:
#   - modify another node's objects
#   - add arbitrary labels to its Node (only kubelet.kubernetes.io/ prefixed labels allowed)
# This limits blast radius if a node is compromised — the kubelet cannot pivot to other nodes
# or escalate privileges by tampering with another node's pod spec.
```

</p>
</details>
