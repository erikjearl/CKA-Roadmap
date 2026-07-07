#!/usr/bin/env bash
# Install a CNI that supports arm64 + amd64. Flannel shown; swap for Calico if preferred.
set -euo pipefail
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
echo "CNI applied. Watch nodes become Ready: kubectl get nodes -w"
