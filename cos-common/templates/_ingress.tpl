{{/*
Render an Ingress for a component.
This helper intentionally supports many input shapes to keep values.yaml flexible
and backward-compatible across services.
*/}}
{{- define "cos-common.ingress" -}}

{{- /* Normalize component values and ingress subtree to always be maps */ -}}
{{- $vals := default dict .values -}}
{{- $ing := default dict $vals.ingress -}}

{{- /* Render ingress only if:
      1) the component itself is enabled
      2) ingress feature is explicitly enabled */ -}}
{{- $componentEnabled := eq (include "cos-common.componentEnabled" (dict "values" $vals) | trim | lower) "true" -}}
{{- $render := and $componentEnabled (default false $ing.enabled) -}}
{{- if $render }}

{{- /* Merge base component labels with ingress-specific labels */ -}}
{{- $labels := merge (dict) (default (dict) $vals.labels) (default (dict) $ing.labels) -}}

{{- /* Resolve annotations via shared annotation helper
      (supports global + resource-specific annotations) */ -}}
{{- $annotations := include "cos-common.annotations" (dict "values" $vals "resource" $ing.annotations) | fromJson -}}

{{- /* Optional fullname override coming from ingress or component */ -}}
{{- $fullnameOverride := coalesce $ing.name $ing.fullnameOverride $vals.fullnameOverride -}}

{{- /* Maintenance configuration is global and lives at root.Values */ -}}
{{- $maintenance := default dict .root.Values.maintenance -}}
{{- $maintenanceEnabled := default false $maintenance.enabled -}}

{{- /* Resolve service names:
      - default component service
      - maintenance service (when enabled) */ -}}
{{- $maintenanceService := default (dict) $maintenance.service -}}
{{- $maintenanceServiceName := coalesce $maintenanceService.name (include "cos-common.fullname" (dict "root" .root "name" "maintenance" "values" $maintenance)) -}}
{{- $defaultServiceName := include "cos-common.fullname" (dict "root" .root "name" .name "values" $vals) -}}

{{- /* Select backend service name depending on maintenance mode */ -}}
{{- $serviceName := $defaultServiceName -}}
{{- if $maintenanceEnabled }}
  {{- $serviceName = coalesce $ing.serviceName $ing.backendServiceName $maintenanceServiceName }}
{{- else }}
  {{- $serviceName = coalesce $ing.serviceName $ing.backendServiceName $defaultServiceName }}
{{- end }}

{{- /* Resolve backend service port.
      Maintenance mode may override the port as well. */ -}}
{{- $defaultServicePort := $ing.servicePort -}}
{{- if $maintenanceEnabled }}
  {{- $defaultServicePort = coalesce
        $ing.servicePort
        (default nil $maintenance.service.externalPort)
        (default nil $maintenance.servicePort)
  }}
{{- end }}
{{- $defaultServicePort = coalesce $defaultServicePort $vals.http.externalPort }}

{{- /* Hosts and rules input normalization */ -}}
{{- $hostsInput := default (list) $ing.hosts -}}
{{- $rules := default (list) $ing.rules -}}
{{- $hosts := list -}}

{{- /*
Determine whether we are in "rules mode":
- hosts defined as a map with primary/additional keys
- rules list exists and defines paths/services
*/ -}}
{{- $rulesMode := and
      (kindIs "map" $hostsInput)
      (or (hasKey $hostsInput "primary") (hasKey $hostsInput "additional"))
      (gt (len $rules) 0)
-}}

