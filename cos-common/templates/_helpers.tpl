{{/*
Common helpers for the cos-common library chart.
*/}}

{{/*
Return true when the component values exist and are enabled.
*/}}
{{- define "cos-common.componentEnabled" -}}
{{- $vals := .values -}}
{{- if and $vals (ne (default true $vals.enabled) false) -}}
true
{{- else -}}
false
{{- end }}
{{- end }}

{{/*
Parse init-certs config (supports boolean for backward compatibility).
*/}}
{{- define "cos-common.initCertConfig" -}}
{{- $vals := default dict .values -}}
{{- $cfg := default (dict) $vals.enabledInitContainersCertificate -}}
{{- if kindIs "bool" $vals.enabledInitContainersCertificate }}
  {{- $cfg = dict "enabled" $vals.enabledInitContainersCertificate -}}
{{- end }}
{{- $enabled := default false $cfg.enabled -}}
{{- $mount := $cfg.mountToContainer -}}
{{- $owner := default "www-data:www-data" $cfg.userCertsOwner -}}
{{- toYaml (dict "enabled" $enabled "mountToContainer" $mount "userCertsOwner" $owner) -}}
{{- end }}

{{/*
Return TLS configs when global TLS is enabled and the component secret opts in.
*/}}
{{- define "cos-common.enabledInitContainersCertificate" -}}
{{- $vals := default dict .values -}}
{{- $sec := default dict $vals.secret -}}
{{- $tls := default dict .root.Values.tls -}}
{{- $componentEnabled := and $vals (ne (default true $vals.enabled) false) -}}
{{- $initCfg := include "cos-common.initCertConfig" (dict "values" $vals) | fromYaml -}}
{{- $includeTls := or (default false $sec.includeTls) (default false $initCfg.enabled) -}}
{{- /* Allow TLS init/volumes even when main.secret.enabled=false (for externally-managed secrets). */ -}}
{{- if and $componentEnabled (default false $tls.enabled) $includeTls -}}
  {{- $enabled := dict -}}
  {{- /* Collect only tls.* entries explicitly enabled so we can mount them. */ -}}
  {{- range $app, $cfg := omit $tls "enabled" }}
    {{- $isMap := kindIs "map" $cfg }}
    {{- if and $cfg $isMap (default false (index $cfg "enabled")) }}
      {{- $_ := set $enabled $app (merge $cfg (dict "mountToContainer" $initCfg.mountToContainer "userCertsOwner" $initCfg.userCertsOwner)) }}
    {{- end }}
  {{- end }}
  {{- if gt (len $enabled) 0 }}
{{ toYaml $enabled }}
  {{- end }}
{{- end }}
{{- end }}

{{/*
Trim any name to <=63 characters and remove trailing hyphen.
*/}}
{{- define "cos-common.trim63" -}}
{{- trunc 63 . | trimSuffix "-" -}}
{{ end }}

{{/*
Resolve the chart name, honoring nameOverride.
*/}}
{{- define "cos-common.chartName" -}}
{{- $root := .root -}}
{{- $name := default $root.Chart.Name $root.Values.nameOverride -}}
{{- include "cos-common.trim63" $name -}}
{{ end }}

{{/*
Resolve the Helm chart version label.
*/}}
{{- define "cos-common.chartVersion" -}}
{{- $root := .root -}}
{{- $sanitizedVersion := replace "+" "_" $root.Chart.Version -}}
{{- $label := printf "%s-%s" $root.Chart.Name $sanitizedVersion -}}
{{- include "cos-common.trim63" $label -}}
{{ end }}

{{/*
Resolve the release base name, honoring fullnameOverride.
*/}}
{{- define "cos-common.releaseName" -}}
{{- $root := .root -}}
{{- $name := $root.Release.Name -}}
{{- if $root.Values.fullnameOverride }}
{{- $name = tpl $root.Values.fullnameOverride $root -}}
{{ end }}
{{- include "cos-common.trim63" $name -}}
{{ end }}

{{/*
Compute the component fullname (<release>-<chart>-<component>)
with optional overrides.
*/}}
{{- define "cos-common.fullname" -}}
{{- $vals := default dict .values -}}
{{- if $vals.fullnameOverride }}
  {{- include "cos-common.trim63" (tpl $vals.fullnameOverride .root) -}}
{{- else -}}
  {{- $release := include "cos-common.releaseName" (dict "root" .root) -}}
  {{- $chart := .root.Chart.Name -}}
  {{- $component := .name -}}

  {{- $fullname := printf "%s-%s-%s" $release $chart $component -}}
  {{- include "cos-common.trim63" $fullname -}}
{{- end }}
{{- end }}


{{/*
Resolve a non-empty component name for labels/containers.
If .name is empty, fall back to the chart name.
*/}}
{{- define "cos-common.componentName" -}}
{{- if .name -}}
{{ .name }}
{{- else -}}
{{- include "cos-common.chartName" (dict "root" .root) -}}
{{- end -}}
{{ end }}

