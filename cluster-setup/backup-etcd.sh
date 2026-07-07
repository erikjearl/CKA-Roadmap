#!/usr/bin/env bash
# Snapshot etcd. Run on the control-plane node.
set -euo pipefail
OUT="${1:-/opt/etcd-backup-$(date +%Y%m%d-%H%M%S).db}"
sudo ETCDCTL_API=3 etcdctl snapshot save "$OUT" \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key
sudo ETCDCTL_API=3 etcdctl --write-out=table snapshot status "$OUT"
echo "Snapshot at $OUT"
