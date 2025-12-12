{{/* ============================================================================
   Build certificate spec (prints YAML; use with fromYaml).
   Copies only supported cert-manager fields from input into a clean spec map.
   ============================================================================ */}}
{{- define "cos-common.buildCertSpec" -}}
{{- $src := .src -}}
{{- $secretName := .secretName -}}
{{- $spec := dict "secretName" $secretName -}}

{{- $fields := list
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

{{- range $field := $fields }}
  {{- with get $src $field }}
    {{- $_ := set $spec $field . }}
  {{- end }}
{{- end }}

{{- toYaml $spec -}}
{{- end }}



{{/* ============================================================================
   Render Certificate resource with the provided spec, name overrides, labels, and annotations.
   ============================================================================ */}}
{{- define "cos-common.renderCertificate" -}}
{{- $root := .root -}}
{{- $name := .name -}}
{{- $fullnameOverride := .fullnameOverride -}}
{{- $labels := default dict .labels -}}
{{- $annotations := default dict .annotations -}}
{{- $spec := default dict .spec -}}

---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
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
  {{- tpl (toYaml $spec) $root | nindent 2 }}
{{- end }}



{{/* ============================================================================
   Main + Additional Certificates (supports one primary and any number of additional entries).
   ============================================================================ */}}
{{- define "cos-common.certificate" -}}

{{- $vals := default dict .values -}}
{{- $cert := default dict $vals.certificate -}}
{{- $componentEnabled := include "cos-common.componentEnabled" (dict "values" $vals) | fromYaml -}}

{{/* ============================================================================
   Main certificate
   ============================================================================ */}}
{{- if and $componentEnabled (default false $cert.enabled) }}

  {{- if not $cert.issuerRef }}
    {{ fail (printf "component %s.certificate.issuerRef must be set when certificate.enabled=true" .name) }}
  {{- end }}

  {{- $labels := merge dict (default dict $vals.labels) (default dict $cert.labels) -}}
  {{- $annotations := include "cos-common.annotations" (dict "values" $vals "resource" $cert.annotations) | fromJson -}}

  {{- $baseName := include "cos-common.fullname" (dict "root" .root "name" .name "values" $vals) -}}
  {{- $name := default $baseName $cert.name -}}
  {{- $secretName := default $name $cert.secretName -}}

  {{- $spec := (include "cos-common.buildCertSpec"
        (dict "src" $cert "secretName" $secretName)
      ) | fromYaml
  -}}

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
  {{- $root := .root -}}
  {{- $component := .name -}}
  {{- $releaseName := include "cos-common.releaseName" (dict "root" $root) -}}
  {{- $chartName := include "cos-common.chartName" (dict "root" $root) -}}
  {{- $prefix := printf "%s-%s-%s-" $releaseName $chartName $component -}}
  {{- $items := list -}}
  {{- range $item := default list $vals.additionalCertificates }}
    {{- $items = append $items (merge (dict "name" (default $item.name $item.secretName)) $item) }}
  {{- end }}
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