{{/*
Common labels shared across objects.
*/}}
{{- define "cos-common.labels" -}}
app.kubernetes.io/name: {{ include "cos-common.chartName" (dict "root" .root) }}
app.kubernetes.io/instance: {{ .root.Release.Name }}
app.kubernetes.io/managed-by: {{ .root.Release.Service }}
app.kubernetes.io/component: {{ include "cos-common.componentName" . }}
{{- with .root.Chart.AppVersion }}
app.kubernetes.io/version: {{ quote . }}
{{ end }}
app.kubernetes.io/part-of: {{ include "cos-common.chartName" (dict "root" .root) }}
helm.sh/chart: {{ include "cos-common.chartVersion" (dict "root" .root) }}
{{ end }}

{{/*
Labels applied to selectors.
*/}}
{{- define "cos-common.selectorLabels" -}}
app.kubernetes.io/name: {{ include "cos-common.chartName" (dict "root" .root) }}
app.kubernetes.io/instance: {{ .root.Release.Name }}
app.kubernetes.io/component: {{ include "cos-common.componentName" . }}
{{ end }}

{{/*
Labels applied to pods (match selectors).
*/}}
{{- define "cos-common.podLabels" -}}
{{- include "cos-common.selectorLabels" . }}
{{ end }}

{{/*
Compose image reference supporting tag or digest.
*/}}
{{- define "cos-common.image" -}}
{{- $img := default dict .image -}}
{{- $root := default dict .root -}}
{{- if not $img.repository }}
{{- fail (printf "component %s requires image.repository" .name) -}}
{{ end }}
{{- $repo := tpl (toString $img.repository) $root -}}
{{- $tag := "" -}}
{{- $digest := "" -}}
{{- if $img.tag }}{{- $tag = tpl (toString $img.tag) $root -}}{{- end -}}
{{- if $img.digest }}{{- $digest = tpl (toString $img.digest) $root -}}{{- end -}}
{{- if $img.digest }}
{{- printf "%s@%s" $repo $digest -}}
{{- else if $img.tag }}
{{- printf "%s:%s" $repo $tag -}}
{{- else -}}
{{- printf "%s:latest" $repo -}}
{{ end }}
{{ end }}

{{/*
Render a generic metadata block, merging labels and annotations.
*/}}
{{- define "cos-common.metadata" -}}
name: {{ include "cos-common.fullname" . | trim }}
labels:
  {{- include "cos-common.labels" . | nindent 2 }}
  {{- with .values.labels }}
  {{ tpl (toYaml .) .root | nindent 2 }}
  {{ end }}
{{- with .values.annotations }}
annotations:
  {{- $anns := tpl (toYaml .) .root | trimSuffix "\n" }}
  {{ $anns | nindent 2 }}
{{ end }}
{{ end }}

{{/*
Merge component annotations with resource-specific annotations.
Honors workload-only scoping via `annotationsWorkloadOnly` and allows
workload-specific additions via `workloadAnnotations`.
*/}}
{{- define "cos-common.annotations" -}}
{{- $values := default (dict) .values -}}
{{- $resourceAnns := default (dict) .resource -}}
{{- $isWorkload := default false .isWorkload -}}
{{- $componentAnns := default (dict) $values.annotations -}}
{{- if and (default false $values.annotationsWorkloadOnly) (not $isWorkload) }}
  {{- $componentAnns = dict -}}
{{- end }}
{{- if $isWorkload }}
  {{- $componentAnns = merge (dict) $componentAnns (default (dict) $values.workloadAnnotations) -}}
{{- end }}
{{- $annotations := merge (dict) $componentAnns $resourceAnns -}}
{{- $annotations | toJson -}}
{{- end }}

{{- define "cos-common.componentChecksum" -}}
{{- $resource := default "configmap" .resource -}}
{{- $templates := dict
    "configmap" "cos-common.configmap"
    "secret" "cos-common.secret"
-}}
{{- $template := get $templates $resource -}}
{{- if not $template }}
  {{- fail (printf "unsupported resource '%s' for checksum" $resource) -}}
{{- end }}
{{- $render := include $template (dict
      "root" .root
      "name" .name
      "values" .values
  ) -}}
{{- if $render }}
{{- trimSuffix "\n" (sha256sum $render) -}}
{{- end }}
{{- end }}

{{/*
Compute pod checksum annotations for resources that affect runtime.
Currently:
- ConfigMap
- Secret
*/}}
{{- define "cos-common.podChecksums" -}}

{{- /* ConfigMap checksum */ -}}
{{- if and .values.configMap (default false .values.configMap.enabled) }}
checksum/configmap: {{ include "cos-common.componentChecksum" (dict
    "root" .root
    "name" .name
    "values" .values
    "resource" "configmap"
) }}
{{- end }}

{{- /* Secret checksum */ -}}
{{- if and .values.secret (default false .values.secret.enabled) }}
checksum/secret: {{ include "cos-common.componentChecksum" (dict
    "root" .root
    "name" .name
    "values" .values
    "resource" "secret"
) }}
{{- end }}

