{{/* Resource Naming */}}

{{/*
Airflow Celery Workload Name
*/}}
{{- define "airflow.celeryName" -}}
{{- printf "%s-airflow-celery-worker" .Release.Name }}
{{- end }}

{{/*
Airflow Webserver Workload Name
*/}}
{{- define "airflow.webserverName" -}}
{{- printf "%s-airflow-webserver" .Release.Name }}
{{- end }}

{{/*
Airflow Postgres Workload Name
*/}}
{{- define "airflow.postgresName" -}}
{{- printf "%s-airflow-postgres" .Release.Name }}
{{- end }}

{{/*
Airflow Redis Workload Name
*/}}
{{- define "airflow.redisName" -}}
{{- printf "%s-airflow-redis" .Release.Name }}
{{- end }}

{{/*
Airflow Secret Name
*/}}
{{- define "airflow.secretName" -}}
{{- printf "%s-airflow-config" .Release.Name }}
{{- end }}

{{/*
Airflow Identity Name
*/}}
{{- define "airflow.identityName" -}}
{{- printf "%s-airflow-identity" .Release.Name }}
{{- end }}

{{/*
Airflow Policy Name
*/}}
{{- define "airflow.policyName" -}}
{{- printf "%s-airflow-policy" .Release.Name }}
{{- end }}

{{/*
Airflow Volume Set Name
*/}}
{{- define "airflow.volumeName" -}}
{{- printf "%s-airflow-vs" .Release.Name }}
{{- end }}

{{/*
Postgres Volume Set Name
*/}}
{{- define "airflow.postgresVolumeName" -}}
{{- printf "%s-airflow-postgres-vs" .Release.Name }}
{{- end }}


{{/* Labeling */}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "airflow.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "airflow.tags" -}}
helm.sh/chart: {{ include "airflow.chart" . }}
{{ include "airflow.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.cpln.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.cpln.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "airflow.selectorLabels" -}}
app.cpln.io/name: {{ .Release.Name }}
app.cpln.io/instance: {{ .Release.Name }}
{{- end }}
