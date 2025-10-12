<!-- markdownlint-disable MD041 -->

# Helm Charts Collection

Curated Helm charts maintained in this repository, ready to deploy to any Kubernetes cluster using [Helm](https://github.com/helm/helm).

## TL;DR

```console
helm install my-release oci://ghcr.io/hoverhuang-er/charts/<chart>
```

Replace `<chart>` with any package published to the GitHub Container Registry namespace `oci://ghcr.io/hoverhuang-er/charts` or install directly from the local `charts` directory if you are developing.

## Prerequisites

- Kubernetes 1.23+
- Helm 3.8.0+

## Getting Started

1. Clone the repository.
2. Package or pull the chart you need from the `charts` directory or the GitHub Container Registry (`oci://ghcr.io/hoverhuang-er/charts`).
3. Deploy it with `helm install` using the values that suit your environment.

```console
git clone https://github.com/Hoverhuang-er/charts.git
cd charts
helm dependency update charts/<chart>
helm install my-release oci://ghcr.io/hoverhuang-er/charts/<chart> --values values.yaml
```

Push updates with `helm push charts/<chart>-<version>.tgz oci://ghcr.io/hoverhuang-er/charts` to keep the registry in sync. If you maintain an alternate registry, adjust the `oci://` prefix accordingly.

## Working With Charts

- Keep `values.yaml` minimal by leveraging upstream defaults.
- Use `helm template` to render manifests locally before applying them to production clusters.
- Validate chart updates with `helm lint` and integration tests suited to your workloads.
- Document chart-specific configuration in the corresponding chart README.

## Contributing

Contributions are welcome. Please:

- Open an issue describing the change or new chart.
- Follow semantic versioning when updating chart versions.
- Run `helm lint` and any chart-specific tests before submitting a pull request.

## License

This repository is licensed under the Apache License 2.0. See `LICENSE.md` for details.