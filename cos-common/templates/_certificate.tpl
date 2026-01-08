{{/* ============================================================================
   Build certificate spec (prints YAML; use with fromYaml).
   Copies only supported cert-manager fields from input into a clean spec map.
   ============================================================================ */}}
{{- define "cos-common.buildCertSpec" -}}

{{- /* Source certificate values (usually .Values.certificate or an additional entry). */ -}}
{{- $src := .src -}}

{{- /* Name of the Secret where cert-manager will store the certificate. */ -}}
{{- $secretName := .secretName -}}

{{- /* Root context is required for fullname helpers and tpl rendering. */ -}}
{{- $root := .root -}}

{{- /* Component values (used only for fullname fallback when needed). */ -}}
{{- $values := default dict .values -}}

{{- /* Initialize spec with mandatory secretName. */ -}}
{{- $spec := dict "secretName" $secretName -}}

{{- /* Allow-list of cert-manager Certificate.spec fields we intentionally support.
      This prevents leaking unsupported or accidental values into the spec. */ -}}
{{- $fields := list
    "acme"
    "commonName"
    "dnsNames"
    "ipAddresses"
    "uris"
    "emailAddresses"
    "issuerRef"
    "duration"
    "renewBefore"
    "usages"
    "privateKey"
    "subject"
    "secretTemplate"
-}}

{{- /* Copy only allowed fields from source into the resulting spec. */ -}}
{{- range $field := $fields }}
  {{- with get $src $field }}
    {{- $_ := set $spec $field . }}
  {{- end }}
{{- end }}

{{- /* --------------------------------------------------------------------------
      Backward-compatibility:
      Support legacy certificate.acmeConfig by translating it into
      spec.acme.config[] (cert-manager v1 format).
      -------------------------------------------------------------------------- */ -}}
{{- if and (not (hasKey $spec "acme")) -}}
  {{- with (get $src "acmeConfig") -}}

  {{- /* Normalize legacy structure. */ -}}
  {{- $acmeCfg := default dict . -}}
  {{- $http01 := default dict (get $acmeCfg "http01") -}}
  {{- $domains := default list (get $acmeCfg "domains") -}}

  {{- /* Render ACME only if at least one meaningful config exists. */ -}}
  {{- $shouldAddAcme := or (gt (len $domains) 0) (gt (len $http01) 0) -}}
  {{- if $shouldAddAcme -}}

  {{- /* Render http01 block defensively to avoid mutating input. */ -}}
  {{- $http01Rendered := dict -}}
  {{- if gt (len $http01) 0 -}}
    {{- $http01Rendered = merge (dict) $http01 -}}
  {{- end -}}

  {{- /* Default ingress name if not explicitly provided. */ -}}
  {{- if not (hasKey $http01Rendered "ingress") -}}
    {{- if not $root }}
      {{- fail "cos-common.buildCertSpec requires root when certificate.acmeConfig.http01.ingress is not set" -}}
    {{- end }}
    {{- $_ := set $http01Rendered "ingress"
          ((include "cos-common.fullname" (dict "root" $root "name" "" "values" $values)) | trim)
    -}}
  {{- end -}}

    {{- /* Inject translated ACME config into final spec. */ -}}
    {{- $_ := set $spec "acme"
          (dict "config" (list (dict "http01" $http01Rendered "domains" $domains)))
    -}}
  {{- end -}}
  {{- end -}}
{{- end -}}

{{- /* Emit YAML so caller can safely pipe through fromYaml. */ -}}
{{- toYaml $spec -}}
{{- end }}



{{/* ============================================================================
   Render Certificate resource with the provided spec, name overrides, labels,
   and annotations.
   ============================================================================ */}}
{{- define "cos-common.renderCertificate" -}}

{{- /* Root chart context. */ -}}
{{- $root := .root -}}

{{- /* Logical component name (used for metadata helpers). */ -}}
{{- $name := .name -}}

{{- /* Optional fullname override for this Certificate. */ -}}
{{- $fullnameOverride := .fullnameOverride -}}

{{- /* Final labels and annotations (already merged upstream). */ -}}
{{- $labels := default dict .labels -}}
{{- $annotations := default dict .annotations -}}

{{- /* Pre-built Certificate.spec map. */ -}}
{{- $spec := default dict .spec -}}

