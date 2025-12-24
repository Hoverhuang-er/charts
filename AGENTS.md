# Chart Repository - Agent Guidelines

## Commands

- `helm lint <chart>` - Validate chart syntax and best practices
- `helm template <release-name> <chart>` - Render manifests locally before applying
- `helm dependency update <chart>` - Build/update chart dependencies
- `helm test <release-name>` - Run chart tests (uses templates/tests/*.yaml hooks)

## Code Style

- Templates: Use `{{-` and `-}}` for whitespace control, `nindent` for proper YAML indentation
- Helpers: Define in `_helpers.tpl` with naming pattern `<chart-name>.<function>` (e.g., `azure-ai-services.labels`)
- Labels: Follow Kubernetes conventions (`app.kubernetes.io/name`, `helm.sh/chart`, `managed-by`)
- Values: Document all options with inline comments in `values.yaml`, keep minimal by leveraging defaults
- Structure: Follow standard Helm layout - Chart.yaml, values.yaml, templates/_helpers.tpl, templates/*.yaml
- Naming: Truncate to 63 chars with `trimSuffix "-"` for Kubernetes DNS limits
- Versioning: Use semantic versioning for chart versions, update appVersion separately

## Important Rules

- Do not write any markdown to this GitHub repo
- Any comment only accept adding as comment with code file