{{- end }}

{{/*
Render pod metadata labels and annotations.
*/}}
{{- define "cos-common.podMetadata" -}}
labels:
  {{- include "cos-common.podLabels" . | nindent 2 }}
  {{- with .values.podLabels }}
  {{ tpl (toYaml .) .root | nindent 2 }}
  {{ end }}
{{- with .values.podAnnotations }}
annotations:
  {{- $podAnns := tpl (toYaml .) .root | trimSuffix "\n" }}
  {{ $podAnns | nindent 2 }}
{{ end }}
{{ end }}

{{/*
Helper to render list values with tpl evaluation.
*/}}
{{- define "cos-common.renderList" -}}
{{- with .list }}
{{ tpl (toYaml .) $.root }}
{{ end }}
{{ end }}

{{/*
Helper to render map values with tpl evaluation.
*/}}
{{- define "cos-common.renderMap" -}}
{{- with .map }}
{{ tpl (toYaml .) $.root }}
{{ end }}
{{ end }}

{{/*
Normalize a port map by templating values and casting numeric strings to integers.
*/}}
{{- define "cos-common.normalizePortMap" -}}
{{- $port := tpl (toYaml .port) .root | fromYaml }}
{{- range $field := (list "port" "targetPort" "containerPort" "hostPort" "nodePort") }}
  {{- $val := get $port $field }}
  {{- if and $val (kindIs "string" $val) (regexMatch "^\\d+$" (toString $val)) }}
    {{- $_ := set $port $field (int $val) }}
  {{- end }}
{{- end }}
{{- $port | toJson -}}
{{ end }}

{{/*
Normalize a probe map and cast httpGet/tcpSocket port strings of digits to integers.
Keeps probes usable when values are templated as strings.
*/}}
{{- define "cos-common.normalizeProbe" -}}
{{- $probe := tpl (toYaml .probe) .root | fromYaml }}
{{- with $probe.httpGet }}
  {{- $p := .port }}
  {{- if and $p (regexMatch "^\\d+$" (toString $p)) }}
    {{- $_ := set . "port" (int $p) }}
  {{- end }}
{{- end }}
{{- with $probe.tcpSocket }}
  {{- $p := .port }}
  {{- if and $p (regexMatch "^\\d+$" (toString $p)) }}
    {{- $_ := set . "port" (int $p) }}
  {{- end }}
{{- end }}
{{- toYaml $probe -}}
{{ end }}

{{/*
Render a service port block, templating strings and converting digit-only strings to numbers.
Accepts either a scalar (name/number) or a port map.
*/}}
{{- define "cos-common.renderServicePort" -}}
{{- $root := .root -}}
{{- $port := .port -}}
{{- if kindIs "map" $port }}
  {{- tpl (toYaml $port) $root -}}
{{- else if kindIs "string" $port }}
  {{- $val := tpl $port $root -}}
  {{- if regexMatch "^\\d+$" (toString $val) }}
number: {{ int $val }}
  {{- else }}
name: {{ $val }}
  {{- end }}
{{- else }}
number: {{ $port }}
{{- end }}
{{ end }}

{{/*
Build copy script for TLS certificates.
*/}}
{{- define "cos-common.tlsCopyScript" -}}
{{- $configs := .configs -}}
{{- $owner := default "www-data:www-data" .owner -}}
{{- range $app, $cfg := $configs }}
cp -f /certs/{{ $app }}/* {{ $cfg.mountPath }}
chown -R {{ $owner }} {{ $cfg.mountPath }}
chmod 0700 {{ $cfg.mountPath }}
chmod -R 0600 {{ $cfg.mountPath }}/*
{{- end }}
{{- end }}

{{/*
Main container specification based on component values.
*/}}
{{- define "cos-common.mainContainer" -}}
{{- $vals := .values -}}
{{- $fallbackName := include "cos-common.componentName" . -}}
{{- $containerName := default (default .name $fallbackName) $vals.containerName -}}
{{- if and $.root (kindIs "string" $containerName) -}}
  {{- $containerName = tpl $containerName $.root -}}
{{- end -}}
{{- $probes := default (dict) $vals.probes -}}
{{- $tlsConfigs := default (dict) .tlsConfigs -}}
{{- $pullPolicy := default "IfNotPresent" $vals.image.pullPolicy -}}
{{- if and (kindIs "string" $pullPolicy) $.root -}}
  {{- $pullPolicy = tpl $pullPolicy $.root -}}
{{- end -}}
name: {{ $containerName }}
image: {{ include "cos-common.image" (dict "image" $vals.image "name" .name "root" .root) }}
imagePullPolicy: {{ $pullPolicy }}
{{- with $vals.command }}
command:
{{ tpl (toYaml .) $.root | nindent 2 }}
{{ end }}
{{- with $vals.args }}
args:
{{ tpl (toYaml .) $.root | nindent 2 }}
{{ end }}
{{- with $vals.workingDir }}
workingDir: {{ tpl . $.root }}
{{ end }}
{{- with $vals.env }}
env:
{{ include "cos-common.renderList" (dict "list" . "root" $.root) | nindent 2 }}
{{ end }}
{{- with $vals.envFrom }}
envFrom:
{{ include "cos-common.renderList" (dict "list" . "root" $.root) | nindent 2 }}
{{ end }}
{{- with $vals.ports }}
  {{- $ports := list }}
  {{- range . }}
    {{- $normalized := include "cos-common.normalizePortMap" (dict "root" $.root "port" .) | fromJson }}
    {{- $ports = append $ports $normalized }}
  {{- end }}
