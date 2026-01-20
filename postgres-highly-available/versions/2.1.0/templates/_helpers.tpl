{{/* Resource Naming */}}

{{/*
Postgres HA Workload Name
*/}}
{{- define "pg-ha.name" -}}
{{- printf "%s-postgres-ha" .Release.Name }}
{{- end }}

{{/*
Postgres HA etcd Workload Name
*/}}
{{- define "pg-ha.etcdName" -}}
{{- printf "%s-etcd" .Release.Name }}
{{- end }}

{{/*
Postgres HA Proxy Workload Name
*/}}
{{- define "pg-ha.proxyName" -}}
{{- printf "%s-postgres-ha-proxy" .Release.Name }}
{{- end }}

{{/*
Postgres HA Workload Logical Backup Name
*/}}
{{- define "pg-ha.backupName" -}}
{{- printf "%s-postgres-ha-backup" .Release.Name }}
{{- end }}

{{/*
Postgres HA Secret Database Config Name
*/}}
{{- define "pg-ha.secretDatabaseName" -}}
{{- printf "%s-postgres-config" .Release.Name }}
{{- end }}

{{/*
Postgres HA Secret Startup Name
*/}}
{{- define "pg-ha.secretStartupName" -}}
{{- printf "%s-postgres-proxy-startup" .Release.Name }}
{{- end }}

{{/*
Postgres HA Secret Proxy Startup Name
*/}}
{{- define "pg-ha.secretProxyStartupName" -}}
{{- printf "%s-patroni-startup" .Release.Name }}
{{- end }}

{{/*
Postgres HA Secret WAL-G Backup Startup Name
*/}}
{{- define "pg-ha.secretWALGStartupName" -}}
{{- printf "%s-wal-g-backup-script" .Release.Name }}
{{- end }}

{{/*
Postgres HA Identity Name
*/}}
{{- define "pg-ha.identityName" -}}
{{- printf "%s-postgres-ha-identity" .Release.Name }}
{{- end }}

{{/*
Postgres HA Policy Name
*/}}
{{- define "pg-ha.policyName" -}}
{{- printf "%s-postgres-ha-policy" .Release.Name }}
{{- end }}

{{/*
Postgres HA Volume Set Name
*/}}
{{- define "pg-ha.volumeName" -}}
{{- printf "%s-postgres-ha-vs" .Release.Name }}
{{- end }}


{{/* Validation */}}

{{/*
Validate backup mode - must be "logical" or "wal-g"
*/}}
{{- define "pg-ha.validateBackupMode" -}}
{{- $mode := .Values.backup.mode -}}
{{- if and .Values.backup.enabled (not (or (eq $mode "logical") (eq $mode "wal-g"))) -}}
  {{- fail (printf "Invalid backup.mode: '%s'. Must be either 'logical' or 'wal-g'." $mode) -}}
{{- end -}}
{{- end }}

{{/*
Validate backup configuration - when backup is enabled, exactly one of aws.enabled or gcp.enabled must be true
*/}}
{{- define "pg-ha.validateBackupConfig" -}}
{{- include "pg-ha.validateBackupMode" . -}}
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
{{- define "pg-ha.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "pg-ha.tags" -}}
helm.sh/chart: {{ include "pg-ha.chart" . }}
{{ include "pg-ha.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.cpln.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.cpln.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "pg-ha.selectorLabels" -}}
app.cpln.io/name: {{ .Release.Name }}
app.cpln.io/instance: {{ .Release.Name }}
{{- end }}