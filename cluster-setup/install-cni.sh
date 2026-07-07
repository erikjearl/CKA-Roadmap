#!/usr/bin/env bash
# Install a CNI that supports arm64 + amd64.
#
# Default: Calico — enforces NetworkPolicy, which the drills in
#   cka-exercises/03-networking.md depend on.
# Option:  ./install-cni.sh flannel — lighter, but NetworkPolicies are
#   SILENTLY IGNORED (Flannel does not implement policy enforcement).
#
# Versions are pinned for reproducibility; bump deliberately after checking
# the release notes against your Kubernetes version.
set -euo pipefail

CALICO_VERSION="v3.29.1"
FLANNEL_VERSION="v0.26.1"
POD_CIDR="10.244.0.0/16"   # must match kubeadm-config.yaml networking.podSubnet

if [[ "${1:-calico}" == "flannel" ]]; then
  echo "Installing Flannel ${FLANNEL_VERSION} (NOTE: no NetworkPolicy enforcement)"
  kubectl apply -f "https://github.com/flannel-io/flannel/releases/download/${FLANNEL_VERSION}/kube-flannel.yml"
else
  echo "Installing Calico ${CALICO_VERSION} with pool ${POD_CIDR}"
  curl -fsSL "https://raw.githubusercontent.com/projectcalico/calico/${CALICO_VERSION}/manifests/calico.yaml" -o /tmp/calico.yaml
  # Align Calico's IP pool with the kubeadm podSubnet (uncomment + set the CIDR)
  sed -i.bak \
    -e 's|# - name: CALICO_IPV4POOL_CIDR|- name: CALICO_IPV4POOL_CIDR|' \
    -e "s|#   value: \"192.168.0.0/16\"|  value: \"${POD_CIDR}\"|" \
    /tmp/calico.yaml
  kubectl apply -f /tmp/calico.yaml
fi

echo "CNI applied. Watch nodes become Ready: kubectl get nodes -w"