ports:
{{ $ports | toYaml | nindent 2 }}
{{ end }}
{{- with $probes.liveness }}
livenessProbe:
{{ include "cos-common.normalizeProbe" (dict "root" $.root "probe" .) | nindent 2 }}
{{ end }}
{{- with $probes.readiness }}
readinessProbe:
{{ include "cos-common.normalizeProbe" (dict "root" $.root "probe" .) | nindent 2 }}
{{ end }}
{{- with $probes.startup }}
startupProbe:
{{ include "cos-common.normalizeProbe" (dict "root" $.root "probe" .) | nindent 2 }}
{{ end }}
{{- with $vals.lifecycle }}
lifecycle:
{{ tpl (toYaml .) $.root | nindent 2 }}
{{ end }}
{{- $volumeMounts := list }}
{{- with $vals.volumeMounts }}
{{- $volumeMounts = concat $volumeMounts . }}
{{ end }}
{{- with $vals.additionalVolumeMounts }}
{{- $volumeMounts = concat $volumeMounts . }}
{{ end }}
{{- if $tlsConfigs }}
  {{- range $app, $cfg := $tlsConfigs }}
    {{- if or (not $cfg.mountToContainer) (eq $cfg.mountToContainer $containerName) }}
      {{- $volumeMounts = concat $volumeMounts (list (dict "name" (printf "certs-%s" $app) "mountPath" $cfg.mountPath)) }}
    {{- end }}
  {{- end }}
{{- end }}
{{- if gt (len $volumeMounts) 0 }}
volumeMounts:
{{ tpl (toYaml $volumeMounts) $.root | nindent 2 }}
{{ end }}
{{- with $vals.securityContext }}
securityContext:
{{ tpl (toYaml .) $.root | nindent 2 }}
{{ end }}
{{- with $vals.resources }}
resources:
{{ tpl (toYaml .) $.root | nindent 2 }}
{{ end }}
{{ end }}

{{/*
Render additional containers (sidecars/extra).
Merges sidecars and additionalContainers, lets you inherit mounts from another container,
adds TLS mounts, normalizes ports/probes, and strips helper-only keys before render.
*/}}
{{- define "cos-common.additionalContainers" -}}
{{- $vals := .values -}}
{{- $tlsConfigs := default (dict) .tlsConfigs -}}
{{- $containers := list -}}
{{- with $vals.sidecars }}
{{- $containers = concat $containers . -}}
{{ end }}
{{- with $vals.additionalContainers }}
{{- $containers = concat $containers . -}}
{{ end }}
{{- $rendered := list -}}
{{- range $containers }}
  {{- $c := deepCopy . -}}
  {{- $name := default "" $c.name -}}
  {{- $volumeMounts := list -}}
  {{- if $c.inheritVolumeMountsFrom }}
    {{- /* copy mounts from another named container section (e.g., main.daphne) */ -}}
    {{- $inheritFrom := tpl (toString $c.inheritVolumeMountsFrom) $.root -}}
    {{- $src := index $vals $inheritFrom -}}
    {{- if kindIs "map" $src }}
      {{- with (default (list) $src.volumeMounts) }}
        {{- $volumeMounts = concat $volumeMounts . -}}
      {{- end }}
      {{- with (default dict $src.resources).volumeMounts }}
        {{- $volumeMounts = concat $volumeMounts . -}}
      {{- end }}
    {{- end }}
  {{- end }}
  {{- /* remove helper-only key so it doesn't reach k8s */ -}}
  {{- $_ := unset $c "inheritVolumeMountsFrom" -}}
  {{- $volumeMounts = concat $volumeMounts (default (list) $c.volumeMounts) -}}
  {{- if $tlsConfigs }}
    {{- range $app, $cfg := $tlsConfigs }}
      {{- if or (not $cfg.mountToContainer) (eq $cfg.mountToContainer $name) }}
        {{- $volumeMounts = concat $volumeMounts (list (dict "name" (printf "certs-%s" $app) "mountPath" $cfg.mountPath)) }}
      {{- end }}
    {{- end }}
  {{- end }}
  {{- if gt (len $volumeMounts) 0 }}
    {{- $_ := set $c "volumeMounts" $volumeMounts -}}
  {{- end }}
  {{- if $c.ports }}
    {{- $ports := list }}
    {{- range $c.ports }}
      {{- $ports = append $ports (include "cos-common.normalizePortMap" (dict "root" $.root "port" .) | fromJson) }}
    {{- end }}
    {{- $_ := set $c "ports" $ports -}}
  {{- end }}
  {{- /* normalize probes (tpl and cast numeric ports to ints) */ -}}
  {{- $probeKeys := list "readinessProbe" "livenessProbe" "startupProbe" -}}
  {{- range $probeKeys }}
    {{- $probe := index $c . }}
    {{- if $probe }}
      {{- $_ := set $c . (include "cos-common.normalizeProbe" (dict "root" $.root "probe" $probe) | fromYaml) }}
    {{- end }}
  {{- end }}
  {{- $rendered = append $rendered $c -}}
{{- end }}
{{- if gt (len $rendered) 0 }}
{{ tpl (toYaml $rendered) $.root }}
{{- end }}
{{ end }}

