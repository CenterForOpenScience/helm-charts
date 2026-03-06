{{/* ============================================================================
   Helper: cos-common.buildSecretData

   Responsibilities:
   - Automatically base64-encode all `.data` entries
   - Leave `.stringData` untouched (Kubernetes encodes it)
   - Optionally merge TLS cert material from `.Values.tls`
   - Support templating (tpl) inside secret values
   ============================================================================ */}}
{{- define "cos-common.buildSecretData" -}}

{{- /* Source secret definition (component or additional secret). */ -}}
{{- $src := .src -}}

{{- /* Root context (needed for tpl rendering and Values access). */ -}}
{{- $root := .root -}}

{{- /* Raw Secret fields (safe defaults). */ -}}
{{- $data := default dict $src.data -}}
{{- $stringData := default dict $src.stringData -}}

{{- /* Global TLS configuration (shared across components). */ -}}
{{- $tls := default dict $root.Values.tls -}}

{{- /* Pre-encoded entries (e.g., base64Files) can be dropped straight into data. */ -}}
{{- $encoded := dict }}
{{- with $src.base64Files }}
  {{- range $key, $value := . }}
    {{- $_ := set $encoded $key (nospace (tpl (toString $value) $root)) }}
  {{- end }}
{{- end }}

{{/* ============================================================================
   TLS MERGE
   Optionally inject TLS cert files into this Secret.

   Activated when:
   - src.includeTls == true
   - Values.tls.enabled == true

   Result:
   - Files are injected as data entries:
     certs-<app>-<filename>
   ============================================================================ */}}
{{- if and (default false $src.includeTls) (default false $tls.enabled) }}

  {{- /* Iterate over TLS entries, skipping the global "enabled" key. */ -}}
  {{- range $app, $tlsCfg := omit $tls "enabled" }}

    {{- if and $tlsCfg $tlsCfg.enabled }}

      {{- /* Plain (non-base64) files → encode here. */ -}}
      {{- with $tlsCfg.files }}
        {{- range $key, $value := . }}
          {{- $_ := set $data
                (printf "certs-%s-%s" $app $key)
                $value
          }}
        {{- end }}
      {{- end }}

      {{- /* Already-base64 files → normalize only. */ -}}
      {{- with $tlsCfg.base64Files }}
        {{- range $key, $value := . }}
          {{- $_ := set $encoded
                (printf "certs-%s-%s" $app $key)
                (nospace $value)
          }}
        {{- end }}
      {{- end }}

    {{- end }}
  {{- end }}
{{- end }}

{{/* ============================================================================
   AUTO BASE64 FOR .data

   Rules:
   - `.data` must always be base64 in rendered YAML
   - Strings are tpl-rendered first
   - Non-strings are converted to string and encoded
   - `.stringData` is NOT encoded here
   ============================================================================ */}}
{{- range $k, $v := $data }}
  {{- if kindIs "string" $v }}
    {{- /* Allow Helm templating inside secret values. */ -}}
    {{- $rendered := tpl $v $root }}
    {{- $_ := set $encoded $k (b64enc $rendered) }}
  {{- else }}
    {{- $_ := set $encoded $k (b64enc (toString $v)) }}
  {{- end }}
{{- end }}

{{/* ============================================================================
   YAML OUTPUT
   Emit only the sections that are actually populated.
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

{{- /* Component values shortcut. */ -}}
{{- $vals := default dict .values -}}

{{- /* Secret-specific values shortcut. */ -}}
{{- $sec := default dict $vals.secret -}}

{{- /* Component enablement gate. */ -}}
{{- $componentEnabled := eq
      (include "cos-common.componentEnabled" (dict "values" $vals) | trim | lower)
      "true"
-}}

{{- /* Init-certs backward compatibility support. */ -}}
{{- $initCertCfg := include "cos-common.initCertConfig"
      (dict "values" $vals) | fromYaml
-}}

{{- /*
Secret enablement logic:
- secret.enabled=true → render
- secret.enabled missing + initCert enabled → render (backward compatibility)
*/ -}}
{{- $secEnabled := or
      (default false $sec.enabled)
      (and (not (hasKey $sec "enabled")) (default false $initCertCfg.enabled))
-}}

{{- /* Final render gate. */ -}}
{{- $render := and $componentEnabled $secEnabled -}}

{{- /*
Automatically include TLS data when:
- secret.includeTls=true
- OR init-cert container is enabled
*/ -}}
{{- $_ := set $sec "includeTls"
      (or (default false $sec.includeTls) (default false $initCertCfg.enabled))
-}}

{{/* ============================================================================
   MAIN SECRET
   ============================================================================ */}}
{{- if $render }}

{{- /* Merge component-level and Secret-level labels. */ -}}
{{- $labels := merge (dict)
      (default (dict) $vals.labels)
      (default (dict) $sec.labels)
-}}

{{- /* Build annotations via shared helper. */ -}}
{{- $annotations := include "cos-common.annotations"
      (dict "values" $vals "resource" $sec.annotations) | fromJson
-}}

{{- /* Allow name override at Secret or component level. */ -}}
{{- $fullnameOverride := coalesce
      $sec.name
      $sec.fullnameOverride
      $vals.fullnameOverride
-}}

{{- /* Build data + stringData blocks via helper. */ -}}
{{- $dataBlock := include "cos-common.buildSecretData"
      (dict "src" $sec "root" .root)
-}}

---
apiVersion: v1
kind: Secret
metadata:
  {{- /* Standardized metadata rendering. */}}
  {{- include "cos-common.metadata"
      (dict
        "root" .root
        "name" .name
        "values" (dict
          "fullnameOverride" $fullnameOverride
          "labels" $labels
          "annotations" $annotations
        )
      ) | nindent 2
  }}

  {{- /* Optional ownerReferences (e.g. for cert-manager). */}}
  {{- with $sec.ownerReferences }}
  ownerReferences:
    {{- tpl (toYaml .) $.root | nindent 4 }}
  {{- end }}

type: {{ default "Opaque" $sec.type }}

{{/* Render data/stringData produced by the helper. */}}
{{ $dataBlock | nindent 0 }}

{{- /* Optional immutability flag. */}}
{{- with $sec.immutable }}
immutable: {{ . }}
{{- end }}

{{- /* Ensure a trailing newline so concatenated includes remain valid YAML. */ -}}
{{- printf "\n" -}}

{{- end }}



{{/* ============================================================================
   ADDITIONAL SECRETS

   Renders extra Secret resources defined in:
   values.additionalSecrets[]
   ============================================================================ */}}
{{- if $componentEnabled }}

{{- $root := .root -}}

{{- /* Base name for additional secret prefixes. */ -}}
{{- $baseName := include "cos-common.fullname"
      (dict "root" $root "name" .name "values" $vals)
      | trim
-}}

{{- /* Render each additional secret via generic resource renderer. */ -}}
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