{{- if $rulesMode }}

  {{- /* Split hosts into primary and additional groups */ -}}
  {{- $primaryHosts := default (list) $hostsInput.primary -}}
  {{- $additionalHosts := default (list) $hostsInput.additional -}}

  {{- /* Normalize rule entries to a consistent structure:
        - supports named rules
        - supports map shorthand
        - filters out disabled rules */ -}}
  {{- $normalizedRules := list -}}
  {{- range $ruleEntry := $rules }}
    {{- $ruleName := "" -}}
    {{- $rule := dict -}}

    {{- /* Support multiple rule declaration styles */ -}}
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

    {{- /* Only include enabled rules */ -}}
    {{- if default true $rule.enabled }}
      {{- if and $ruleName (not $rule.name) }}
        {{- $_ := set $rule "name" $ruleName }}
      {{- end }}
      {{- $normalizedRules = append $normalizedRules $rule }}
    {{- end }}
  {{- end }}

  {{- /* Expand rules for PRIMARY hosts */ -}}
  {{- range $host := $primaryHosts }}
    {{- $paths := list }}

    {{- range $rule := $normalizedRules }}
      {{- /* Rules may explicitly opt out of primary hosts */ -}}
      {{- $include := $rule.includeForPrimaryHost }}
      {{- if eq $include nil }}{{- $include = true }}{{- end }}

      {{- if $include }}
        {{- /* Validate rule paths */ -}}
        {{- $rulePaths := default (list) $rule.paths -}}
        {{- if not $rulePaths }}
          {{- fail (printf "component %s.ingress.rules entry requires paths" $.name) }}
        {{- end }}

        {{- /* Resolve rule-level defaults */ -}}
        {{- $rulePathType := default "ImplementationSpecific" $rule.pathType }}
        {{- $svc := default (dict) $rule.service }}
        {{- $ruleServiceName := $serviceName }}
        {{- $ruleServicePort := $defaultServicePort }}

        {{- /* Rule-level overrides disabled during maintenance */ -}}
        {{- if not $maintenanceEnabled }}
          {{- $ruleServiceName = coalesce $rule.serviceName $svc.name $svc.serviceName $ruleServiceName }}
          {{- $ruleServicePort = coalesce $rule.servicePort $svc.port $svc.servicePort $svc.externalPort $ruleServicePort }}
        {{- end }}

        {{- /* Expand individual paths */ -}}
        {{- range $p := $rulePaths }}
          {{- $pathVal := "" -}}
          {{- $pathType := $rulePathType -}}
          {{- $pathServiceName := $ruleServiceName -}}
          {{- $pathPort := $ruleServicePort -}}

          {{- /* Path can be string or map */ -}}
          {{- if kindIs "map" $p }}
            {{- $pathVal = default "" $p.path }}
            {{- $pathType = default $pathType $p.pathType }}
            {{- if not $maintenanceEnabled }}
              {{- $pathServiceName = coalesce $p.serviceName $pathServiceName }}
              {{- $pathPort = coalesce $p.port $p.servicePort $p.externalPort $pathPort }}
            {{- end }}
          {{- else }}
            {{- $pathVal = $p }}
          {{- end }}

          {{- $pathVal = default "/" $pathVal }}
          {{- $pathPort = coalesce $pathPort $defaultServicePort }}

          {{- if not $pathPort }}
            {{- fail (printf "component %s.ingress rule %s path %s requires a port" $.name (default "<unnamed>" $rule.name) $pathVal) }}
          {{- end }}

          {{- $paths = append $paths (dict
                "path" $pathVal
                "pathType" $pathType
                "serviceName" $pathServiceName
                "port" $pathPort
          ) }}
        {{- end }}
      {{- end }}
    {{- end }}

    {{- /* Only emit host entry if at least one path was produced */ -}}
    {{- if gt (len $paths) 0 }}
      {{- $hosts = append $hosts (dict "host" $host "paths" $paths) }}
    {{- end }}
  {{- end }}

  {{- /* Repeat the same expansion logic for ADDITIONAL hosts */ -}}
  {{- /* (logic intentionally duplicated for clarity and isolation) */ -}}
  {{- range $host := $additionalHosts }}
    {{- $paths := list }}

    {{- range $rule := $normalizedRules }}
      {{- /* Rules may explicitly opt out of additional hosts */ -}}
      {{- $include := $rule.includeForAdditionalHost }}
      {{- if eq $include nil }}{{- $include = false }}{{- end }}

      {{- if $include }}
        {{- /* Validate rule paths */ -}}
        {{- $rulePaths := default (list) $rule.paths -}}
        {{- if not $rulePaths }}
          {{- fail (printf "component %s.ingress.rules entry requires paths" $.name) }}
        {{- end }}

        {{- /* Resolve rule-level defaults */ -}}
        {{- $rulePathType := default "ImplementationSpecific" $rule.pathType }}
        {{- $svc := default (dict) $rule.service }}
        {{- $ruleServiceName := $serviceName }}
        {{- $ruleServicePort := $defaultServicePort }}

        {{- /* Rule-level overrides disabled during maintenance */ -}}
        {{- if not $maintenanceEnabled }}
          {{- $ruleServiceName = coalesce $rule.serviceName $svc.name $svc.serviceName $ruleServiceName }}
          {{- $ruleServicePort = coalesce $rule.servicePort $svc.port $svc.servicePort $svc.externalPort $ruleServicePort }}
        {{- end }}

        {{- /* Expand individual paths */ -}}
        {{- range $p := $rulePaths }}
          {{- $pathVal := "" -}}
          {{- $pathType := $rulePathType -}}
          {{- $pathServiceName := $ruleServiceName -}}
          {{- $pathPort := $ruleServicePort -}}

          {{- /* Path can be string or map */ -}}
          {{- if kindIs "map" $p }}
            {{- $pathVal = default "" $p.path }}
            {{- $pathType = default $pathType $p.pathType }}
            {{- if not $maintenanceEnabled }}
              {{- $pathServiceName = coalesce $p.serviceName $pathServiceName }}
              {{- $pathPort = coalesce $p.port $p.servicePort $p.externalPort $pathPort }}
            {{- end }}
          {{- else }}
            {{- $pathVal = $p }}
          {{- end }}

          {{- $pathVal = default "/" $pathVal }}
          {{- $pathPort = coalesce $pathPort $defaultServicePort }}

          {{- if not $pathPort }}
            {{- fail (printf "component %s.ingress rule %s path %s requires a port" $.name (default "<unnamed>" $rule.name) $pathVal) }}
          {{- end }}

          {{- $paths = append $paths (dict
                "path" $pathVal
                "pathType" $pathType
                "serviceName" $pathServiceName
                "port" $pathPort
          ) }}
        {{- end }}
      {{- end }}
    {{- end }}

    {{- /* Only emit host entry if at least one path was produced */ -}}
    {{- if gt (len $paths) 0 }}
      {{- $hosts = append $hosts (dict "host" $host "paths" $paths) }}
    {{- end }}
  {{- end }}

