#!/usr/bin/env bash
# DRILL: stop the kubelet so the node goes NotReady. Practice diagnosing with
# systemctl/journalctl, then FIX by starting it again. Lab nodes only.
set -euo pipefail
echo "Stopping kubelet on $(hostname). Diagnose with: systemctl status kubelet; journalctl -u kubelet"
sudo systemctl stop kubelet
echo "FIX when done:  sudo systemctl start kubelet && kubectl get nodes"
