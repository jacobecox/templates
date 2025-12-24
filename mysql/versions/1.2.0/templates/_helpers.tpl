{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "mysql.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "mysql.tags" -}}
helm.sh/chart: {{ include "mysql.chart" . }}
{{ include "mysql.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.cpln.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.cpln.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "mysql.selectorLabels" -}}
app.cpln.io/name: {{ .Release.Name }}
app.cpln.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Validate backup configuration - when backup is enabled, exactly one of aws.enabled or gcp.enabled must be true
*/}}
{{- define "mysql.validateBackupConfig" -}}
{{- $awsEnabled := .Values.backup.aws.enabled -}}
{{- $gcpEnabled := .Values.backup.gcp.enabled -}}
{{- if .Values.backup.enabled -}}
  {{- if and $awsEnabled $gcpEnabled -}}
    {{- fail "Invalid backup configuration: both aws.enabled and gcp.enabled are true. Please enable only one backup provider." -}}
  {{- end -}}
  {{- if not (or $awsEnabled $gcpEnabled) -}}
    {{- fail "Invalid backup configuration: backup.enabled is true but neither aws.enabled nor gcp.enabled is set. Please enable exactly one backup provider." -}}
  {{- end -}}
{{- else -}}
  {{- if or $awsEnabled $gcpEnabled -}}
    {{- fail "Invalid backup configuration: aws.enabled or gcp.enabled is true but backup.enabled is false. Please set backup.enabled to true." -}}
  {{- end -}}
{{- end -}}
{{- end }}