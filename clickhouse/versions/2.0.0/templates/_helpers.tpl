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
{{- if not .Values.aws.enabled -}}
  {{- fail "A storage option must be selected. Please enable either AWS or GCP." -}}
{{- end -}}
{{- if .Values.aws.enabled -}}
  {{- if not .Values.aws.s3.bucket -}}
    {{- fail "All fields are required for S3 when enabled. Missing: bucket" -}}
  {{- end -}}
  {{- if not .Values.aws.s3.region -}}
    {{- fail "All fields are required for S3 when enabled. Missing: region" -}}
  {{- end -}}
  {{- if not .Values.aws.s3.roleArn -}}
    {{- fail "All fields are required for S3 when enabled. Missing: roleArn" -}}
  {{- end -}}
  {{- if not .Values.aws.s3.policyName -}}
    {{- fail "All fields are required for S3 when enabled. Missing: policyName" -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{- define "clickhouse.validateLocations" -}}
{{- if lt (len .Values.gvc.locations) 3 -}}
  {{- fail "3 or more locations must be specified." -}}
{{- end -}}
{{- end -}}