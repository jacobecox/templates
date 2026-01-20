{{/* Resource Naming */}}

{{/*
Postgres Workload Name
*/}}
{{- define "postgres.name" -}}
{{- printf "%s-postgres" .Release.Name }}
{{- end }}

{{/*
Postgres Backup Workload Name
*/}}
{{- define "postgres.backupName" -}}
{{- printf "%s-pg-backup" .Release.Name }}
{{- end }}

{{/*
Postgres Secret Database Config Name
*/}}
{{- define "postgres.secretDatabaseName" -}}
{{- printf "%s-pg-config" .Release.Name }}
{{- end }}

{{/*
Postgres Identity Name
*/}}
{{- define "postgres.identityName" -}}
{{- printf "%s-pg-identity" .Release.Name }}
{{- end }}

{{/*
Postgres Policy Name
*/}}
{{- define "postgres.policyName" -}}
{{- printf "%s-pg-policy" .Release.Name }}
{{- end }}

{{/*
Postgres Volume Set Name
*/}}
{{- define "postgres.volumeName" -}}
{{- printf "%s-pg-vs" .Release.Name }}
{{- end }}


{{/* Validation */}}

{{/*
Validate backup configuration - when backup is enabled, exactly one of aws.enabled or gcp.enabled must be true
*/}}
{{- define "pg.validateBackupConfig" -}}
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


{{/* Labeling */}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "pg.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "pg.tags" -}}
helm.sh/chart: {{ include "pg.chart" . }}
{{ include "pg.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.cpln.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.cpln.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "pg.selectorLabels" -}}
app.cpln.io/name: {{ .Release.Name }}
app.cpln.io/instance: {{ .Release.Name }}
{{- end }}