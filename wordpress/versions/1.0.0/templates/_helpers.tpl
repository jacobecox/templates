{{/*
Wordpress Workload Name
*/}}
{{- define "wp.name" -}}
{{- printf "%s" .Release.Name }}
{{- end }}

{{/*
Secret Name for Wordpress Configuration
*/}}
{{- define "wp.secretName" -}}
{{- printf "%s-conf" (include "wp.name" .) }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "wp.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "wp.tags" -}}
helm.sh/chart: {{ include "wp.chart" . }}
{{ include "wp.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.cpln.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.cpln.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "wp.selectorLabels" -}}
app.cpln.io/name: {{ .Release.Name }}
app.cpln.io/instance: {{ .Release.Name }}
{{- end }}
