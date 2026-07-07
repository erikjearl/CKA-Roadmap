#!/usr/bin/env bash
# DRILL: scale CoreDNS to 0 replicas so in-cluster DNS resolution fails.
# Practice diagnosing with nslookup from a running pod, then tracing back to
# the missing DNS pods. FIX by scaling CoreDNS back to 2.
set -euo pipefail
kubectl -n kube-system scale deploy/coredns --replicas=0
echo "CoreDNS scaled to 0. Diagnose cluster DNS failures with:"
echo "  kubectl run tmp --image=busybox:1.36 --restart=Never --rm -it -- nslookup kubernetes"
echo "  kubectl -n kube-system get pods -l k8s-app=kube-dns"
echo "FIX when done:  kubectl -n kube-system scale deploy/coredns --replicas=2"
