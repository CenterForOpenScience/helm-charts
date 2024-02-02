{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "elasticsearch.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "elasticsearch.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified client name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "elasticsearch.client.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s-%s" .Release.Name $name .Values.client.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified data name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "elasticsearch.data.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s-%s" .Release.Name $name .Values.data.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified master name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "elasticsearch.master.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s-%s" .Release.Name $name .Values.master.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Default list of standard annotations for all deployments and statefulsets.
*/}}
{{- define "elasticsearch.annotations" }}
checksum/config: {{ include (print $.Template.BasePath "/configmap.yaml") . | sha256sum }}
checksum/secret: {{ include (print $.Template.BasePath "/secret.yaml") . | sha256sum }}
{{- end -}}

{{- define "elasticsearch.initContainers.common" }}
- name: increase-memory-limits
  image: busybox
  command:
    - sh
    - -c
    - |-
      # see https://www.elastic.co/guide/en/elasticsearch/reference/current/vm-max-map-count.html
      # and https://www.elastic.co/guide/en/elasticsearch/reference/current/setup-configuration-memory.html#mlockall
      # and https://www.elastic.co/guide/en/elasticsearch/reference/current/docker.html#docker-cli-run-prod-mode
      sysctl -w vm.max_map_count=262144
      # To increase the ulimit
      # https://www.elastic.co/guide/en/elasticsearch/reference/current/docker.html#_notes_for_production_use_and_defaults
      ulimit -l unlimited
  securityContext:
    privileged: true
{{- if .Values.plugins.enabled }}
- name: plugins
  image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
  imagePullPolicy: {{ default "" .Values.image.pullPolicy | quote }}
  command:
    - /bin/sh
    - -c
    - |-
      {{- if semverCompare "^2.x" .Values.appVersion }}
      {{ if .Values.plugins.remove }}bin/plugin remove {{ join " && bin/plugin remove " .Values.plugins.remove }}{{ end }}
      {{ if .Values.plugins.install }}bin/plugin install {{ join " && bin/plugin install " .Values.plugins.install }}{{ end }}
      {{- end }}
      {{- if semverCompare ">= 5.x" .Values.appVersion }}
      {{ if .Values.plugins.remove }}bin/elasticsearch-plugin remove {{ join " && bin/elasticsearch-plugin remove " .Values.plugins.remove }}{{ end }}
      {{ if .Values.plugins.install }}bin/elasticsearch-plugin install -b {{ join " && bin/elasticsearch-plugin install -b " .Values.plugins.install }}{{ end }}
      {{- end }}
      cp -Rf /usr/share/elasticsearch/plugins/. /plugins/
  volumeMounts:
    - mountPath: /plugins
      name: plugins
{{- end }}
{{- end -}}