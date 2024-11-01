{{/*
MariaDB Workload Name
*/}}
{{- define "maria.name" -}}
{{- printf "%s" .Release.Name }}
{{- end }}

{{/*
Secret Name for MariaDB Configuration
*/}}
{{- define "maria.secretName" -}}
{{- printf "%s-conf" (include "maria.name" .) }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "maria.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "maria.tags" -}}
helm.sh/chart: {{ include "maria.chart" . }}
{{ include "maria.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.cpln.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.cpln.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "maria.selectorLabels" -}}
app.cpln.io/name: {{ .Release.Name }}
app.cpln.io/instance: {{ .Release.Name }}
{{- end }}
