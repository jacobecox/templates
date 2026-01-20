{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "manticore.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "manticore.tags" -}}
helm.sh/chart: {{ include "manticore.chart" . }}
{{ include "manticore.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.cpln.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.cpln.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "manticore.selectorLabels" -}}
app.cpln.io/name: {{ .Release.Name }}
app.cpln.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Generate JSON mapping of table names to CSV paths for orchestrator
Output: {"addresses":"imports/addresses/data.csv","products":"imports/products/data.csv"}
*/}}
{{- define "manticore.tablesConfigJSON" -}}
{{- $config := dict -}}
{{- range . -}}
{{- $_ := set $config .name .csvPath -}}
{{- end -}}
{{- $config | toJson -}}
{{- end }}

{{/*
Calculate total load test duration in seconds (duration + buffer)
Parses duration strings like "5m", "1h", "30s"
*/}}
{{- define "loadTest.totalDurationSeconds" -}}
{{- $duration := .Values.loadTest.duration -}}
{{- $buffer := .Values.loadTest.controller.testDurationBuffer | int -}}
{{- $seconds := 0 -}}
{{- if hasSuffix "s" $duration -}}
  {{- $seconds = trimSuffix "s" $duration | int -}}
{{- else if hasSuffix "m" $duration -}}
  {{- $seconds = mul (trimSuffix "m" $duration | int) 60 -}}
{{- else if hasSuffix "h" $duration -}}
  {{- $seconds = mul (trimSuffix "h" $duration | int) 3600 -}}
{{- end -}}
{{- add $seconds $buffer -}}
{{- end }}