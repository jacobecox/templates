{{/*
Validate that gvc.locations has at least 2 entries
*/}}
{{- define "cockroach.validateLocations" -}}
{{- if lt (len .Values.gvc.locations) 2 -}}
{{- fail "gvc.locations must contain at least 2 locations for CockroachDB multi-region deployment" -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "cockroach.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "cockroach.tags" -}}
helm.sh/chart: {{ include "cockroach.chart" . }}
{{ include "cockroach.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.cpln.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.cpln.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "cockroach.selectorLabels" -}}
app.cpln.io/name: {{ .Release.Name }}
app.cpln.io/instance: {{ .Release.Name }}
{{- end }}