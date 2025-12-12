{{/* ============================================================================
   Main ConfigMap + Additional ConfigMaps.
   Supports templating data (tpl=true) and keeps binaryData separate.
   ============================================================================ */}}
{{- define "cos-common.configmap" -}}

{{- $vals := default dict .values -}}
{{- $cfg := default dict $vals.configMap -}}
{{- $root := .root -}}
{{- $componentEnabled := include "cos-common.componentEnabled" (dict "values" $vals) | fromYaml -}}
{{- $render := and $componentEnabled (default false $cfg.enabled) -}}

{{/* ============================================================================
   MAIN CONFIGMAP
   ============================================================================ */}}
{{- if $render }}

{{- $labels := merge dict (default dict $vals.labels) (default dict $cfg.labels) -}}
{{- $annotations := include "cos-common.annotations" (dict "values" $vals "resource" $cfg.annotations) | fromJson -}}
{{- $fullnameOverride := coalesce $cfg.name $cfg.fullnameOverride $vals.fullnameOverride -}}
{{- $data := default dict $cfg.data -}}
{{- $binaryData := default dict $cfg.binaryData -}}

---
apiVersion: v1
kind: ConfigMap
metadata:
  {{- include "cos-common.metadata"
      (dict "root" .root "name" .name "values"
        (dict "fullnameOverride" $fullnameOverride "labels" $labels "annotations" $annotations)
      ) | nindent 2
  }}
  {{- with $cfg.ownerReferences }}
  ownerReferences:
    {{- tpl (toYaml .) $.root | nindent 4 }}
  {{- end }}

data:
{{- /* Empty map? Render {} to avoid null coercion in Helm. */ -}}
{{- if eq (len $data) 0 }}
  {}
{{- else if $cfg.tpl }}
  {{- /* tpl=true: evaluate string values against the root context. */ -}}
  {{- $renderedData := dict }}
  {{- range $key, $value := $data }}
    {{- if kindIs "string" $value }}
      {{- $_ := set $renderedData $key (tpl $value $.root) }}
    {{- else }}
      {{- $_ := set $renderedData $key $value }}
    {{- end }}
  {{- end }}
{{ toYaml $renderedData | nindent 2 }}
{{- else }}
{{ toYaml $data | nindent 2 }}
{{- end }}

{{- if gt (len $binaryData) 0 }}
binaryData:
{{ toYaml $binaryData | nindent 2 }}
{{- end }}

{{- with $cfg.immutable }}
immutable: {{ . }}
{{- end }}

{{- end }}{{/* end MAIN CONFIGMAP */}}



{{/* ============================================================================
   ADDITIONAL CONFIGMAPS
   Name rule:
   - fullnameOverride → directly use it
   - name → chartName + "-" + name
   ============================================================================ */}}
{{- if $componentEnabled }}

  {{- $baseName := include "cos-common.fullname" (dict "root" $root "name" .name "values" $vals) | trim -}}
  {{- $namePrefix := printf "%s-" $baseName -}}
  {{- include "cos-common.renderAdditionalResources" (dict
      "root" $root
      "component" .name
      "values" $vals
      "items" $vals.additionalConfigMaps
      "namePrefix" $namePrefix
      "error" "additionalConfigMaps entry must have either name or fullnameOverride"
      "renderer" "cos-common.additionalConfigMapResource"
    )
  }}

{{- end }}{{/* end componentEnabled */}}

{{- end }}{{/* end define */}}
