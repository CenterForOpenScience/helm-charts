{{/* Render a PodDisruptionBudget when pdb.enabled is true. */}}
{{- define "cos-common.pdb" -}}
{{- $vals := default dict .values -}}
{{- $pdb := default dict $vals.pdb -}}
{{- $componentEnabled := eq (include "cos-common.componentEnabled" (dict "values" $vals) | trim | lower) "true" -}}
{{- $render := and $componentEnabled (default false $pdb.enabled) -}}
{{- if $render }}
{{- $labels := merge (dict) (default (dict) $vals.labels) (default (dict) $pdb.labels) -}}
{{- $annotations := include "cos-common.annotations" (dict "values" $vals "resource" $pdb.annotations) | fromJson -}}
{{- $fullnameOverride := coalesce $pdb.name $pdb.fullnameOverride $vals.fullnameOverride -}}
---
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  {{- include "cos-common.metadata" (dict "root" .root "name" .name "values" (dict "fullnameOverride" $fullnameOverride "labels" $labels "annotations" $annotations)) | nindent 2 }}
spec:
  selector:
    matchLabels:
      {{- include "cos-common.selectorLabels" . | nindent 6 }}
  {{- /* Choose either minAvailable or maxUnavailable based on caller input. */}}
  {{- with $pdb.minAvailable }}
  minAvailable: {{ . }}
  {{ end }}
  {{- with $pdb.maxUnavailable }}
  maxUnavailable: {{ . }}
  {{ end }}
  {{- with $pdb.unhealthyPodEvictionPolicy }}
  unhealthyPodEvictionPolicy: {{ . }}
  {{ end }}
{{ end }}
{{ end }}
