#!/usr/bin/env bash
#
# Renders the root-application Helm template into a concrete Argo CD
# Application manifest, one per cluster, using that cluster's own
# cluster_values.yaml as the variable source.
#
# Usage:
#   ./render-root-apps.sh                 # render every cluster under eks_new/clusters/*
#   ./render-root-apps.sh devcluster01     # render just one cluster
#
# Output:
#   eks_new/clusters/<cluster>/root-application.yaml
#
# This file is meant to be committed to git (for review/audit) and then
# applied ONCE per cluster to that cluster's own dedicated GitOps agent,
# e.g.:
#   kubectl --context <cluster-context> -n argocd apply \
#     -f eks_new/clusters/<cluster>/root-application.yaml
#
# From that point on, everything below the root Application (the
# applicationsets ApplicationSet, and every app it creates) is continuously
# reconciled by Argo CD itself - this script/manual apply only ever runs
# again if you change the root-application chart or that cluster's
# identity fields (name/environment/project/gitopsAgentId/server).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EKS_NEW_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
CHART_DIR="${SCRIPT_DIR}/root-application"
CLUSTERS_DIR="${EKS_NEW_DIR}/clusters"

render_cluster() {
  local cluster_name="$1"
  local values_file="${CLUSTERS_DIR}/${cluster_name}/cluster_values.yaml"
  local out_file="${CLUSTERS_DIR}/${cluster_name}/root-application.yaml"

  if [[ ! -f "${values_file}" ]]; then
    echo "skip: ${values_file} not found" >&2
    return
  fi

  echo "rendering ${cluster_name} -> ${out_file}"
  helm template root-application "${CHART_DIR}" \
    -f "${values_file}" \
    > "${out_file}"
}

if [[ $# -eq 1 ]]; then
  render_cluster "$1"
else
  for dir in "${CLUSTERS_DIR}"/*/; do
    render_cluster "$(basename "${dir}")"
  done
fi
