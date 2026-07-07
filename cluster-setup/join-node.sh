#!/usr/bin/env bash
# Run on a worker (Pi or PC) to join the cluster.
# Get the real join command from the control plane with:
#   kubeadm token create --print-join-command
set -euo pipefail
JOIN_CMD="${1:-}"
if [[ -z "$JOIN_CMD" ]]; then
  echo "Usage: sudo ./join-node.sh 'kubeadm join <IP>:6443 --token <TOKEN> --discovery-token-ca-cert-hash sha256:<HASH>'"
  exit 1
fi
eval "sudo $JOIN_CMD"
