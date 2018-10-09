{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "osf.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "osf.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified admin name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "osf.admin.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s-%s" .Release.Name $name .Values.admin.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified certificate name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "osf.admin.certificate.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s-%s-%s" .Release.Name $name .Values.admin.name .Values.admin.certificate.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified api name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "osf.api.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s-%s" .Release.Name $name .Values.api.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified certificate name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "osf.api.certificate.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s-%s-%s" .Release.Name $name .Values.api.name .Values.api.certificate.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified beat name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "osf.beat.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s-%s" .Release.Name $name .Values.beat.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified collectstatic name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "osf.collectstatic.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s-%s" .Release.Name $name .Values.collectstatic.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified migration name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "osf.migration.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s-%s" .Release.Name $name .Values.migration.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified web name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "osf.web.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s-%s" .Release.Name $name .Values.web.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified certificate name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "osf.web.certificate.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s-%s-%s" .Release.Name $name .Values.web.name .Values.web.certificate.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified task name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "osf.task.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s-%s" .Release.Name $name .Values.task.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified worker name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "osf.worker.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s-%s" .Release.Name $name .Values.worker.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified maintenance name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "osf.maintenance.fullname" -}}
{{- $name := "maintenance" -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified postgresql name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "osf.postgresql.fullname" -}}
{{- $name := "postgresql" -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified rabbitmq name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "osf.rabbitmq.fullname" -}}
{{- $name := "rabbitmq" -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified elasticsearch client name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "osf.elasticsearch.client.fullname" -}}
{{- $name := "elasticsearch-client" -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified elasticsearch6 client name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "osf.elasticsearch6.client.fullname" -}}
{{- $name := "elasticsearch6-client" -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified redis name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "osf.redis.fullname" -}}
{{- $name := "redis" -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Overridable deployment annotations
*/}}
{{- define "osf.deploymentAnnotations" -}}
checksum/config: {{ include (print $.Template.BasePath "/configmap.yaml") . | sha256sum }}
checksum/secret: {{ include (print $.Template.BasePath "/secret.yaml") . | sha256sum }}
# Init containers not updated on upgrade : https://github.com/kubernetes/helm/issues/2702
{{- if and (eq .Capabilities.KubeVersion.Major "1") (lt .Capabilities.KubeVersion.Minor "8") }}
pod.alpha.kubernetes.io/init-containers: null
pod.beta.kubernetes.io/init-containers: null
{{- end }}
{{- end -}}

{{- define "osf.environment" -}}
{{- if .Values.postgresql.enabled }}
- name: OSF_DB_HOST
  value: {{ template "osf.postgresql.fullname" . }}
- name: OSF_DB_NAME
  value: {{ .Values.postgresql.postgresDatabase | quote }}
- name: OSF_DB_USER
  value: {{ .Values.postgresql.postgresUser | quote }}
- name: OSF_DB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ template "osf.postgresql.fullname" . }}
      key: postgres-password
{{- end }}
{{- if .Values.rabbitmq.enabled }}
- name: RABBITMQ_HOST
  value: {{ template "osf.rabbitmq.fullname" . }}
- name: RABBITMQ_PORT
  value: {{ .Values.rabbitmq.service.ports.amqp | quote }}
- name: RABBITMQ_VHOST
  valueFrom:
    configMapKeyRef:
      name: {{ template "osf.rabbitmq.fullname" . }}
      key: RABBITMQ_VHOST
- name: RABBITMQ_USERNAME
  valueFrom:
    secretKeyRef:
      name: {{ template "osf.rabbitmq.fullname" . }}
      key: RABBITMQ_DEFAULT_USER
- name: RABBITMQ_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ template "osf.rabbitmq.fullname" . }}
      key: RABBITMQ_DEFAULT_PASS
{{- end }}
{{- if .Values.elasticsearch.enabled }}
- name: ELASTIC_URI
  value: http://{{ template "osf.elasticsearch.client.fullname" . }}:9200
{{- end }}
{{- if .Values.elasticsearch6.enabled }}
- name: ELASTIC6_URI
  value: http://{{ template "osf.elasticsearch6.client.fullname" . }}:9200
{{- end }}
{{- $fullname := include "osf.fullname" . -}}
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
{{- end -}}

{{- define "osf.certificates.initContainer" -}}
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

{{- define "osf.volumes" -}}
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
    name: {{ template "osf.fullname" . }}
- name: secret
  secret:
    secretName: {{ template "osf.fullname" . }}
{{- end -}}

{{- define "osf.volumeMounts" -}}
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