#!/usr/bin/env bash
# DRILL: patch a Service selector to a non-matching label so endpoints empty out.
# Usage: ./break-service-selector.sh <namespace> <service>
set -euo pipefail
NS="${1:?namespace}"; SVC="${2:?service}"
kubectl -n "$NS" patch svc "$SVC" -p '{"spec":{"selector":{"app":"does-not-exist"}}}'
echo "Broke $NS/$SVC selector. Diagnose empty endpoints with: kubectl -n $NS get endpoints $SVC"
