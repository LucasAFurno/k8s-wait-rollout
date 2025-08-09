```markdown
# Kubernetes Rollout Waiter

A small Bash utility to wait for a Kubernetes rollout to finish with a timeout.  
If the rollout does not complete, it prints a quick triage including:
- `kubectl describe` of the resource
- The last 20 events in the namespace
- A best-effort pod listing to spot failing pods

## Why?
CI/CD pipelines and on-call runbooks often need a **simple, portable** way to:
- Block until a Deployment/StatefulSet/DaemonSet finishes rolling out
- Dump useful context automatically when it **doesn't**

## Requirements
- `kubectl` installed and authenticated to the target cluster

## Usage
```bash
chmod +x k8s-wait-rollout.sh
./k8s-wait-rollout.sh [OPTIONS] <name>
```

**Options**
- `-k, --kind`       Resource kind. One of: `deployment`, `statefulset`, `daemonset`. Default: `deployment`
- `-n, --namespace`  Namespace. Default: `default`
- `-t, --timeout`    Timeout, e.g. `60s`, `2m`. Default: `120s`

**Examples**
```bash
# Wait for a Deployment in qa
./k8s-wait-rollout.sh -n qa web-api

# Wait for a StatefulSet in db namespace with a 3-minute timeout
./k8s-wait-rollout.sh -k statefulset -n db -t 3m postgres
```

## Exit Codes
- `0`  Rollout completed successfully
- `1`  Invalid usage or an error occurred
- `>0` Propagates `kubectl rollout status` non-zero exit on failure/timeout

## Notes
- This script is intentionally dependency-free (plain Bash + kubectl).
- Event sorting is best-effort and may vary across Kubernetes versions.
```
