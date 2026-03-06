{{/* Render a Service for the component with templated ports and optional extra services. */}}

{{/*
Shared Service spec BODY renderer for main + additional services.
- Returns ONLY the fields under spec: (no "spec:" line)
- Supports headless via type: None -> clusterIP: None + type: ClusterIP
*/}}
{{- define "cos-common.serviceSpecBody" -}}
{{- $root := .root -}}
{{- $component := .component -}}
{{- $values := default dict .values -}}
{{- $svc := default dict .svc -}}

{{- /* Type (templatable) */ -}}
{{- $svcType := default "ClusterIP" $svc.type -}}
{{- if and (kindIs "string" $svcType) $root -}}
  {{- $svcType = tpl $svcType $root -}}
{{- end -}}

{{- /* Headless shortcut: allow "None" (case-insensitive) */ -}}
{{- $clusterIP := $svc.clusterIP -}}
{{- if and (kindIs "string" $svcType) (eq (lower (toString $svcType)) "none") -}}
  {{- $svcType = "ClusterIP" -}}
  {{- if not $clusterIP -}}{{- $clusterIP = "None" -}}{{- end -}}
{{- end -}}

type: {{ $svcType }}
{{- with $clusterIP }}
clusterIP: {{ . }}
{{- end }}

{{- with $svc.clusterIPs }}
clusterIPs:
  {{- range . }}
  - {{ . }}
  {{- end }}
{{- end }}

{{- with $svc.ipFamilies }}
ipFamilies:
  {{- range . }}
  - {{ . }}
  {{- end }}
{{- end }}

{{- with $svc.ipFamilyPolicy }}
ipFamilyPolicy: {{ . }}
{{- end }}

{{- with $svc.externalIPs }}
externalIPs:
  {{- range . }}
  - {{ . }}
  {{- end }}
{{- end }}

{{- with $svc.loadBalancerIP }}
loadBalancerIP: {{ . }}
{{- end }}

{{- with $svc.loadBalancerSourceRanges }}
loadBalancerSourceRanges:
  {{- range . }}
  - {{ . }}
  {{- end }}
{{- end }}

{{- with $svc.externalTrafficPolicy }}
externalTrafficPolicy: {{ . }}
{{- end }}

{{- with $svc.sessionAffinity }}
sessionAffinity: {{ . }}
{{- end }}

{{- with $svc.sessionAffinityConfig }}
sessionAffinityConfig:
  {{- tpl (toYaml .) $root | nindent 2 }}
{{- end }}

{{- with $svc.publishNotReadyAddresses }}
publishNotReadyAddresses: {{ . }}
{{- end }}

selector:
  {{- if $svc.selector }}
  {{- tpl (toYaml $svc.selector) $root | nindent 2 }}
  {{- else }}
  {{- include "cos-common.selectorLabels" (dict "root" $root "name" $component "values" $values) | nindent 2 }}
  {{- end }}

ports:
{{- $ports := default (list) $svc.ports -}}
{{- if not $ports }}
{{- fail (printf "component %s service entry requires ports" $component) }}
{{- end }}
{{- range $port := $ports }}
  {{- /* Normalize templated port fields so numbers stay numbers for k8s. */ -}}
  {{- $normalized := include "cos-common.normalizePortMap" (dict "root" $root "port" $port) | fromJson }}
  - {{ $normalized | toYaml | nindent 4 }}
{{- end }}
{{- end }}


{{/*
Render a Service resource. Used for BOTH main + additional services.
*/}}
{{- define "cos-common.serviceResource" -}}
{{- $root := .root -}}
{{- $component := .component -}}
{{- $values := default dict .values -}}
{{- $svc := default dict .svc -}}
{{- $fullnameOverride := .fullnameOverride -}}
{{- $labels := default (dict) .labels -}}
{{- $annotations := default (dict) .annotations -}}

---
apiVersion: v1
kind: Service
metadata:
  {{- include "cos-common.metadata" (dict "root" $root "name" $component "values" (dict "fullnameOverride" $fullnameOverride "labels" $labels "annotations" $annotations)) | nindent 2 }}
spec:
  {{- include "cos-common.serviceSpecBody" (dict "root" $root "component" $component "values" $values "svc" $svc) | nindent 2 }}
{{- end }}


{{/*
Main entrypoint: render main Service + additional services.
- Main service controlled by: componentEnabled && service.enabled
- Additional services controlled by: componentEnabled (and item.enabled inside renderAdditionalResources)
*/}}
{{- define "cos-common.service" -}}
{{- $vals := default dict .values -}}
{{- $root := .root -}}
{{- $name := .name -}}
{{- $svc := default dict $vals.service -}}

{{- $componentEnabled := eq (include "cos-common.componentEnabled" (dict "values" $vals) | trim | lower) "true" -}}
{{- $svcEnabled := and $componentEnabled (default false $svc.enabled) -}}

{{- if $svcEnabled }}
  {{- $labels := merge (dict) (default (dict) $vals.labels) (default (dict) $svc.labels) -}}
  {{- $annotations := include "cos-common.annotations" (dict "values" $vals "resource" $svc.annotations) | fromJson -}}
  {{- $fullnameOverride := coalesce $svc.name $svc.fullnameOverride $vals.fullnameOverride -}}

  {{- include "cos-common.serviceResource" (dict
      "root" $root
      "component" $name
      "values" $vals
      "svc" $svc
      "fullnameOverride" $fullnameOverride
      "labels" $labels
      "annotations" $annotations
    )
  }}
  {{ "\n" }}
{{- end }}

{{- if $componentEnabled }}
  {{- /* Render additionalServices[] entries when the component is enabled. */ -}}
  {{- $baseName := include "cos-common.fullname" (dict "root" $root "name" $name "values" $vals) | trim -}}
  {{- $namePrefix := printf "%s-" $baseName -}}
  {{- include "cos-common.renderAdditionalResources" (dict
      "root" $root
      "component" $name
      "values" $vals
      "items" $vals.additionalServices
      "namePrefix" $namePrefix
      "error" "additionalServices entry must have either name or fullnameOverride"
      "renderer" "cos-common.additionalServiceResource"
    )
  }}
{{- end }}
{{- end }}


{{/*
Renderer for additional Services (called by cos-common.renderAdditionalResources).
*/}}
{{- define "cos-common.additionalServiceResource" -}}
{{- $root := .root -}}
{{- $values := default dict .values -}}
{{- $item := default dict .item -}}
{{- $name := .name -}}
{{- $labels := .labels -}}
{{- $annotations := .annotations -}}

{{- include "cos-common.serviceResource" (dict
    "root" $root
    "component" .component
    "values" $values
    "svc" $item
    "fullnameOverride" $name
    "labels" $labels
    "annotations" $annotations
  )
}}
{{ "\n" }}
{{- end }}