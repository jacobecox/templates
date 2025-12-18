{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "tidb.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Validation: Ensure minimum 3 locations are defined
*/}}
{{- define "tidb.validateLocations" -}}
{{- $numLocs := len .Values.gvc.locations -}}
{{- if lt $numLocs 3 -}}
{{- fail (printf "TiDB requires at least 3 locations for high availability. Found %d location(s)." $numLocs) -}}
{{- end -}}
{{- end -}}

{{/*
Validation: Ensure pdReplicas is 3, 5, or 7
*/}}
{{- define "tidb.validatePdReplicas" -}}
{{- $pdReplicas := .Values.gvc.pdReplicas -}}
{{- if not (or (eq $pdReplicas 3) (eq $pdReplicas 5) (eq $pdReplicas 7)) -}}
{{- fail (printf "pdReplicas must be 3, 5, or 7. Found %d." (int $pdReplicas)) -}}
{{- end -}}
{{- end -}}

{{/*
Validation: Ensure pdReplicas=3 requires exactly 3 locations
*/}}
{{- define "tidb.validatePdReplicasLocations" -}}
{{- $pdReplicas := .Values.gvc.pdReplicas -}}
{{- $numLocs := len .Values.gvc.locations -}}
{{- if and (eq $pdReplicas 3) (ne $numLocs 3) -}}
{{- fail (printf "When pdReplicas is 3, exactly 3 locations are required. Found %d location(s)." $numLocs) -}}
{{- end -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "tidb.tags" -}}
helm.sh/chart: {{ include "tidb.chart" . }}
{{ include "tidb.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.cpln.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.cpln.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "tidb.selectorLabels" -}}
app.cpln.io/name: {{ .Release.Name }}
app.cpln.io/instance: {{ .Release.Name }}
{{- end }}