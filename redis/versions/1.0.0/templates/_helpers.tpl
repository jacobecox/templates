{{/*
Redis Workload Name
*/}}
{{- define "redis.name" -}}
{{- printf "%s" .Release.Name }}
{{- end }}