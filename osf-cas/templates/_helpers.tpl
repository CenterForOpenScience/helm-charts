{{/*
Apache volume mounts
*/}}
{{- define "cas.apache.volumeMounts" }}
{{- $configFiles := merge (default dict .Values.apache.configFiles) (include "cas.apache.inlineconfigs" . | fromYaml | default dict) (include "cas.apache.fileconfigs" . | fromYaml | default dict) }}
{{- range $key := keys $configFiles }}
- mountPath: /etc/{{ $key }}
  name: config
  subPath: apache-{{ $key | replace "/" "-" }}
  readOnly: true
{{- end }}
{{- range $key := keys (default dict .Values.apache.secretFiles) }}
- mountPath: /etc/{{ $key }}
  name: secret
  subPath: apache-{{ $key | replace "/" "-" }}
  readOnly: true
{{- end }}
{{- end }}

{{- define "cas.jetty.volumeMounts" }}
{{- $configFiles := merge (default dict .Values.jetty.configFiles) (include "cas.jetty.inlineconfigs" . | fromYaml | default dict) (include "cas.jetty.fileconfigs" . | fromYaml | default dict) }}
{{- range $key := keys $configFiles }}
- mountPath: /etc/cas/{{ $key }}
  name: config
  subPath: jetty-{{ $key | replace "/" "-" }}
  readOnly: true
{{- end }}
{{- range $key := keys (default dict .Values.jetty.secretFiles) }}
- mountPath: /etc/cas/{{ $key }}
  name: secret
  subPath: jetty-{{ $key | replace "/" "-" }}
  readOnly: true
{{- end }}
{{- end }}

{{/*
Apache environment variables
*/}}
{{- define "cas.apache.environment" -}}
{{- $fullname := include "cos-common.fullname" (dict "root" . "name" "" "values" .Values.main) -}}
{{- range $key := keys (default dict .Values.apache.configEnvs) }}
- name: {{ $key }}
  valueFrom:
    configMapKeyRef:
      name: {{ $fullname }}
      key: apache-{{ $key }}
{{- end }}
{{- range $key := keys (default dict .Values.apache.secretEnvs) }}
- name: {{ $key }}
  valueFrom:
    secretKeyRef:
      name: {{ $fullname }}
      key: apache-{{ $key }}
{{- end }}
{{- end -}}

{{/*
Jetty environment variables
*/}}
{{- define "cas.jetty.environment" -}}
- name: SESSION_SECURE_COOKIES
  value: "true"
{{- $fullname := include "cos-common.fullname" (dict "root" . "name" "" "values" .Values.main) -}}
{{- range $key := keys (default dict .Values.jetty.configEnvs) }}
- name: {{ $key }}
  valueFrom:
    configMapKeyRef:
      name: {{ $fullname }}
      key: jetty-{{ $key }}
{{- end }}
{{- range $key := keys (default dict .Values.jetty.secretEnvs) }}
- name: {{ $key }}
  valueFrom:
    secretKeyRef:
      name: {{ $fullname }}
      key: jetty-{{ $key }}
{{- end }}
{{- end -}}

{{/*
Checksums for rendered ConfigMap/Secret to trigger pod restarts on updates.
*/}}
{{- define "cas.podChecksums" -}}
checksum/config: {{ include (print $.Template.BasePath "/configmap.yaml") . | sha256sum }}
checksum/secret: {{ include (print $.Template.BasePath "/secret.yaml") . | sha256sum }}
{{- end }}

{{/*
Prepare the main values with injected Jetty/Apache envs and volume mounts
*/}}
{{- define "cas.main.values" -}}
{{- $root := .root -}}
{{- $main := deepCopy (default dict .values) -}}

{{- /* Inject Jetty envs from helpers */}}
{{- $jettyEnvRaw := include "cas.jetty.environment" $root | fromYamlArray }}
{{- $jettyEnv := ternary $jettyEnvRaw (list) (kindIs "slice" $jettyEnvRaw) }}
{{- $mergedEnv := list }}
{{- range (default list $main.env) }}
  {{- $mergedEnv = append $mergedEnv . }}
{{- end }}
{{- range (default list $jettyEnv) }}
  {{- $mergedEnv = append $mergedEnv . }}
{{- end }}
{{- $_ := set $main "env" $mergedEnv }}

{{- /* Inject Jetty volume mounts from helpers */}}
{{- $jettyMountsRaw := include "cas.jetty.volumeMounts" $root | fromYamlArray }}
{{- $jettyMounts := ternary $jettyMountsRaw (list) (kindIs "slice" $jettyMountsRaw) }}
{{- $mergedMounts := list }}
{{- range (default list $main.additionalVolumeMounts) }}
  {{- $mergedMounts = append $mergedMounts . }}
{{- end }}
{{- range (default list $jettyMounts) }}
  {{- $mergedMounts = append $mergedMounts . }}
{{- end }}
{{- $_ := set $main "additionalVolumeMounts" $mergedMounts }}

{{- /* Wire Apache helper envs/volume mounts into the apache additional container */}}
{{- $updatedContainers := list }}
{{- range $idx, $container := default list $main.additionalContainers }}
  {{- $c := deepCopy $container }}
  {{- if eq $c.name "apache" }}
    {{- $apacheEnvRaw := include "cas.apache.environment" $root | fromYamlArray }}
    {{- $apacheEnv := ternary $apacheEnvRaw (list) (kindIs "slice" $apacheEnvRaw) }}
    {{- $cEnv := list }}
    {{- range (default list $c.env) }}
      {{- $cEnv = append $cEnv . }}
    {{- end }}
    {{- range (default list $apacheEnv) }}
      {{- $cEnv = append $cEnv . }}
    {{- end }}
    {{- $_ := set $c "env" $cEnv }}

    {{- $apacheMountsRaw := include "cas.apache.volumeMounts" $root | fromYamlArray }}
    {{- $apacheMounts := ternary $apacheMountsRaw (list) (kindIs "slice" $apacheMountsRaw) }}
    {{- $cMounts := list }}
    {{- range (default list $c.volumeMounts) }}
      {{- $cMounts = append $cMounts . }}
    {{- end }}
    {{- range (default list $apacheMounts) }}
      {{- $cMounts = append $cMounts . }}
    {{- end }}
    {{- $_ := set $c "volumeMounts" $cMounts }}
  {{- end }}
  {{- $updatedContainers = append $updatedContainers $c }}
{{- end }}
{{- $_ := set $main "additionalContainers" $updatedContainers }}

{{- /* Add checksum pod annotations for config/secret changes. */}}
{{- $checksumAnnotations := include "cas.podChecksums" $root | fromYaml | default dict }}
{{- $podAnnotations := merge (dict) (default dict $main.podAnnotations) $checksumAnnotations }}
{{- $_ := set $main "podAnnotations" $podAnnotations }}

{{- toYaml $main -}}
{{- end -}}
