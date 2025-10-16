{{/*
etcd Workload Name
*/}}
{{- define "etcd.name" -}}
{{- printf "%s-etcd" .Release.Name }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "etcd.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
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