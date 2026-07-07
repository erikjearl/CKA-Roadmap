# cluster-setup

Reusable kubeadm artifacts for the home lab cluster (Raspberry Pi arm64 nodes + one amd64 PC node). This directory doubles as the **CKA Installation and Cluster Management lab** — working through these scripts is the hands-on practice for that domain.

## Mixed-arch caveat

The cluster runs a mix of `arm64` (Pi) and `amd64` (PC) nodes. Always use **multi-arch images** for system components and CNI add-ons — single-arch images will fail to pull on the wrong node. Flannel (`kube-flannel.yml`) publishes multi-arch manifests and works fine here. etcd running on Pi SD cards is noticeably slower than SSD, but performance is adequate for exam practice.

## Bootstrap sequence

Perform these steps in order from the control-plane node:

1. **Init the control plane**
   ```bash
   # Edit kubeadm-config.yaml first — replace <CONTROL_PLANE_IP>
   sudo kubeadm init --config kubeadm-config.yaml
   ```
2. **Configure kubectl for your user**
   ```bash
   mkdir -p $HOME/.kube
   sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
   sudo chown $(id -u):$(id -g) $HOME/.kube/config
   ```
3. **Install the CNI**
   ```bash
   ./install-cni.sh
   ```
4. **Generate a join command**
   ```bash
   kubeadm token create --print-join-command
   ```
5. **Join each worker node** (run on the worker, paste the join command as the argument)
   ```bash
   sudo ./join-node.sh 'kubeadm join <IP>:6443 --token <TOKEN> --discovery-token-ca-cert-hash sha256:<HASH>'
   ```

## Scripts

| Script | Description |
|---|---|
| `install-cni.sh` | Applies the Flannel CNI manifest (multi-arch); nodes transition to Ready after this step. |
| `join-node.sh` | Wrapper run on each worker node that executes the `kubeadm join` command passed as its first argument. |
| `reset-cluster.sh` | Destructively resets a node to pre-kubeadm state via `kubeadm reset`; used by break-fix drills (see `../practice/break-fix/`) to restore a clean lab. |
| `backup-etcd.sh` | Takes an etcd snapshot with `etcdctl snapshot save`; used for etcd backup/restore practice (see `../cka-exercises/02-installation-cluster-mgmt.md`). |

## Safety note

**Never commit real cluster credentials.** The `.gitignore` at the repo root excludes `*.db` (etcd snapshots), `*.kubeconfig`, `admin.conf`, `pki/`, and certificate/key files. All values in `kubeadm-config.yaml` use `<PLACEHOLDER>` syntax — replace them locally and do not stage those changes.
