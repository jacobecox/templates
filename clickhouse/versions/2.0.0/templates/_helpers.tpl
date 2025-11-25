{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "clickhouse.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "clickhouse.tags" -}}
helm.sh/chart: {{ include "clickhouse.chart" . }}
{{ include "clickhouse.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.cpln.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.cpln.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "clickhouse.selectorLabels" -}}
app.cpln.io/name: {{ .Release.Name }}
app.cpln.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "clickhouse.validateStorage" -}}
{{- $awsEnabled := .Values.aws.enabled -}}
{{- $gcpEnabled := .Values.gcp.enabled -}}
{{- if and $awsEnabled $gcpEnabled -}}
  {{- fail "Only one storage option can be enabled. Please enable either AWS or GCP, not both." -}}
{{- end -}}
{{- if and (not $awsEnabled) (not $gcpEnabled) -}}
  {{- fail "A storage option must be selected. Please enable either AWS or GCP." -}}
{{- end -}}
{{- if $awsEnabled -}}
  {{- if not .Values.aws.s3.bucket -}}
    {{- fail "All fields are required for S3 when enabled. Missing: bucket" -}}
  {{- end -}}
  {{- if not .Values.aws.s3.region -}}
    {{- fail "All fields are required for S3 when enabled. Missing: region" -}}
  {{- end -}}
  {{- if not .Values.aws.s3.cloudAccountName -}}
    {{- fail "All fields are required for S3 when enabled. Missing: cloudAccountName" -}}
  {{- end -}}
  {{- if not .Values.aws.s3.policyName -}}
    {{- fail "All fields are required for S3 when enabled. Missing: policyName" -}}
  {{- end -}}
{{- end -}}
{{- if $gcpEnabled -}}
  {{- if not .Values.gcp.gcs.bucket -}}
    {{- fail "All fields are required for GCS when enabled. Missing: bucket" -}}
  {{- end -}}
  {{- if not .Values.gcp.gcs.accessKeyId -}}
    {{- fail "All fields are required for GCS when enabled. Missing: accessKeyId" -}}
  {{- end -}}
  {{- if not .Values.gcp.gcs.secretAccessKey -}}
    {{- fail "All fields are required for GCS when enabled. Missing: secretAccessKey" -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{- define "clickhouse.validateLocations" -}}
{{- if lt (len .Values.gvc.locations) 3 -}}
  {{- fail "3 or more locations must be specified." -}}
{{- end -}}
{{- end -}}