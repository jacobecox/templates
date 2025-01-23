{{- define "calculateWorkloadCounts" -}}
{{- $quorumCount := int .Values.sentinel.quorum }}
{{- $workloadCount := 0 }}
{{- if eq $quorumCount 1 }}
  {{- $workloadCount = 1 }}
{{- else }}
  {{- $workloadCount = int (add $quorumCount 1) }}
{{- end }}
{{- $locations := default (list) .Values.locations }}
{{- if and $locations (gt (len $locations) 0) }}
  {{- $locationCount := (len $locations) }}
  {{- $baseCount := int (div $workloadCount $locationCount) }}
  {{- $remainderCount := int (mod $workloadCount $locationCount) }}
  {{- if not .Values.global }}
    {{- $ := set .Values "global" (dict) }}
  {{- end }}
  {{- $ := set .Values.global "baseCount" $baseCount }}
  {{- $ := set .Values.global "remainderCount" $remainderCount }}
  {{- $ := set .Values.global "locationCount" $locationCount }}
  {{- $ := set .Values.global "workloadCount" $workloadCount }}
{{- end }}
{{- end }}
