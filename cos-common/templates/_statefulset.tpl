{{/* Render a StatefulSet for the component, reusing the shared pod spec helpers. */}}
{{- define "cos-common.statefulset" -}}
{{- $vals := default dict .values -}}
{{- $enabled := include "cos-common.componentEnabled" (dict "values" $vals) | fromYaml -}}
{{- if $enabled }}
{{- $annotations := include "cos-common.annotations" (dict "values" $vals "isWorkload" true) | fromJson -}}
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  {{- /* Reuse metadata helper so StatefulSet and its pods share labels/annotations. */}}
  {{- $metadataVals := merge (dict) $vals (dict "annotations" $annotations) -}}
  {{- include "cos-common.metadata" (dict "root" .root "name" .name "values" $metadataVals) | nindent 2 }}
spec:
  {{- /* StatefulSet needs a headless service name; default to the component fullname. */}}
  serviceName: {{ default (include "cos-common.fullname" .) $vals.serviceName }}
  replicas: {{ default 1 $vals.replicas }}
  {{- with $vals.revisionHistoryLimit }}
  revisionHistoryLimit: {{ . }}
  {{ end }}
  {{- with $vals.minReadySeconds }}
  minReadySeconds: {{ . }}
  {{ end }}
  {{- with $vals.podManagementPolicy }}
  podManagementPolicy: {{ . }}
  {{ end }}
  {{- with $vals.updateStrategy }}
  updateStrategy:
    {{- tpl (toYaml .) $.root | nindent 4 }}
  {{ end }}
  {{- with $vals.ordinals }}
  ordinals:
    {{- tpl (toYaml .) $.root | nindent 4 }}
  {{ end }}
  selector:
    matchLabels:
      {{- include "cos-common.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      {{- include "cos-common.podMetadata" . | nindent 6 }}
    spec:
  {{- include "cos-common.podSpec" . | nindent 6 }}
  {{- with $vals.volumeClaimTemplates }}
  volumeClaimTemplates:
    {{- range $vct := . }}
    {{- /* Allow templated volume claims so each replica gets its own PVC. */}}
    - {{ tpl (toYaml $vct) $.root | nindent 6 }}
    {{ end }}
  {{ end }}
  {{- with $vals.persistentVolumeClaimRetentionPolicy }}
  persistentVolumeClaimRetentionPolicy:
    {{- tpl (toYaml .) $.root | nindent 4 }}
  {{ end }}
{{ end }}
{{ end }}