{{/*
Render init containers.
*/}}
{{- define "cos-common.initContainers" -}}
{{- $vals := .values -}}
{{- $tlsConfigs := default (dict) .tlsConfigs -}}
{{- $items := list -}}
{{- with $vals.initContainers }}
{{- $items = concat $items . -}}
{{ end }}
{{- with $vals.additionalInitContainers }}
{{- $items = concat $items . -}}
{{ end }}
{{- if $tlsConfigs }}
  {{- $tlsVolumeMounts := list -}}
  {{- range $app, $cfg := $tlsConfigs }}
    {{- /* Mount cert files from the shared secret so the copy init container can stage them. */ -}}
    {{- $tlsFiles := merge (dict) (default dict $cfg.files) (default dict $cfg.base64Files) }}
    {{- $tlsVolumeMounts = concat $tlsVolumeMounts (list (dict "name" (printf "certs-%s" $app) "mountPath" $cfg.mountPath)) }}
    {{- range $key := keys $tlsFiles }}
      {{- $tlsVolumeMounts = concat $tlsVolumeMounts (list (dict "name" "secret" "mountPath" (printf "/certs/%s/%s" $app $key) "subPath" (printf "certs-%s-%s" $app $key) "readOnly" true)) }}
    {{- end }}
  {{- end }}
  {{- $owner := default "www-data:www-data" (get (default dict $vals.enabledInitContainersCertificate) "userCertsOwner") }}
  {{- $script := include "cos-common.tlsCopyScript" (dict "configs" $tlsConfigs "owner" $owner) | trim }}
  {{- $pullPolicy := default "IfNotPresent" $vals.image.pullPolicy -}}
  {{- if and (kindIs "string" $pullPolicy) $.root -}}
    {{- $pullPolicy = tpl $pullPolicy $.root -}}
  {{- end -}}
  {{- $tlsContainer := dict
      "name" "certificates"
      "image" (include "cos-common.image" (dict "image" $vals.image "name" .name "root" .root))
      "imagePullPolicy" $pullPolicy
      "command" (list "/bin/sh" "-c" $script)
      "volumeMounts" $tlsVolumeMounts
  -}}
  {{- $items = concat (list $tlsContainer) $items -}}
{{- end }}
{{- if gt (len $items) 0 }}
initContainers:
{{ tpl (toYaml $items) $.root | nindent 2 }}
{{ end }}
{{ end }}

{{/*
Resolve the claim name for persistence (component-level or per-volume).
*/}}
{{- define "cos-common.persistenceClaimName" -}}
{{- $root := .root -}}
{{- $vals := default dict .values -}}
{{- $pvc := default dict .persistence -}}
{{- $componentName := default "" .name -}}
{{- $volumeName := default "" .volumeName -}}
{{- if and $volumeName (kindIs "string" $volumeName) -}}
  {{- $volumeName = tpl $volumeName $root -}}
{{- end -}}
{{- if $pvc.existingClaim -}}
{{- tpl $pvc.existingClaim $root -}}
{{- else -}}
  {{- if and $volumeName (ne $volumeName "") -}}
    {{- if $componentName -}}
      {{- if ne $componentName $volumeName -}}
        {{- $componentName = printf "%s-%s" $componentName $volumeName -}}
      {{- end -}}
    {{- else -}}
      {{- $componentName = $volumeName -}}
    {{- end -}}
  {{- end -}}
  {{- $fullnameOverride := coalesce $pvc.name $pvc.fullnameOverride $vals.fullnameOverride -}}
  {{- include "cos-common.fullname" (dict "root" $root "name" $componentName "values" (dict "fullnameOverride" $fullnameOverride)) -}}
{{- end -}}
{{- end }}

