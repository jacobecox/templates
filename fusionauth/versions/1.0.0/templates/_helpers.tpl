{{/*
FusionAuth Workload Name
*/}}
{{- define "fusionauth.name" -}}
{{- printf "%s" .Release.Name }}
{{- end }}

{{/*
PostgreSQL Workload Name (for database connection)
*/}}
{{- define "postgres.pg.name" -}}
{{- printf "%s" .Release.Name }}
{{- end }}

{{/*
Secret Name for PostgreSQL Configuration
*/}}
{{- define "postgres.pg.secretName" -}}
{{- printf "%s-conf" (include "postgres.pg.name" .) }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "fusionauth.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "fusionauth.tags" -}}
helm.sh/chart: {{ include "fusionauth.chart" . }}
{{ include "fusionauth.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.cpln.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.cpln.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "fusionauth.selectorLabels" -}}
app.cpln.io/name: {{ .Release.Name }}
app.cpln.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
PostgreSQL Host Name
*/}}
{{- define "fusionauth.postgresHost" -}}
{{- printf "%s" .Release.Name }}
{{- end }}

{{/*
Database URL
*/}}
{{- define "fusionauth.databaseURL" -}}
{{- printf "jdbc:postgresql://%s.%s.cpln.local:5432/test" (include "fusionauth.postgresHost" .) .Values.cpln.gvc }}
{{- end }}

{{/*
Secret Reference for PostgreSQL Password
*/}}
{{- define "fusionauth.postgresPasswordSecret" -}}
{{- printf "cpln://secret/%s.password" (include "postgres.pg.secretName" .) }}
{{- end }}

{{/*
Secret Reference for PostgreSQL Username
*/}}
{{- define "fusionauth.postgresUsernameSecret" -}}
{{- printf "cpln://secret/%s.username" (include "postgres.pg.secretName" .) }}
{{- end }}
