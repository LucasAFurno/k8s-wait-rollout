#!/usr/bin/env bash
# Name: k8s-wait-rollout.sh
# Author: Lucas Furno
# Description: Waits for a Kubernetes resource rollout to complete with a timeout.
# On failure, prints a quick triage (describe + recent events).

set -euo pipefail

KIND="deployment"     # deployment|statefulset|daemonset
NAMESPACE="default"
TIMEOUT="120s"

usage() {
  cat <<EOF
Usage:
  $(basename "$0") [OPTIONS] <name>

Options:
  -k, --kind       Resource kind (deployment|statefulset|daemonset). Default: deployment
  -n, --namespace  Kubernetes namespace. Default: default
  -t, --timeout    Rollout wait timeout (e.g., 60s, 2m). Default: 120s
  -h, --help       Show this help

Examples:
  $(basename "$0") -n qa web-api
  $(basename "$0") -k statefulset -n db postgres
EOF
}

die() { echo "ERROR: $*" >&2; exit 1; }

# Parse args
if [[ $# -eq 0 ]]; then usage; exit 1; fi
ARGS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    -k|--kind) KIND="${2:-}"; shift 2 ;;
    -n|--namespace) NAMESPACE="${2:-}"; shift 2 ;;
    -t|--timeout) TIMEOUT="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    --) shift; break ;;
    -* ) die "Unknown option: $1" ;;
     * ) ARGS+=("$1"); shift ;;
  esac
done
set -- "${ARGS[@]:-}"

NAME="${1:-}"
[[ -z "${NAME}" ]] && { usage; exit 1; }

echo "🔄 Waiting for rollout of ${KIND}/${NAME} in namespace ${NAMESPACE} (timeout: ${TIMEOUT})..."
set +e
kubectl -n "${NAMESPACE}" rollout status "${KIND}/${NAME}" --timeout="${TIMEOUT}"
RC=$?
set -e

if [[ $RC -eq 0 ]]; then
  echo "✅ Rollout completed successfully."
  exit 0
fi

echo "❌ Rollout did NOT complete within ${TIMEOUT} or failed."
echo "— — — Describe ${KIND}/${NAME} — — —"
kubectl -n "${NAMESPACE}" describe "${KIND}/${NAME}" || true

echo
echo "— — — Recent namespace events (last 20) — — —"
kubectl -n "${NAMESPACE}" get events --sort-by=.lastTimestamp | tail -n 20 || true

# Try to surface pods owned by this controller (best-effort)
echo
echo "— — — Pods for ${KIND}/${NAME} (best-effort) — — —"
kubectl -n "${NAMESPACE}" get pods --show-labels | grep -Ei "${NAME}" || true

exit $RC
