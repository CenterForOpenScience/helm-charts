{{/* Render an Ingress for the component with optional default backend and multiple host rules. */}}
{{- define "cos-common.ingress" -}}
{{- $vals := default dict .values -}}
{{- $ing := default dict $vals.ingress -}}
{{- /* Only render when the component itself and ingress feature are enabled. */ -}}
{{- $componentEnabled := include "cos-common.componentEnabled" (dict "values" $vals) | fromYaml -}}
{{- $render := and $componentEnabled (default false $ing.enabled) -}}
{{- if $render }}
{{- $labels := merge (dict) (default (dict) $vals.labels) (default (dict) $ing.labels) -}}
{{- $annotations := include "cos-common.annotations" (dict "values" $vals "resource" $ing.annotations) | fromJson -}}
{{- $fullnameOverride := coalesce $ing.name $ing.fullnameOverride $vals.fullnameOverride -}}
{{- $maintenance := default dict .root.Values.maintenance -}}
{{- $maintenanceEnabled := default false $maintenance.enabled -}}
{{- $maintenanceServiceName := include "cos-common.fullname" (dict "root" .root "name" "maintenance" "values" $maintenance) -}}
{{- $defaultServiceName := include "cos-common.fullname" (dict "root" .root "name" .name "values" $vals) -}}
{{- $serviceName := $defaultServiceName -}}
{{- /* Swap backend to the maintenance service when maintenance mode is toggled on. */ -}}
{{- if $maintenanceEnabled }}
  {{- $serviceName = coalesce $ing.serviceName $ing.backendServiceName $maintenanceServiceName }}
{{- else }}
  {{- $serviceName = coalesce $ing.serviceName $ing.backendServiceName $defaultServiceName }}
{{- end }}
{{- $defaultServicePort := $ing.servicePort -}}
{{- if $maintenanceEnabled }}
  {{- $defaultServicePort = coalesce $ing.servicePort (default nil $maintenance.service.externalPort) (default nil $maintenance.servicePort) }}
{{- end }}
{{- $defaultServicePort = coalesce $defaultServicePort $vals.http.externalPort }}
{{- $hostsInput := default (list) $ing.hosts -}}
{{- $rules := default (list) $ing.rules -}}
{{- $hosts := list -}}
{{- /* When hosts are provided as primary/secondary lists, expand each rule for the correct host set. */ -}}
{{- $rulesMode := and (kindIs "map" $hostsInput) (or (hasKey $hostsInput "primary") (hasKey $hostsInput "secondary")) (gt (len $rules) 0) -}}
{{- if $rulesMode }}
  {{- $primaryHosts := default (list) $hostsInput.primary -}}
  {{- $secondaryHosts := default (list) $hostsInput.secondary -}}
  {{- $normalizedRules := list -}}
  {{- range $ruleEntry := $rules }}
    {{- $ruleName := "" -}}
    {{- $rule := dict -}}
    {{- if and (kindIs "map" $ruleEntry) (hasKey $ruleEntry "name") }}
      {{- $ruleName = $ruleEntry.name }}
      {{- $rule = $ruleEntry }}
    {{- else if and (kindIs "map" $ruleEntry) (eq (len $ruleEntry) 1) }}
      {{- range $k, $v := $ruleEntry }}
        {{- $ruleName = $k }}
        {{- $rule = $v }}
      {{- end }}
    {{- else }}
      {{- $rule = $ruleEntry }}
      {{- $ruleName = default "" $rule.name }}
    {{- end }}
    {{- if default true $rule.enabled }}
      {{- if and $ruleName (not $rule.name) }}
        {{- $_ := set $rule "name" $ruleName }}
      {{- end }}
      {{- $normalizedRules = append $normalizedRules $rule }}
    {{- end }}
  {{- end }}
  {{- range $host := $primaryHosts }}
    {{- $paths := list }}
    {{- range $rule := $normalizedRules }}
      {{- /* includeForPrimaryHost/SecondaryHost flags let a rule target only one host group. */ -}}
      {{- $include := $rule.includeForPrimaryHost }}
      {{- if eq $include nil }}{{- $include = true }}{{- end }}
      {{- if $include }}
        {{- $rulePaths := default (list) $rule.paths }}
        {{- if not $rulePaths }}
          {{- fail (printf "component %s.ingress.rules entry requires paths" $.name) }}
        {{- end }}
        {{- $rulePathType := default "ImplementationSpecific" $rule.pathType }}
        {{- $svc := default (dict) $rule.service }}
        {{- $ruleServiceName := coalesce $rule.serviceName $svc.name $svc.serviceName }}
        {{- $ruleServicePort := coalesce $rule.servicePort $svc.port $svc.servicePort $svc.externalPort }}
        {{- range $p := $rulePaths }}
          {{- $pathVal := "" }}
          {{- $pathType := $rulePathType }}
          {{- $pathServiceName := $ruleServiceName }}
          {{- $pathPort := $ruleServicePort }}
          {{- if kindIs "map" $p }}
            {{- $pathVal = default "" $p.path }}
            {{- $pathType = default $pathType $p.pathType }}
            {{- $pathServiceName = coalesce $p.serviceName $pathServiceName }}
            {{- $pathPort = coalesce $p.port $p.servicePort $p.externalPort $pathPort }}
          {{- else }}
            {{- $pathVal = $p }}
          {{- end }}
          {{- $pathVal = default "/" $pathVal }}
          {{- $pathPort = coalesce $pathPort $defaultServicePort }}
          {{- if not $pathPort }}
            {{- fail (printf "component %s.ingress rule %s path %s requires a port" $.name (default "<unnamed>" $rule.name) $pathVal) }}
          {{- end }}
          {{- $paths = append $paths (dict "path" $pathVal "pathType" $pathType "serviceName" $pathServiceName "port" $pathPort) }}
        {{- end }}
      {{- end }}
    {{- end }}
    {{- if gt (len $paths) 0 }}
      {{- $hosts = append $hosts (dict "host" $host "paths" $paths) }}
    {{- end }}
  {{- end }}
  {{- range $host := $secondaryHosts }}
    {{- $paths := list }}
    {{- range $rule := $normalizedRules }}
      {{- $include := $rule.includeForSecondaryHost }}
      {{- if eq $include nil }}{{- $include = true }}{{- end }}
      {{- if $include }}
        {{- $rulePaths := default (list) $rule.paths }}
        {{- if not $rulePaths }}
          {{- fail (printf "component %s.ingress.rules entry requires paths" $.name) }}
        {{- end }}
        {{- $rulePathType := default "ImplementationSpecific" $rule.pathType }}
        {{- $svc := default (dict) $rule.service }}
        {{- $ruleServiceName := coalesce $rule.serviceName $svc.name $svc.serviceName }}
        {{- $ruleServicePort := coalesce $rule.servicePort $svc.port $svc.servicePort $svc.externalPort }}
        {{- range $p := $rulePaths }}
          {{- $pathVal := "" }}
          {{- $pathType := $rulePathType }}
          {{- $pathServiceName := $ruleServiceName }}
          {{- $pathPort := $ruleServicePort }}
          {{- if kindIs "map" $p }}
            {{- $pathVal = default "" $p.path }}
            {{- $pathType = default $pathType $p.pathType }}
            {{- $pathServiceName = coalesce $p.serviceName $pathServiceName }}
            {{- $pathPort = coalesce $p.port $p.servicePort $p.externalPort $pathPort }}
          {{- else }}
            {{- $pathVal = $p }}
          {{- end }}
          {{- $pathVal = default "/" $pathVal }}
          {{- $pathPort = coalesce $pathPort $defaultServicePort }}
          {{- if not $pathPort }}
            {{- fail (printf "component %s.ingress rule %s path %s requires a port" $.name (default "<unnamed>" $rule.name) $pathVal) }}
          {{- end }}
          {{- $paths = append $paths (dict "path" $pathVal "pathType" $pathType "serviceName" $pathServiceName "port" $pathPort) }}
        {{- end }}
      {{- end }}
    {{- end }}
    {{- if gt (len $paths) 0 }}
      {{- $hosts = append $hosts (dict "host" $host "paths" $paths) }}
    {{- end }}
  {{- end }}
{{- else }}
  {{- $hosts = $hostsInput }}
{{- end }}
{{- $backend := default (dict) $ing.defaultBackend -}}
{{- $hasHosts := gt (len $hosts) 0 -}}
{{- $hasBackend := gt (len $backend) 0 -}}
{{- if and (not $hasHosts) (not $hasBackend) }}
{{- fail (printf "component %s.ingress must define hosts or defaultBackend" .name) }}
{{ end }}
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  {{- include "cos-common.metadata" (dict "root" .root "name" .name "values" (dict "fullnameOverride" $fullnameOverride "labels" $labels "annotations" $annotations)) | nindent 2 }}
spec:
  {{- with $ing.ingressClassName }}
  ingressClassName: {{ . }}
  {{ end }}
  {{- if $hasBackend }}
  defaultBackend:
    {{- if $backend.service }}
    service:
      {{ tpl (toYaml $backend.service) $.root | nindent 6 }}
    {{- else }}
    service:
      name: {{ default $serviceName $backend.serviceName }}
      port:
        {{- $backendPort := coalesce $backend.port $backend.servicePort $defaultServicePort }}
        {{- if not $backendPort }}
        {{- fail (printf "component %s.ingress.defaultBackend.port is required" .name) }}
        {{ end }}
        {{ include "cos-common.renderServicePort" (dict "root" $.root "port" $backendPort) | nindent 8 }}
    {{ end }}
  {{ end }}
  {{- with $ing.tls }}
  {{- /* Pass through TLS entries as-is to let callers manage secrets and hosts. */}}
  tls:
    {{- range . }}
    - {{ tpl (toYaml .) $.root | nindent 6 }}
    {{ end }}
  {{ end }}
  {{- if $hasHosts }}
  rules:
    {{- range $host := $hosts }}
    - {{- if $host.host }}
      host: {{ tpl (toString $host.host) $.root }}
      {{ end }}
      http:
        paths:
          {{- $paths := default (list) $host.paths }}
          {{- if not $paths }}
          {{- fail (printf "component %s.ingress.hosts[].paths must be defined" $.name) }}
          {{ end }}
          {{- range $path := $paths }}
          - path: {{ default "/" $path.path }}
            pathType: {{ default "ImplementationSpecific" $path.pathType }}
            backend:
              service:
                {{- $svcName := default $serviceName $path.serviceName }}
                name: {{ tpl (toString $svcName) $.root }}
                port:
                  {{- $port := default $defaultServicePort $path.port }}
                  {{- if not $port }}
                  {{- fail (printf "component %s.ingress path requires port" $.name) }}
                  {{ end }}
                  {{ include "cos-common.renderServicePort" (dict "root" $.root "port" $port) | nindent 18 }}
          {{ end }}
    {{ end }}
  {{ end }}
{{ end }}
{{ end }}