{{/*
Render volumes (including additionalVolumes).
*/}}
{{- define "cos-common.volumes" -}}
{{- $vals := .values -}}
{{- $tlsConfigs := default (dict) .tlsConfigs -}}
{{- $items := list -}}
{{- with $vals.volumes }}
{{- $items = concat $items . -}}
{{ end }}
{{- with $vals.additionalVolumes }}
{{- $items = concat $items . -}}
{{ end }}
{{- $processed := list -}}
{{- range $items }}
  {{- $volume := omit . "persistence" -}}
  {{- $volName := default "" .name -}}
  {{- $persistence := default dict .persistence -}}
  {{- if and $persistence (default false $persistence.enabled) -}}
    {{- if not $volName -}}
      {{- fail (printf "component %s volume requires name when persistence.enabled=true" $.name) -}}
    {{- end -}}
    {{- if hasKey . "emptyDir" -}}
      {{- fail (printf "component %s volume %s cannot use emptyDir when persistence.enabled=true" $.name $volName) -}}
    {{- end -}}
    {{- $claimName := include "cos-common.persistenceClaimName" (dict "root" $.root "name" $.name "values" $vals "persistence" $persistence "volumeName" $volName) -}}
    {{- $volume = dict "name" $volName "persistentVolumeClaim" (dict "claimName" $claimName) -}}
  {{- end -}}
  {{- $processed = concat $processed (list $volume) -}}
{{- end }}
{{- $items = $processed -}}
{{- $volumeNames := dict -}}
{{- range $items }}
  {{- if .name }}{{- $_ := set $volumeNames .name true }}{{- end }}
{{- end }}
{{- if $tlsConfigs }}
  {{- $sec := default dict $vals.secret -}}
  {{- $secretOverride := coalesce $sec.name $sec.fullnameOverride $vals.fullnameOverride -}}
  {{- $secretName := include "cos-common.fullname" (dict "root" .root "name" .name "values" (dict "fullnameOverride" $secretOverride)) -}}
  {{- if not (hasKey $volumeNames "secret") }}
    {{- $items = concat $items (list (dict "name" "secret" "secret" (dict "secretName" $secretName))) }}
    {{- $_ := set $volumeNames "secret" true }}
  {{- end }}
  {{- range $app, $cfg := $tlsConfigs }}
    {{- $volName := printf "certs-%s" $app }}
    {{- if not (hasKey $volumeNames $volName) }}
      {{- $items = concat $items (list (dict "name" $volName "emptyDir" (dict))) }}
      {{- $_ := set $volumeNames $volName true }}
    {{- end }}
  {{- end }}
{{- end }}
{{- if gt (len $items) 0 }}
volumes:
{{ tpl (toYaml $items) $.root | nindent 2 }}
{{ end }}
{{ end }}

{{/*
Shared pod spec bits.
*/}}
{{- define "cos-common.podSpec" -}}
{{- $vals := .values -}}
{{- $tlsConfigs := (include "cos-common.enabledInitContainersCertificate" (dict "root" $.root "values" $vals)) | fromYaml }}
{{- with $vals.serviceAccountName }}
serviceAccountName: {{ tpl . $.root }}
{{ end }}
{{- with $vals.automountServiceAccountToken }}
automountServiceAccountToken: {{ . }}
{{ end }}
{{- with $vals.hostNetwork }}
hostNetwork: {{ . }}
{{ end }}
{{- with $vals.hostPID }}
hostPID: {{ . }}
{{ end }}
{{- with $vals.hostIPC }}
hostIPC: {{ . }}
{{ end }}
{{- with $vals.dnsPolicy }}
dnsPolicy: {{ . }}
{{ end }}
{{- with $vals.dnsConfig }}
dnsConfig:
{{ tpl (toYaml .) $.root | nindent 2 }}
{{ end }}
{{- with $vals.hostAliases }}
hostAliases:
{{ tpl (toYaml .) $.root | nindent 2 }}
{{ end }}
{{- with $vals.schedulerName }}
schedulerName: {{ . }}
{{ end }}
{{- with $vals.terminationGracePeriodSeconds }}
terminationGracePeriodSeconds: {{ . }}
{{ end }}
{{- with $vals.restartPolicy }}
restartPolicy: {{ . }}
{{ end }}
{{- with $vals.imagePullSecrets }}
imagePullSecrets:
{{ tpl (toYaml .) $.root | nindent 2 }}
{{ end }}
{{- with $vals.podSecurityContext }}
securityContext:
{{ tpl (toYaml .) $.root | nindent 2 }}
{{ end }}
{{- with $vals.priorityClassName }}
priorityClassName: {{ tpl . $.root }}
{{ end }}
{{- with $vals.runtimeClassName }}
runtimeClassName: {{ tpl . $.root }}
{{ end }}
{{- with $vals.shareProcessNamespace }}
shareProcessNamespace: {{ . }}
{{ end }}
{{- with $vals.enableServiceLinks }}
enableServiceLinks: {{ . }}
{{ end }}
{{- with $vals.preemptionPolicy }}
preemptionPolicy: {{ . }}
{{ end }}
{{- with $vals.topologySpreadConstraints }}
topologySpreadConstraints:
{{ tpl (toYaml .) $.root | nindent 2 }}
{{ end }}
{{- /* Merge the base affinity with additionalAffinities (later entries win). */ -}}
{{- $affinity := dict -}}
{{- if $vals.affinity }}
  {{- $affinity = merge $affinity $vals.affinity -}}
{{- end }}
{{- range $extra := default list $vals.additionalAffinities }}
  {{- if $extra }}
    {{- $affinity = merge $affinity $extra -}}
  {{- end }}
{{- end }}
{{- with $affinity }}
affinity:
{{ tpl (toYaml .) $.root | nindent 2 }}
{{- end }}
{{- with $vals.nodeSelector }}
nodeSelector:
{{ tpl (toYaml .) $.root | nindent 2 }}
{{ end }}
{{- with $vals.tolerations }}
tolerations:
{{ tpl (toYaml .) $.root | nindent 2 }}
{{ end }}
{{- with $vals.readinessGates }}
readinessGates:
{{ tpl (toYaml .) $.root | nindent 2 }}
{{ end }}
{{ include "cos-common.initContainers" (dict "root" .root "name" .name "values" $vals "tlsConfigs" $tlsConfigs) }}
containers:
  - {{- include "cos-common.mainContainer" (dict "root" .root "name" .name "values" $vals "tlsConfigs" $tlsConfigs) | nindent 4 }}
{{- with (include "cos-common.additionalContainers" (dict "root" .root "name" .name "values" $vals "tlsConfigs" $tlsConfigs)) }}
{{ . | nindent 2 }}
{{ end }}
{{ include "cos-common.volumes" (dict "root" .root "name" .name "values" $vals "tlsConfigs" $tlsConfigs) }}
{{ end }}

