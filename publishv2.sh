#!/bin/bash

set -euo pipefail

REGISTRY_HOST="${REGISTRY:-ghcr.io}"
REGISTRY_NAMESPACE="${NAMESPACE:-hoverhuang-er/charts}"
PACKAGE_DIR="${PACKAGE_DIR:-dist}"

mkdir -p "${PACKAGE_DIR}"

# Find all Chart.yaml files recursively
echo "==> Searching for Helm charts..."
while IFS= read -r chart_yaml; do
    chart_path=$(dirname "${chart_yaml}")
    chart_name=$(basename "${chart_path}")

    echo "\n==> Building dependencies for ${chart_name}"
    helm dependency update "${chart_path}"

    echo "==> Packaging ${chart_name}"
    package_output=$(helm package "${chart_path}" --destination "${PACKAGE_DIR}")
    package_path=$(echo "${package_output}" | awk '{print $NF}')

    if [[ ! -f "${package_path}" ]]; then
        echo "Failed to locate packaged chart at ${package_path}" >&2
        exit 1
    fi

    echo "==> Pushing ${package_path} to oci://${REGISTRY_HOST}/${REGISTRY_NAMESPACE}"
    helm push "${package_path}" "oci://${REGISTRY_HOST}/${REGISTRY_NAMESPACE}"
done < <(find . -name "Chart.yaml" -type f)

# Keep .tgz files for GitHub Release uploads when running from a tag
if [[ "${IS_TAG:-false}" != "true" ]]; then
    echo "\nCleaning packaged archives"
    find "${PACKAGE_DIR}" -name '*.tgz' -delete
else
    echo "\nKeeping packaged archives for GitHub Release"
    ls -lh "${PACKAGE_DIR}"/*.tgz 2>/dev/null || echo "No .tgz files found"
fi