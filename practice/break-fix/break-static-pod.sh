#!/usr/bin/env bash
# DRILL: corrupt a control-plane static pod manifest. Practice restoring it.
# Backs the manifest up first so you can recover.
set -euo pipefail
M=/etc/kubernetes/manifests/kube-scheduler.yaml
sudo cp "$M" "/tmp/$(basename "$M").bak"
echo "  invalid: yaml: [broken" | sudo tee -a "$M" >/dev/null
echo "Broke $M (backup at /tmp/$(basename "$M").bak). Diagnose the scheduler pod, then restore."
