{{/*
etcd Workload Name
*/}}
{{- define "etcd.name" -}}
{{- printf "%s" .Release.Name }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "etcd.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "etcd.tags" -}}
helm.sh/chart: {{ include "etcd.chart" . }}
{{ include "etcd.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.cpln.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.cpln.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "etcd.selectorLabels" -}}
app.cpln.io/name: {{ .Release.Name }}
app.cpln.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
VolumeSet Name
*/}}
{{- define "etcd.volumesetName" -}}
{{- printf "%s-etcd-vs" .Release.Name }}
{{- end }}

{{/*
etcd Client URL
*/}}
{{- define "etcd.clientURL" -}}
{{- printf "http://%s.%s.cpln.local:2379" .Release.Name .Values.global.cpln.gvc }}
{{- end }}
