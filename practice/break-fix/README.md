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

## Full Recovery

If you need a complete cluster reset (e.g., after multiple breaks or to wipe the node):

```bash
../../cluster-setup/reset-cluster.sh
```

Then re-join the node to the cluster using the control plane's join token.
