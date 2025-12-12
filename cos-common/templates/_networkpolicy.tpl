{{/* Render a NetworkPolicy for the component plus any additionalNetworkPolicies entries. */}}
{{- define "cos-common.networkpolicy.single" -}}
{{- $vals := default dict .values -}}
{{- $np := default dict $vals.networkPolicy -}}
{{- $componentEnabled := include "cos-common.componentEnabled" (dict "values" $vals) | fromYaml -}}
{{- $render := and $componentEnabled (default false $np.enabled) -}}
{{- if $render }}
{{- $labels := merge (dict) (default (dict) $vals.labels) (default (dict) $np.labels) -}}
{{- $annotations := include "cos-common.annotations" (dict "values" $vals "resource" $np.annotations) | fromJson -}}
{{- $fullnameOverride := coalesce $np.name $np.fullnameOverride $vals.fullnameOverride -}}
{{- /* Prefer ingressRules/egressRules if set; fall back to extra* for backward compatibility. */ -}}
{{- $ingressRules := default (list) $np.ingressRules -}}
{{- if eq (len $ingressRules) 0 }}
  {{- $ingressRules = default (list) $np.extraIngressRules }}
{{- end }}
{{- $egressRules := default (list) $np.egressRules -}}
{{- if eq (len $egressRules) 0 }}
  {{- $egressRules = default (list) $np.extraEgressRules }}
{{- end }}
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  {{- include "cos-common.metadata" (dict "root" .root "name" .name "values" (dict "fullnameOverride" $fullnameOverride "labels" $labels "annotations" $annotations)) | nindent 2 }}
spec:
  podSelector:
    {{- if $np.podSelector }}
    {{- tpl (toYaml $np.podSelector) $.root | nindent 4 }}
    {{- else }}
    {{- $selector := include "cos-common.selectorLabels" . | fromYaml }}
    {{- /* componentScoped=false: drop component label so one policy can cover all components. */ -}}
    {{- $componentScoped := true }}
    {{- if hasKey $np "componentScoped" }}
      {{- $componentScoped = $np.componentScoped }}
    {{- end }}
    {{- $componentScoped = toString $componentScoped }}
    {{- if eq $componentScoped "false" }}
      {{- $_ := unset $selector "app.kubernetes.io/component" }}
    {{- end }}
    matchLabels:
      {{- toYaml $selector | nindent 6 }}
    {{- end }}
  policyTypes:
    - Ingress
    {{- if or (default false $np.allowEgress) (gt (len $egressRules) 0) }}
    - Egress
    {{ end }}
  ingress:
    {{- if gt (len $ingressRules) 0 }}
    {{- /* Normalize each ingress rule and any port maps inside it. */ -}}
    {{- range $rule := $ingressRules }}
      {{- $rendered := tpl (toYaml $rule) $.root | fromYaml }}
      {{- if hasKey $rendered "ports" }}
        {{- $ports := list }}
        {{- range $rendered.ports }}
          {{- $ports = append $ports (include "cos-common.normalizePortMap" (dict "root" $.root "port" .) | fromJson) }}
        {{- end }}
        {{- $_ := set $rendered "ports" $ports }}
      {{- end }}
    - {{ $rendered | toYaml | nindent 6 }}
    {{ end }}
    {{- else }}
    {{- /* Default rule: allow traffic from the release namespace if no rules provided. */}}
    - from:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: {{ .root.Release.Namespace }}
    {{ end }}
  {{- if or (default false $np.allowEgress) (gt (len $egressRules) 0) }}
  egress:
    {{- if gt (len $egressRules) 0 }}
    {{- range $rule := $egressRules }}
      {{- $rendered := tpl (toYaml $rule) $.root | fromYaml }}
      {{- if hasKey $rendered "ports" }}
        {{- $ports := list }}
        {{- range $rendered.ports }}
          {{- $ports = append $ports (include "cos-common.normalizePortMap" (dict "root" $.root "port" .) | fromJson) }}
        {{- end }}
        {{- $_ := set $rendered "ports" $ports }}
      {{- end }}
    - {{ $rendered | toYaml | nindent 6 }}
    {{ end }}
    {{ end }}
    {{- if default false $np.allowEgress }}
    - {}
    {{ end }}
  {{ end }}
{{ end }}
{{ end }}

{{- define "cos-common.networkpolicy" -}}
{{- $vals := default dict .values -}}
{{- $root := .root -}}
{{- $name := .name -}}
{{- include "cos-common.networkpolicy.single" . }}
{{- $additional := default list $vals.additionalNetworkPolicies -}}
{{- $componentEnabled := include "cos-common.componentEnabled" (dict "values" $vals) | fromYaml -}}
{{- if $componentEnabled }}
  {{- $releaseName := include "cos-common.releaseName" (dict "root" $root) -}}
  {{- $componentName := include "cos-common.componentName" (dict "root" $root "name" $name) -}}
  {{- include "cos-common.renderAdditionalResources" (dict
      "root" $root
      "component" $name
      "values" $vals
      "items" $additional
      "namePrefix" (printf "%s-%s-" $releaseName $componentName)
      "error" (printf "component %s.additionalNetworkPolicies entry requires name" $name)
      "renderer" "cos-common.additionalNetworkPolicyResource"
    )
  }}
{{- end }}
{{ end }}
