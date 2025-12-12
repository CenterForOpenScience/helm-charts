{{/* ============================================================================
   Helper: cos-common.buildSecretData
   Adds automatic base64 encoding for all .data values and merges in TLS cert files when requested.
   ============================================================================ */}}
{{- define "cos-common.buildSecretData" -}}
{{- $src := .src -}}
{{- $root := .root -}}

{{- $data := default dict $src.data -}}
{{- $stringData := default dict $src.stringData -}}

{{- $tls := default dict $root.Values.tls -}}

{{/* TLS merge: optionally pull in files/base64Files from tls.* into this Secret. */}}
{{- if and (default false $src.includeTls) (default false $tls.enabled) }}
  {{- range $app, $tlsCfg := omit $tls "enabled" }}
    {{- if and $tlsCfg $tlsCfg.enabled }}
      {{- with $tlsCfg.files }}
        {{- range $key, $value := . }}
          {{- $_ := set $data (printf "certs-%s-%s" $app $key) (b64enc $value) }}
        {{- end }}
      {{- end }}
      {{- with $tlsCfg.base64Files }}
        {{- range $key, $value := . }}
          {{- $_ := set $data (printf "certs-%s-%s" $app $key) (nospace $value) }}
        {{- end }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}

{{/* ============================================================================
   AUTO BASE64 FOR .data (stringData is left as-is for K8s to encode)
   ============================================================================ */}}
{{- $encoded := dict }}
{{- range $k, $v := $data }}
  {{- if kindIs "string" $v }}
    {{- $rendered := tpl $v $root }}
    {{- $_ := set $encoded $k (b64enc $rendered) }}
  {{- else }}
    {{- $_ := set $encoded $k (b64enc (toString $v)) }}
  {{- end }}
{{- end }}

{{/* ============================================================================
   YAML OUTPUT
   ============================================================================ */}}
{{- if gt (len $encoded) 0 }}
data:
{{ toYaml $encoded | nindent 2 }}
{{- end }}

{{- if gt (len $stringData) 0 }}
stringData:
{{ tpl (toYaml $stringData) $root | nindent 2 }}
{{- end }}

{{- end }}



{{/* ============================================================================
   Main Secret + Additional Secrets
   ============================================================================ */}}
{{- define "cos-common.secret" -}}

{{- $vals := default dict .values -}}
{{- $sec := default dict $vals.secret -}}
{{- $componentEnabled := include "cos-common.componentEnabled" (dict "values" $vals) | fromYaml -}}
{{- $initCertCfg := include "cos-common.initCertConfig" (dict "values" $vals) | fromYaml -}}
{{- $secEnabled := or (default false $sec.enabled) (and (not (hasKey $sec "enabled")) (default false $initCertCfg.enabled)) -}}
{{- $render := and $componentEnabled $secEnabled -}}
{{- $_ := set $sec "includeTls" (or (default false $sec.includeTls) (default false $initCertCfg.enabled)) -}}

{{/* ============================================================================
   MAIN SECRET
   ============================================================================ */}}
{{- if $render }}

{{- $labels := merge (dict) (default (dict) $vals.labels) (default (dict) $sec.labels) -}}
{{- $annotations := include "cos-common.annotations" (dict "values" $vals "resource" $sec.annotations) | fromJson -}}
{{- $fullnameOverride := coalesce $sec.name $sec.fullnameOverride $vals.fullnameOverride -}}

{{- $dataBlock := include "cos-common.buildSecretData" (dict "src" $sec "root" .root) }}

---
apiVersion: v1
kind: Secret
metadata:
  {{- include "cos-common.metadata"
      (dict "root" .root "name" .name "values"
        (dict "fullnameOverride" $fullnameOverride "labels" $labels "annotations" $annotations)
      ) | nindent 2
  }}
  {{- with $sec.ownerReferences }}
  ownerReferences:
    {{- tpl (toYaml .) $.root | nindent 4 }}
  {{- end }}
type: {{ default "Opaque" $sec.type }}
{{ $dataBlock | nindent 0 }}
{{- with $sec.immutable }}
immutable: {{ . }}
{{- end }}

{{- end }}



{{/* ============================================================================
   ADDITIONAL SECRETS
   ============================================================================ */}}
{{- if $componentEnabled }}

{{- $root := .root -}}
{{- $baseName := include "cos-common.fullname" (dict "root" $root "name" .name "values" $vals) | trim -}}

{{- include "cos-common.renderAdditionalResources" (dict
    "root" $root
    "component" .name
    "values" $vals
    "items" $vals.additionalSecrets
    "namePrefix" (printf "%s-" $baseName)
    "error" "additionalSecrets entry must have either name or fullnameOverride"
    "renderer" "cos-common.additionalSecretResource"
  )
}}

{{- end }}

{{- end }}
