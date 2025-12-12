{{/* Render a Service for the component with templated ports and optional extra services. */}}
{{- define "cos-common.service" -}}
{{- $vals := default dict .values -}}
{{- $svc := default dict $vals.service -}}
{{- $componentEnabled := include "cos-common.componentEnabled" (dict "values" $vals) | fromYaml -}}
{{- $svcEnabled := and $componentEnabled (default true $svc.enabled) -}}
{{- if $svcEnabled }}
{{- $labels := merge (dict) (default (dict) $vals.labels) (default (dict) $svc.labels) -}}
{{- $annotations := include "cos-common.annotations" (dict "values" $vals "resource" $svc.annotations) | fromJson -}}
{{- $fullnameOverride := coalesce $svc.name $svc.fullnameOverride $vals.fullnameOverride -}}
---
apiVersion: v1
kind: Service
metadata:
  {{- include "cos-common.metadata" (dict "root" .root "name" .name "values" (dict "fullnameOverride" $fullnameOverride "labels" $labels "annotations" $annotations)) | nindent 2 }}
spec:
  {{- $svcType := default "ClusterIP" $svc.type -}}
  {{- /* Allow templated service type (e.g., switch to LoadBalancer per env). */ -}}
  {{- if and (kindIs "string" $svcType) $.root }}{{- $svcType = tpl $svcType $.root -}}{{- end }}
  type: {{ $svcType }}
  {{- with $svc.clusterIP }}
  clusterIP: {{ . }}
  {{ end }}
  {{- with $svc.clusterIPs }}
  clusterIPs:
    {{- range . }}
    - {{ . }}
    {{ end }}
  {{ end }}
  {{- with $svc.ipFamilies }}
  ipFamilies:
    {{- range . }}
    - {{ . }}
    {{ end }}
  {{ end }}
  {{- with $svc.ipFamilyPolicy }}
  ipFamilyPolicy: {{ . }}
  {{ end }}
  {{- with $svc.externalIPs }}
  externalIPs:
    {{- range . }}
    - {{ . }}
    {{ end }}
  {{ end }}
  {{- with $svc.loadBalancerIP }}
  loadBalancerIP: {{ . }}
  {{ end }}
  {{- with $svc.loadBalancerSourceRanges }}
  loadBalancerSourceRanges:
    {{- range . }}
    - {{ . }}
    {{ end }}
  {{ end }}
  {{- with $svc.externalTrafficPolicy }}
  externalTrafficPolicy: {{ . }}
  {{ end }}
  {{- with $svc.sessionAffinity }}
  sessionAffinity: {{ . }}
  {{ end }}
  {{- with $svc.sessionAffinityConfig }}
  sessionAffinityConfig:
    {{- tpl (toYaml .) $.root | nindent 4 }}
  {{ end }}
  {{- with $svc.publishNotReadyAddresses }}
  publishNotReadyAddresses: {{ . }}
  {{ end }}
  selector:
    {{- include "cos-common.selectorLabels" . | nindent 4 }}
  ports:
  {{- $ports := default (list) $svc.ports }}
  {{- if not $ports }}
  {{- fail (printf "component %s.service.ports must be defined" .name) }}
  {{ end }}
  {{- range $port := $ports }}
    {{- /* Normalize templated port fields so numbers stay numbers for k8s. */ -}}
    {{- $normalized := include "cos-common.normalizePortMap" (dict "root" $.root "port" $port) | fromJson }}
    - {{ $normalized | toYaml | nindent 6 }}
  {{ end }}
{{ end }}
{{ end }}
