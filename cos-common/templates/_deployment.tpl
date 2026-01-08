{{/* Render a Deployment for the component, wiring in the shared pod spec pieces. */}}
{{- define "cos-common.deployment" -}}
{{- $vals := default dict .values -}}
{{- $enabled := include "cos-common.componentEnabled" (dict "values" $vals) | fromYaml -}}
{{- if $enabled }}
{{- $annotations := include "cos-common.annotations" (dict "values" $vals "isWorkload" true) | fromJson -}}
---
apiVersion: apps/v1
kind: Deployment
metadata:
  {{- /* Merge base values with workload annotations so pod and owner share them. */}}
  {{- $metadataVals := merge (dict) $vals (dict "annotations" $annotations) -}}
  {{- include "cos-common.metadata" (dict "root" .root "name" .name "values" $metadataVals) | nindent 2 }}
spec:
  {{- /* Simple rollout defaults; caller can override counts and timing. */}}
  replicas: {{ default 1 $vals.replicas }}
  {{- with $vals.revisionHistoryLimit }}
  revisionHistoryLimit: {{ . }}
  {{ end }}
  {{- with $vals.minReadySeconds }}
  minReadySeconds: {{ . }}
  {{ end }}
  {{- with $vals.paused }}
  paused: {{ . }}
  {{ end }}
  {{- with $vals.progressDeadlineSeconds }}
  progressDeadlineSeconds: {{ . }}
  {{ end }}
  selector:
    matchLabels:
      {{- include "cos-common.selectorLabels" . | nindent 6 }}
  {{- with $vals.strategy }}
  strategy:
    {{- tpl (toYaml .) $.root | nindent 4 }}
  {{ end }}
  template:
    metadata:
      {{- /* Pod labels/annotations stay aligned with selectors. */}}
      {{- include "cos-common.podMetadata" . | nindent 6 }}
    spec:
      {{- /* Shared pod spec helper wires containers, volumes, TLS, affinities, etc. */}}
      {{- include "cos-common.podSpec" . | nindent 6 }}
{{ end }}
{{ end }}