{{/*
Resolve a name for additional resources (configmaps/secrets) with either name or fullnameOverride.
*/}}
{{- define "cos-common.resolveAdditionalName" -}}
{{- $fullnameOverride := .fullnameOverride -}}
{{- $name := .name -}}
{{- $prefix := default "" .prefix -}}
{{- $error := default "additional entry must have either name or fullnameOverride" .error -}}
{{- if $fullnameOverride }}
{{- $fullnameOverride -}}
{{- else if $name }}
{{- printf "%s%s" $prefix $name -}}
{{- else }}
{{- fail $error -}}
{{- end }}
{{- end }}

{{/*
Generic renderer for additional resources that share enable/name/label/annotation patterns.
Callers provide a renderer template name for the resource body.
*/}}
{{- define "cos-common.renderAdditionalResources" -}}
{{- $root := .root -}}
{{- $component := .component -}}
{{- $values := default dict .values -}}
{{- $items := default list .items -}}
{{- $namePrefix := default "" .namePrefix -}}
{{- $error := default "additional entry must have either name or fullnameOverride" .error -}}
{{- $renderer := .renderer -}}
{{- range $item := $items }}
  {{- $itemEnabled := or (not (hasKey $item "enabled")) (eq (toString $item.enabled) "true") -}}
  {{- if $itemEnabled }}
    {{- $name := include "cos-common.resolveAdditionalName" (dict "fullnameOverride" $item.fullnameOverride "name" $item.name "prefix" $namePrefix "error" $error) }}
    {{- $labels := merge (dict) (default (dict) $values.labels) (default (dict) $item.labels) -}}
    {{- $annotations := include "cos-common.annotations" (dict "values" $values "resource" $item.annotations) | fromJson -}}
    {{- include $renderer (dict
        "root" $root
        "component" $component
        "values" $values
        "item" $item
        "name" $name
        "labels" $labels
        "annotations" $annotations
        "fromOverride" (and (hasKey $item "fullnameOverride") $item.fullnameOverride)
      )
    }}
  {{- end }}
{{- end }}
{{- end }}

{{/*
Renderer for additional ConfigMaps (metadata + data blocks).
*/}}
{{- define "cos-common.additionalConfigMapResource" -}}
{{- $root := .root -}}
{{- $name := .name -}}
{{- $labels := .labels -}}
{{- $annotations := .annotations -}}
{{- $item := default dict .item -}}
{{- $data := default dict $item.data -}}
{{- $binaryData := default dict $item.binaryData -}}
---
apiVersion: v1
kind: ConfigMap
metadata:
  {{- include "cos-common.metadata"
      (dict "root" $root "name" .component "values"
        (dict "fullnameOverride" $name "labels" $labels "annotations" $annotations)
      ) | nindent 2
  }}
  {{- with $item.ownerReferences }}
  ownerReferences:
    {{- tpl (toYaml .) $root | nindent 4 }}
  {{- end }}

data:
{{- if eq (len $data) 0 }}
  {}
{{- else if $item.tpl }}
  {{- $renderedData := dict }}
  {{- range $key, $value := $data }}
    {{- if kindIs "string" $value }}
      {{- $_ := set $renderedData $key (tpl $value $root) }}
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

{{- with $item.immutable }}
immutable: {{ . }}
{{- end }}
{{ end }}


