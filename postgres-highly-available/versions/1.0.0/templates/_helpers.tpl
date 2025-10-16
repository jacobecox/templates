{{/*
Patroni PostgreSQL Workload Name
*/}}
{{- define "patroni.name" -}}
{{- printf "%s-patroni-postgres" .Release.Name }}
{{- end }}

{{/*
Secret Name for PostgreSQL Configuration
*/}}
{{- define "patroni.configSecretName" -}}
{{- printf "%s-postgres-config" .Release.Name }}
{{- end }}

{{/*
Secret Name for Patroni Startup Script
*/}}
{{- define "patroni.startupSecretName" -}}
{{- printf "%s-patroni-startup" .Release.Name }}
{{- end }}

{{/*
VolumeSet Name
*/}}
{{- define "patroni.volumeSetName" -}}
{{- printf "%s-postgres-vs" .Release.Name }}
{{- end }}

{{/*
Identity Name
*/}}
{{- define "patroni.identityName" -}}
{{- printf "%s-patroni-postgres-identity" .Release.Name }}
{{- end }}

{{/*
Policy Name
*/}}
{{- define "patroni.policyName" -}}
{{- printf "%s-patroni-postgres-%s-policy" .Release.Name .Values.global.cpln.gvc }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "patroni.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}
