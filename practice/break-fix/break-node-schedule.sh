#!/usr/bin/env bash
# DRILL: taint every node NoSchedule and create a pod with no matching toleration
# so it stays Pending. Practice tracing Pending pods via describe → events → taints.
# FIX by removing the taint from all nodes. CLEANUP: kubectl delete ns drill
set -euo pipefail
kubectl taint nodes --all drill=true:NoSchedule --overwrite
kubectl get ns drill >/dev/null 2>&1 || kubectl create ns drill
kubectl -n drill run drill-pending --image=nginx:1.27 --restart=Never \
  --dry-run=client -o yaml | kubectl apply -f -
echo "All nodes tainted drill=true:NoSchedule; pod drill-pending is now Pending."
echo "Diagnose with:"
echo "  kubectl -n drill get pod drill-pending"
echo "  kubectl -n drill describe pod drill-pending   # check Events"
echo "  kubectl describe nodes | grep -A5 Taints"
echo "FIX when done:  kubectl taint nodes --all drill=true:NoSchedule-"
echo "CLEANUP:        kubectl delete ns drill"
