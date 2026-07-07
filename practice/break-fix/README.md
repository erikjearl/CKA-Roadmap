# Break-Fix Troubleshooting Drills

These scripts deliberately break a Kubernetes lab cluster to help you practice diagnosis and recovery — part of the CKA skill chain.

## DESTRUCTIVE WARNING ⚠️

**These scripts are DESTRUCTIVE and intended for lab nodes only.** Do not run on production clusters. They will intentionally break components, disrupt workloads, or corrupt configurations.

## The Break → Diagnose → Fix → Reset Loop

Each script breaks a specific Kubernetes component or configuration. Your task is to:

1. **Break:** Run the script to intentionally break the component.
2. **Diagnose:** Use kubectl, systemctl, journalctl, or other tools to identify what went wrong.
3. **Fix:** Restore the component to working order (scripts provide guidance).
4. **Reset (optional):** For full cluster recovery, run `../../cluster-setup/reset-cluster.sh` and re-join the node.

## Scripts

- **`break-kubelet.sh`** — Stops the kubelet service, causing the node to go NotReady. Diagnose with `systemctl status kubelet` and `journalctl -u kubelet`; fix by restarting it.

- **`break-static-pod.sh`** — Corrupts the kube-scheduler static pod manifest by appending invalid YAML. A backup is saved to `/tmp/kube-scheduler.yaml.bak`; restore from it to fix.

- **`break-service-selector.sh`** — Patches a Service selector to a non-matching label, leaving endpoints empty. Usage: `./break-service-selector.sh <namespace> <service>`; diagnose with `kubectl get endpoints`; fix by patching the selector back.

- **`break-coredns.sh`** — Scales CoreDNS to 0 replicas so in-cluster DNS resolution fails. Diagnose with `nslookup` from a running pod; fix by scaling CoreDNS back to 2.

- **`break-deployment.sh`** — Creates deployment `web` (nginx:1.27) in namespace `drill`, waits for it to be ready, then sets a non-existent image to trigger a stuck rollout (ProgressDeadlineExceeded / ImagePullBackOff). Fix with `rollout undo` or `set image`; clean up with `kubectl delete ns drill`.

- **`break-node-schedule.sh`** — Taints all nodes with `drill=true:NoSchedule` and creates a Pending pod `drill-pending` in namespace `drill`. Diagnose via `describe pod` events and node taints; fix by removing the taint. Clean up with `kubectl delete ns drill`.

- **`break-random.sh`** — Mystery mode: picks one break script at random and runs it silently. See [Mystery mode](#mystery-mode) below.

## Mystery mode

`break-random.sh` selects one of the other break scripts at random and runs it with output suppressed, so you must diagnose blind from cluster symptoms alone.

```bash
./break-random.sh
# "Something in the cluster is now broken. Find it and fix it."
```

**Log-file escape hatch:** if you are truly stuck, the chosen script name and its full output are written to `/tmp/break-fix-last.log`:

```bash
cat /tmp/break-fix-last.log
```

**sudo caveat:** `break-kubelet.sh` and `break-static-pod.sh` invoke `sudo` internally. If either is selected you may see a sudo password prompt — the prompt itself is a hint that a node-level component is involved. This is intentional and acceptable in mystery mode.

## Full Recovery

If you need a complete cluster reset (e.g., after multiple breaks or to wipe the node):

```bash
../../cluster-setup/reset-cluster.sh
```

Then re-join the node to the cluster using the control plane's join token.