{{/*
Renderer for additional Secrets (metadata + data blocks).
*/}}
{{- define "cos-common.additionalSecretResource" -}}
{{- $root := .root -}}
{{- $name := .name -}}
{{- $labels := .labels -}}
{{- $annotations := .annotations -}}
{{- $item := default dict .item -}}
{{- $dataBlock := include "cos-common.buildSecretData" (dict "src" $item "root" $root) }}
---
apiVersion: v1
kind: Secret
metadata:
  {{- include "cos-common.metadata"
      (dict "root" $root "name" .component "values"
        (dict "fullnameOverride" $name "labels" $labels "annotations" $annotations)
      ) | nindent 2
  }}
  {{- with $item.ownerReferences }}
  ownerReferences:
    {{- tpl (toYaml .) $root | nindent 4 }}
  {{- end }}
type: {{ default "Opaque" $item.type }}
{{ $dataBlock | nindent 0 }}
{{- with $item.immutable }}
immutable: {{ . }}
{{- end }}
{{ end }}


{{/*
Renderer for additional NetworkPolicies.
*/}}
{{- define "cos-common.additionalNetworkPolicyResource" -}}
{{- $root := .root -}}
{{- $component := .component -}}
{{- $item := default dict .item -}}
{{- if not $item.name }}
  {{- fail (printf "component %s.additionalNetworkPolicies entry requires name" $component) -}}
{{- end }}
{{- $name := .name -}}
{{- if not .fromOverride }}
  {{- $name = include "cos-common.trim63" $name -}}
{{- end }}
{{- $fullnameOverride := coalesce $item.fullnameOverride $name -}}
{{- $itemNetworkPolicy := merge (dict "enabled" true) (omit $item "labels" "annotations" "fullnameOverride" "enabled" "name") -}}
{{- $itemValues := dict "labels" .labels "annotations" .annotations "fullnameOverride" $fullnameOverride "networkPolicy" $itemNetworkPolicy -}}
{{- include "cos-common.networkpolicy.single" (dict "root" $root "name" $component "values" $itemValues) }}
{{- end }}

{{/*
Renderer for additional Certificates.
*/}}
{{- define "cos-common.additionalCertificateResource" -}}
{{- $root := .root -}}
{{- $component := .component -}}
{{- $item := default dict .item -}}
{{- if and (not $item.secretName) (not $item.name) }}
  {{- fail (printf "component %s.additionalCertificates entry requires name or secretName" $component) }}
{{- end }}
{{- if not $item.issuerRef }}
  {{- fail (printf "component %s.additionalCertificates[%s] missing issuerRef" $component (default $item.name $item.secretName)) }}
{{- end }}
{{- $generatedName := .name -}}
{{- $secretName := default $generatedName $item.secretName -}}
{{- if not .fromOverride }}
  {{- $generatedName = (include "cos-common.trim63" $generatedName) | trim -}}
{{- end }}
{{- if not $item.secretName }}
  {{- $secretName = (include "cos-common.trim63" $secretName) | trim -}}
{{- else }}
  {{- $secretName = $secretName | trim -}}
{{- end }}
{{- $spec := (include "cos-common.buildCertSpec"
      (dict "src" $item "secretName" $secretName "root" $root "values" .values)
    ) | fromYaml
}}
{{- include "cos-common.renderCertificate" (dict
    "root" $root
    "name" $component
    "fullnameOverride" (default $generatedName $item.fullnameOverride)
    "labels" .labels
    "annotations" .annotations
    "spec" $spec
) }}
{{- end }}

{{/*
Render the shared Job spec body so Job and CronJob stay in sync.
*/}}
{{- define "cos-common.jobSpec" -}}
{{- $root := .root -}}
{{- $name := .name -}}
{{- $vals := .values -}}
{{- $suspend := .suspend -}}
{{- $includeManualSelector := default false .includeManualSelector -}}
{{- with $vals.parallelism }}
parallelism: {{ . }}
{{- end }}
{{- with $vals.completions }}
completions: {{ . }}
{{- end }}
{{- with $vals.backoffLimit }}
backoffLimit: {{ . }}
{{- end }}
{{- with $vals.activeDeadlineSeconds }}
activeDeadlineSeconds: {{ . }}
{{- end }}
{{- with $vals.ttlSecondsAfterFinished }}
ttlSecondsAfterFinished: {{ . }}
{{- end }}
{{- with $vals.completionMode }}
completionMode: {{ . }}
{{- end }}
{{- with $suspend }}
suspend: {{ . }}
{{- end }}
{{- with $vals.selector }}
selector:
{{ tpl (toYaml .) $root | nindent 2 }}
{{- end }}
{{- if $includeManualSelector }}
{{- with $vals.manualSelector }}
manualSelector: {{ . }}
{{- end }}
{{- end }}
{{- with $vals.podFailurePolicy }}
podFailurePolicy:
{{ tpl (toYaml .) $root | nindent 2 }}
{{- end }}
template:
  metadata:
    {{- include "cos-common.podMetadata" (dict "root" $root "name" $name "values" $vals) | nindent 4 }}
  spec:
    {{- include "cos-common.podSpec" (dict "root" $root "name" $name "values" $vals) | nindent 4 }}
{{- end }}
