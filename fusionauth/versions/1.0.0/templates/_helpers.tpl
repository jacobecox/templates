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
PostgreSQL Host Name
*/}}
{{- define "fusionauth.postgresHost" -}}
{{- printf "%s-db" .Release.Name }}
{{- end }}

{{/*
Database URL
*/}}
{{- define "fusionauth.databaseURL" -}}
{{- printf "jdbc:postgresql://%s.%s.cpln.local:5432/%s" (include "fusionauth.postgresHost" .) .Values.global.cpln.gvc .Values.postgres.config.database }}
{{- end }}