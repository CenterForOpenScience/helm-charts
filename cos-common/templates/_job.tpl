{{/* Render a one-shot Job for the component, leveraging the shared pod spec. */}}
{{- define "cos-common.job" -}}
{{- $vals := default dict .values -}}
{{- $enabled := include "cos-common.componentEnabled" (dict "values" $vals) | fromYaml -}}
{{- if $enabled }}
{{- $annotations := include "cos-common.annotations" (dict "values" $vals "isWorkload" true) | fromJson -}}
---
apiVersion: batch/v1
kind: Job
metadata:
  {{- /* Pass workload annotations through so pods inherit the same metadata. */}}
  {{- $metadataVals := merge (dict) $vals (dict "annotations" $annotations) -}}
  {{- include "cos-common.metadata" (dict "root" .root "name" .name "values" $metadataVals) | nindent 2 }}
spec:
  {{- /* jobSpec helper keeps CronJob and Job behavior consistent. */}}
  {{- include "cos-common.jobSpec" (dict "root" .root "name" .name "values" $vals "suspend" $vals.suspend "includeManualSelector" true) | nindent 2 }}
{{ end }}
{{ end }}