{{- else }}

  {{- /* Simple mode: hosts are already fully defined */ -}}
  {{- $hosts = $hostsInput }}

{{- end }}

{{- /* Validate that ingress has something to route */ -}}
{{- $backend := default (dict) $ing.defaultBackend -}}
{{- $hasHosts := gt (len $hosts) 0 -}}
{{- $hasBackend := gt (len $backend) 0 -}}

{{- if and (not $hasHosts) (not $hasBackend) }}
  {{- fail (printf "component %s.ingress must define hosts or defaultBackend" .name) }}
{{- end }}

---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  {{- include "cos-common.metadata" (dict
        "root" .root
        "name" .name
        "values" (dict
          "fullnameOverride" $fullnameOverride
          "labels" $labels
          "annotations" $annotations
        )
  ) | nindent 2 }}

spec:
  {{- /* Optional ingress class */ -}}
  {{- with $ing.ingressClassName }}
  ingressClassName: {{ . }}
  {{- end }}

  {{- /* Optional default backend */ -}}
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
        {{- end }}
        {{ include "cos-common.renderServicePort" (dict "root" $.root "port" $backendPort) | nindent 8 }}
    {{- end }}
  {{- end }}

  {{- /* TLS entries are passed through without modification */ -}}
  {{- with $ing.tls }}
  tls:
    {{- range . }}
    - {{ tpl (toYaml .) $.root | nindent 6 }}
    {{- end }}
  {{- end }}

  {{- /* Host rules */ -}}
  {{- if $hasHosts }}
  rules:
    {{- range $host := $hosts }}
    - {{- if $host.host }}
      host: {{ tpl (toString $host.host) $.root }}
      {{- end }}
      http:
        paths:
          {{- range $path := default (list) $host.paths }}
          - path: {{ default "/" $path.path }}
            pathType: {{ default "ImplementationSpecific" $path.pathType }}
            backend:
              service:
                name: {{ tpl (toString (default $serviceName $path.serviceName)) $.root }}
                port:
                  {{ include "cos-common.renderServicePort" (dict "root" $.root "port" (default $defaultServicePort $path.port)) | nindent 18 }}
          {{- end }}
    {{- end }}
  {{- end }}

{{- end }}
{{- end }}
