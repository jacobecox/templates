{{/*
DBeaver Workload Name
*/}}
{{- define "dbeaver.name" -}}
{{- printf "%s-dbeaver" .Release.Name }}
{{- end }}

{{/*
Secret Name for DBeaver Admin Configuration
*/}}
{{- define "dbeaver.secretName" -}}
{{- printf "%s-admin-config" .Release.Name }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "dbeaver.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
VolumeSet Name
*/}}
{{- define "dbeaver.volumeSetName" -}}
{{- printf "%s-dbeaver-vs" .Release.Name }}
{{- end }}
