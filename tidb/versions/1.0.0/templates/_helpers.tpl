{{/*
TiDB PD Workload Name
*/}}
{{- define "tidb.pdName" -}}
{{- printf "%s-pd" .Release.Name }}
{{- end }}

{{/*
TiDB Server Workload Name
*/}}
{{- define "tidb.serverName" -}}
{{- printf "%s-server" .Release.Name }}
{{- end }}

{{/*
TiDB TiKV Workload Name
*/}}
{{- define "tidb.tikvName" -}}
{{- printf "%s-tikv" .Release.Name }}
{{- end }}

{{/*
TiDB Identity Name
*/}}
{{- define "tidb.identityName" -}}
{{- printf "%s-tidb-identity" .Release.Name }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "tidb.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}