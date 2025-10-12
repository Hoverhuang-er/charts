#!/bin/bash

set -euo pipefail

CHART_DIR="${CHART_DIR:-charts}"
REGISTRY_HOST="${REGISTRY:-ghcr.io}"
REGISTRY_NAMESPACE="${NAMESPACE:-hoverhuang-er/charts}"
PACKAGE_DIR="${PACKAGE_DIR:-dist}"

mkdir -p "${PACKAGE_DIR}"

for chart_path in "${CHART_DIR}"/*; do
    [[ -d "${chart_path}" ]] || continue
    [[ -f "${chart_path}/Chart.yaml" ]] || continue

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
done

echo "\nCleaning packaged archives"
find "${PACKAGE_DIR}" -name '*.tgz' -delete