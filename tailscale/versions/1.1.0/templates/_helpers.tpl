{{/*
Name of the chart
*/}}
{{- define "ts.name" -}}
{{- printf "%s" .Release.Name }}
{{- end }}