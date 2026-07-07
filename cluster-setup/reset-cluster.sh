#!/usr/bin/env bash
# Reset a node to pre-kubeadm state. DESTRUCTIVE — use on lab nodes only.
set -euo pipefail
read -r -p "This will 'kubeadm reset' THIS node. Continue? [y/N] " ans
[[ "$ans" == "y" ]] || { echo "aborted"; exit 1; }
sudo kubeadm reset -f
sudo rm -rf /etc/cni/net.d ~/.kube/config
echo "Node reset. Re-init (control plane) or re-run join-node.sh (worker)."
