{{/*
MongoDB Workload Name
*/}}
{{- define "mongo.name" -}}
{{- printf "%s" .Release.Name }}
{{- end }}

{{/*
Secret Name for MongoDB Configuration
*/}}
{{- define "mongo.secretName" -}}
{{- printf "%s-conf" (include "mongo.name" .) }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "mongo.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "mongo.tags" -}}
helm.sh/chart: {{ include "mongo.chart" . }}
{{ include "mongo.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.cpln.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.cpln.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "mongo.selectorLabels" -}}
app.cpln.io/name: {{ .Release.Name }}
app.cpln.io/instance: {{ .Release.Name }}
{{- end }}
