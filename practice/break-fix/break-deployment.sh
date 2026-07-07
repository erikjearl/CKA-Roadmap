#!/usr/bin/env bash
# DRILL: trigger a stuck rollout by setting a non-existent image on a deployment.
# Practice diagnosing ProgressDeadlineExceeded / ImagePullBackOff, then fix
# with a rollout undo or corrected image. CLEANUP: kubectl delete ns drill
set -euo pipefail
kubectl get ns drill >/dev/null 2>&1 || kubectl create ns drill
kubectl -n drill create deployment web --image=nginx:1.27 --replicas=2 \
  --dry-run=client -o yaml | kubectl apply -f -
echo "Waiting for deployment/web to become ready..."
kubectl -n drill rollout status deploy/web --timeout=90s
kubectl -n drill set image deploy/web nginx=nginx:1.99-does-not-exist
echo "Broke deploy/web with a non-existent image. Diagnose with:"
echo "  kubectl -n drill rollout status deploy/web"
echo "  kubectl -n drill get pods"
echo "  kubectl -n drill describe pod <pending-pod>"
echo "FIX (option 1): kubectl -n drill rollout undo deploy/web"
echo "FIX (option 2): kubectl -n drill set image deploy/web nginx=nginx:1.27"
echo "CLEANUP:        kubectl delete ns drill"
