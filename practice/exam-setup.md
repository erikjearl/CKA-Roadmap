# Exam Setup — Speed Layer

Paste these into the terminal at the very start of the exam session. They survive for the life of the shell.

## Shell Aliases and Variables

```bash
alias k=kubectl
export do='--dry-run=client -o yaml'
export now='--force --grace-period=0'
```

Usage examples:

```bash
# Generate a manifest without applying it
k create deploy web --image=nginx $do

# Generate a pod manifest
k run mypod --image=nginx $do

# Force-delete a pod immediately (no 30 s termination wait)
k delete pod mypod $now
```

## kubectl Autocompletion

```bash
source <(kubectl completion bash)
complete -o default -F __start_kubectl k
```

> Note: `complete -o default -F __start_kubectl k` wires completion to the `k` alias. Both lines are required — the first loads the completion function; the second registers it for the alias.

## Explore Resources Inline

```bash
# See all fields (recursive) — faster than switching to docs
kubectl explain pod --recursive
kubectl explain pod.spec.containers --recursive
kubectl explain networkpolicy.spec --recursive
```

## Output Formatting

### JSONPath

```bash
# List all pod names across all namespaces
k get pods -A -o jsonpath='{.items[*].metadata.name}'

# One name per line (use range)
k get pods -A -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}'

# Node internal IPs
k get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.addresses[?(@.type=="InternalIP")].address}{"\n"}{end}'
```

### Sort by field

```bash
k get pods -A --sort-by='.metadata.creationTimestamp'
k get pods -A --sort-by='.status.startTime'
```

### Custom columns

```bash
k get pods -A -o custom-columns='NAMESPACE:.metadata.namespace,NAME:.metadata.name,STATUS:.status.phase,NODE:.spec.nodeName'
```

### Wide output (quick node info)

```bash
k get pods -o wide
k get nodes -o wide
```

## Minimal ~/.vimrc

Paste once; persists for the session.

```vim
set number
set expandtab
set shiftwidth=2
set tabstop=2
```

> `set paste` disables auto-indent when pasting large blocks — toggle with `:set paste` / `:set nopaste`. Do NOT leave `set paste` permanently in the file; it disables other insert-mode features.

## tmux Basics (if the exam environment provides it)

| Action | Key |
|--------|-----|
| Split pane horizontally | `Ctrl-b "` |
| Split pane vertically | `Ctrl-b %` |
| Switch panes | `Ctrl-b <arrow>` |
| Detach session | `Ctrl-b d` |
| New window | `Ctrl-b c` |
| Next window | `Ctrl-b n` |

> The PSI exam browser runs in a locked-down desktop. tmux availability varies — confirm at the start rather than spending time configuring it.

## Context / Namespace Shortcuts

```bash
# Every task in the exam specifies a context — switch first, every time
kubectl config use-context <ctx>

# Set a default namespace for the session
kubectl config set-context --current --namespace=<ns>

# Check current context
kubectl config current-context
```
