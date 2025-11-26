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
app.cpln.io/postgres-host: {{ include "fusionauth.postgresHost" . }}
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
{{- printf "%s-pg-db" .Release.Name }}
{{- end }}
