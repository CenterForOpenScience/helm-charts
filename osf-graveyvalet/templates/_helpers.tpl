{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "osf-gravyvalet.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "osf-gravyvalet.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified postgresql name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "osf-gravyvalet.postgresql.fullname" -}}
{{- $name := "postgresql" -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified rabbitmq name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "osf-gravyvalet.rabbitmq.fullname" -}}
{{- $name := "rabbitmq" -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified certificate name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "osf-gravyvalet.certificate.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s-%s" .Release.Name $name .Values.certificate.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified migration name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "osf-gravyvalet.migration.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s-%s" .Release.Name $name .Values.migration.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified worker name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "osf-gravyvalet.worker.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s-%s" .Release.Name $name .Values.worker.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified beat name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "osf-gravyvalet.beat.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s-%s" .Release.Name $name .Values.beat.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Overridable deployment annotations
*/}}
{{- define "osf-gravyvalet.deploymentAnnotations" -}}
checksum/config: {{ include (print $.Template.BasePath "/configmap.yaml") . | sha256sum }}
checksum/secret: {{ include (print $.Template.BasePath "/secret.yaml") . | sha256sum }}
{{- end -}}

{{- define "osf-gravyvalet.environment" -}}
{{- $fullname := include "osf-gravyvalet.fullname" . -}}
{{- range $key, $value := .Values.configEnvs }}
- name: {{ $key }}
  valueFrom:
    configMapKeyRef:
      name: {{ $fullname }}
      key: {{ $key }}
{{- end }}
{{- range $key, $value := .Values.secretEnvs }}
- name: {{ $key }}
  valueFrom:
    secretKeyRef:
      name: {{ $fullname }}
      key: {{ $key }}
{{- end }}
{{- if and .Values.persistence.enabled .Values.persistence.mountPath }}
- name: gravyvalet_FILESTORE_DIR
  value: {{ .Values.persistence.mountPath }}
{{- end }}
{{- end -}}

{{- define "gravyvalet.certificates.initContainer" -}}
{{- if .Values.tls.enabled }}
- name: certificates
  image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
  imagePullPolicy: {{ .Values.image.pullPolicy }}
  command:
    - /bin/sh
    - -c
    - |-
      {{- range $app, $tls := omit .Values.tls "enabled" }}
      {{- if $tls.enabled }}
      cp -f /certs/{{ $app }}/* {{ $tls.mountPath }}
      chown -R www-data:www-data {{ $tls.mountPath }}
      chmod -R 0600 {{ $tls.mountPath }}/*
      {{- end }}
      {{- end }}
  volumeMounts:
    {{- range $app, $tls := omit .Values.tls "enabled" }}
    {{- if $tls.enabled }}
    - name: certs-{{ $app }}
      mountPath: {{ $tls.mountPath }}
    {{- range $key := keys $tls.files }}
    - mountPath: /certs/{{ $app }}/{{ $key }}
      name: secret
      subPath: certs-{{ $app }}-{{ $key }}
      readOnly: true
    {{- end }}
    {{- end }}
    {{- end }}
{{- end }}
{{- end }}

{{- define "osf-gravyvalet.volumes" -}}
{{- if .Values.tls.enabled }}
{{- range $app, $tls := omit .Values.tls "enabled" }}
{{- if $tls.enabled }}
- name: certs-{{ $app }}
  emptyDir: {}
{{- end }}
{{- end }}
{{- end }}
- name: config
  configMap:
    name: {{ template "osf-gravyvalet.fullname" . }}
- name: secret
  secret:
    secretName: {{ template "osf-gravyvalet.fullname" . }}
{{- end -}}

{{- define "gravyvalet.volumeMounts" -}}
{{- if .Values.volumeMounts -}}
{{- toYaml .Values.volumeMounts }}
{{- end -}}
{{- if .Values.tls.enabled }}
{{- range $app, $tls := omit .Values.tls "enabled" }}
{{- if $tls.enabled }}
- name: certs-{{ $app }}
  mountPath: {{ $tls.mountPath }}
{{- end }}
{{- end }}
{{- end }}
{{- end -}}
