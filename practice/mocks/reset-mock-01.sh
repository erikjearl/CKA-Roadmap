#!/usr/bin/env bash
# reset-mock-01.sh — Delete all resources created by Mock Exam 01
# Usage: bash practice/mocks/reset-mock-01.sh
set -uo pipefail

echo ""
echo "============================================"
echo " CKA Mock Exam 01 — Reset"
echo "============================================"
echo ""

echo "Deleting namespace mock01-web (Deployment web, NetworkPolicy, HPA, Pod important)..."
kubectl delete namespace mock01-web --ignore-not-found

echo "Deleting namespace mock01-rbac (ServiceAccount, Role, RoleBinding)..."
kubectl delete namespace mock01-rbac --ignore-not-found

echo "Deleting namespace mock01-data (PVC data-pvc)..."
kubectl delete namespace mock01-data --ignore-not-found

echo "Deleting PersistentVolume mock01-pv..."
kubectl delete persistentvolume mock01-pv --ignore-not-found

echo "Deleting PriorityClass mock01-high..."
kubectl delete priorityclass mock01-high --ignore-not-found

echo ""
echo "Reset complete. You may now retake Mock Exam 01."
echo "  Start:  practice/mocks/mock-01.md"
echo "  Grade:  bash practice/mocks/grade-mock-01.sh"
echo ""
