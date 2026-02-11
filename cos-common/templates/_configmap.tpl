{{/* ============================================================================
   Main ConfigMap + Additional ConfigMaps.
   - Renders a primary ConfigMap from .Values.configMap
   - Optionally renders multiple additional ConfigMaps
   - Supports templated data values (tpl=true)
   - Keeps binaryData separate from data
   ============================================================================ */}}
{{- define "cos-common.configmap" -}}

{{- /* Component values scope. */ -}}
{{- $vals := default dict .values -}}

{{- /* ConfigMap-specific configuration block. */ -}}
{{- $cfg := default dict $vals.configMap -}}

{{- /* Root chart context (required for tpl and helpers). */ -}}
{{- $root := .root -}}

{{- /* Component-level enable switch. */ -}}
{{- $componentEnabled := eq
      (include "cos-common.componentEnabled" (dict "values" $vals) | trim | lower)
      "true"
-}}

{{- /* Render main ConfigMap only when both component and feature are enabled. */ -}}
{{- $render := and $componentEnabled (default false $cfg.enabled) -}}

{{/* ============================================================================
   MAIN CONFIGMAP
   ============================================================================ */}}
{{- if $render }}

{{- /* Merge global and ConfigMap-specific labels. */ -}}
{{- $labels := merge dict (default dict $vals.labels) (default dict $cfg.labels) -}}

{{- /* Resolve annotations via common helper (supports global defaults). */ -}}
{{- $annotations := include "cos-common.annotations"
      (dict "values" $vals "resource" $cfg.annotations) | fromJson
-}}

{{- /* Name resolution priority:
      1. configMap.name
      2. configMap.fullnameOverride
      3. global fullnameOverride
*/ -}}
{{- $fullnameOverride := coalesce $cfg.name $cfg.fullnameOverride $vals.fullnameOverride -}}

{{- /* Split textual and binary payloads. */ -}}
{{- $data := default dict $cfg.data -}}
{{- $binaryData := default dict $cfg.binaryData -}}

---
apiVersion: v1
kind: ConfigMap
metadata:
  {{- /* Centralized metadata rendering (name, labels, annotations). */ -}}
  {{- include "cos-common.metadata"
      (dict "root" .root "name" .name "values"
        (dict
          "fullnameOverride" $fullnameOverride
          "labels" $labels
          "annotations" $annotations
        )
      ) | nindent 2
  }}

  {{- /* Optional ownerReferences (templated to allow dynamic values). */ -}}
  {{- with $cfg.ownerReferences }}
  ownerReferences:
    {{- tpl (toYaml .) $.root | nindent 4 }}
  {{- end }}

data:
{{- /* Empty map? Render {} explicitly to avoid Helm producing null. */ -}}
{{- if eq (len $data) 0 }}
  {}
{{- else if $cfg.tpl }}

  {{- /* tpl=true:
        - Only string values are evaluated with tpl
        - Non-string values (maps, lists) are passed through untouched
  */ -}}
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
  {{- /* tpl disabled: render data verbatim. */ -}}
{{ toYaml $data | nindent 2 }}
{{- end }}

{{- /* Render binaryData only when present. */ -}}
{{- if gt (len $binaryData) 0 }}
binaryData:
{{ toYaml $binaryData | nindent 2 }}
{{- end }}

{{- /* Immutable flag (Kubernetes ≥1.19). */ -}}
{{- with $cfg.immutable }}
immutable: {{ . }}
{{- end }}

{{- /* Ensure a trailing newline so concatenated includes remain valid YAML. */ -}}
{{- printf "\n" -}}

{{- end }}{{/* end MAIN CONFIGMAP */}}



{{/* ============================================================================
   ADDITIONAL CONFIGMAPS
   Naming rules:
   - fullnameOverride → used as-is
   - name            → <component-fullname>-<name>
   ============================================================================ */}}
{{- if $componentEnabled }}

  {{- /* Base component fullname used as prefix for additional ConfigMaps. */ -}}
  {{- $baseName := include "cos-common.fullname"
        (dict "root" $root "name" .name "values" $vals) | trim
  -}}
  {{- $namePrefix := printf "%s-" $baseName -}}

  {{- /* Delegate rendering to shared additional-resources helper. */ -}}
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