---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  {{- /* Centralized metadata rendering (name, labels, annotations). */ -}}
  {{- include "cos-common.metadata"
      (dict
        "root" $root
        "name" $name
        "values" (dict
          "fullnameOverride" $fullnameOverride
          "labels" $labels
          "annotations" $annotations
        )
      ) | nindent 2
  }}
spec:
  {{- /* tpl allows values inside spec (e.g. {{ .Release.Namespace }}). */ -}}
  {{- tpl (toYaml $spec) $root | nindent 2 }}
{{- print "\n" -}}
{{- end }}



{{/* ============================================================================
   Main + Additional Certificates
   Supports:
   - One primary certificate (.Values.certificate)
   - Any number of additional certificates (.Values.additionalCertificates)
   ============================================================================ */}}
{{- define "cos-common.certificate" -}}

{{- $vals := default dict .values -}}
{{- $cert := default dict $vals.certificate -}}

{{- /* Component-level enable switch. */ -}}
{{- $componentEnabled := include "cos-common.componentEnabled" (dict "values" $vals) | fromYaml -}}

{{/* ============================================================================
   Main certificate
   ============================================================================ */}}
{{- if and $componentEnabled (default false $cert.enabled) }}

  {{- /* issuerRef is mandatory for cert-manager Certificates. */ -}}
  {{- if not $cert.issuerRef }}
    {{ fail (printf "component %s.certificate.issuerRef must be set when certificate.enabled=true" .name) }}
  {{- end }}

  {{- /* Merge global and certificate-specific labels. */ -}}
  {{- $labels := merge dict (default dict $vals.labels) (default dict $cert.labels) -}}

  {{- /* Resolve annotations via common helper (supports global defaults). */ -}}
  {{- $annotations := include "cos-common.annotations"
        (dict "values" $vals "resource" $cert.annotations) | fromJson
  -}}

  {{- /* Base name derived from component fullname. */ -}}
  {{- $baseName := include "cos-common.fullname"
        (dict "root" .root "name" .name "values" $vals)
  -}}

  {{- /* Allow explicit Certificate name override. */ -}}
  {{- $name := default $baseName $cert.name -}}

  {{- /* Secret defaults to certificate name unless overridden. */ -}}
  {{- $secretName := default $name $cert.secretName -}}

  {{- /* Build and normalize Certificate.spec. */ -}}
  {{- $spec := (include "cos-common.buildCertSpec"
        (dict "src" $cert "secretName" $secretName "root" .root "values" $vals)
      ) | fromYaml
  -}}

  {{- /* Render primary Certificate resource. */ -}}
  {{- include "cos-common.renderCertificate" (dict
      "root" .root
      "name" .name
      "fullnameOverride" (coalesce $cert.fullnameOverride $vals.fullnameOverride $name)
      "labels" $labels
      "annotations" $annotations
      "spec" $spec
  ) }}
{{- end }}



{{/* ============================================================================
   Additional certificates
   ============================================================================ */}}
{{- if $componentEnabled }}

  {{- /* Context helpers for consistent naming. */ -}}
  {{- $root := .root -}}
  {{- $component := .name -}}
  {{- $releaseName := include "cos-common.releaseName" (dict "root" $root) -}}
  {{- $chartName := include "cos-common.chartName" (dict "root" $root) -}}

  {{- /* Prefix ensures unique names across components. */ -}}
  {{- $prefix := printf "%s-%s-%s-" $releaseName $chartName $component -}}

  {{- /* Normalize additional certificate entries to always have a name. */ -}}
  {{- $items := list -}}
  {{- range $item := default list $vals.additionalCertificates }}
    {{- $itemName := default $item.secretName $item.name -}}
    {{- $items = append $items (merge $item (dict "name" $itemName)) }}
  {{- end }}

  {{- /* Render via shared additional-resources helper. */ -}}
  {{- include "cos-common.renderAdditionalResources" (dict
      "root" $root
      "component" $component
      "values" $vals
      "items" $items
      "namePrefix" $prefix
      "error" (printf "component %s.additionalCertificates entry requires name or secretName" $component)
      "renderer" "cos-common.additionalCertificateResource"
    )
  }}
{{- end }}

{{- end }}
