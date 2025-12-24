{{/*
Expand the name of the chart.
*/}}
{{- define "azure-ai-services.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "azure-ai-services.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "azure-ai-services.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "azure-ai-services.labels" -}}
helm.sh/chart: {{ include "azure-ai-services.chart" . }}
{{ include "azure-ai-services.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "azure-ai-services.selectorLabels" -}}
app.kubernetes.io/name: {{ include "azure-ai-services.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "azure-ai-services.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "azure-ai-services.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Convert environment variable name to Kubernetes-safe format
Replaces invalid characters (:) with _ and reduces double underscores to single underscore
Kubernetes env var names only allow: letters, digits, '_', '-', '.' (cannot start with digit)
This preserves Azure container compatibility while satisfying Kubernetes requirements
*/}}
{{- define "azure-ai-services.envName" -}}
{{- $name := . -}}
{{- $name = replace ":" "_" $name -}}
{{- $name = replace "__" "_" $name -}}
{{- $name -}}
{{- end }}

{{/*
Generate mount path environment variable name with configurable separator
Supports: _, __, ., - (with auto-quoting for invalid Kubernetes characters)
*/}}
{{- define "azure-ai-services.mountEnvName" -}}
{{- $suffix := .suffix -}}
{{- $separator := .separator | default "__" -}}
{{- $name := printf "Mounts%s%s" $separator $suffix -}}
{{- include "azure-ai-services.envName" $name -}}
{{- end }}
