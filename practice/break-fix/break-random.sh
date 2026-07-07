#!/usr/bin/env bash
# DRILL (mystery mode): breaks ONE random thing and does not tell you what.
# Diagnose from symptoms alone. If truly stuck: cat /tmp/break-fix-last.log
# NOTE: mapfile requires bash 4+; macOS ships bash 3.2 but these run on Linux
# lab nodes where bash 4+ is standard — so mapfile is fine here.
# NOTE: break-kubelet.sh and break-static-pod.sh invoke sudo internally; if
# either is selected you may see a sudo password prompt — that prompt is itself
# a hint that a node-level component is involved.
set -euo pipefail
cd "$(dirname "$0")"
mapfile -t scripts < <(ls break-*.sh | grep -v break-random.sh)
pick="${scripts[RANDOM % ${#scripts[@]}]}"
echo "Something in the cluster is now broken. Find it and fix it."
echo "(The culprit and its output are logged to /tmp/break-fix-last.log)"
{ echo "== $(date) == $pick"; "./$pick"; } > /tmp/break-fix-last.log 2>&1
