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
Create a default fully qualified api name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "osf.api.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s-%s" .Release.Name $name .Values.api.name | trunc 63 | trimSuffix "-" -}}
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
Create a default fully qualified postgresql name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "postgresql.fullname" -}}
{{- $name := "postgresql" -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified rabbitmq name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "rabbitmq.fullname" -}}
{{- $name := "rabbitmq" -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified elasticsearch client name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "elasticsearch.client.fullname" -}}
{{- $name := "elasticsearch-client" -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Overridable deployment annotations
*/}}
{{- define "osf.deploymentAnnotations" -}}
checksum/config: {{ include (print $.Template.BasePath "/configmap.yaml") . | sha256sum }}
checksum/secret: {{ include (print $.Template.BasePath "/secret.yaml") . | sha256sum }}
{{- end -}}

{{- define "osf.environment" -}}
{{- if .Values.postgresql.enabled }}
- name: OSF_DB_HOST
  value: {{ template "postgresql.fullname" . }}
- name: OSF_DB_NAME
  value: {{ .Values.postgresql.postgresDatabase | quote }}
- name: OSF_DB_USER
  value: {{ .Values.postgresql.postgresUser | quote }}
- name: OSF_DB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ template "postgresql.fullname" . }}
      key: postgres-password
{{- end }}
{{- if .Values.rabbitmq.enabled }}
- name: RABBITMQ_HOST
  value: {{ template "rabbitmq.fullname" . }}
- name: RABBITMQ_PORT
  value: {{ .Values.rabbitmq.rabbitmqNodePort | quote }}
- name: RABBITMQ_VHOST
  value: {{ .Values.rabbitmq.rabbitmqVhost | quote }}
- name: RABBITMQ_USERNAME
  value: {{ .Values.rabbitmq.rabbitmqUsername | quote }}
- name: RABBITMQ_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ template "rabbitmq.fullname" . }}
      key: rabbitmq-password
{{- end }}
{{- if .Values.elasticsearch.enabled }}
- name: ELASTIC_URI
  value: http://{{ template "elasticsearch.client.fullname" . }}:9200
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

{{/*
admin initContainers
*/}}
{{- define "osf.admin.initContainers" -}}
initContainers:
{{- if or (not .Values.collectstatic.enabled) .Values.tls.enabled }}
  {{- if not .Values.collectstatic.enabled }}
  - name: {{ .Values.collectstatic.name }}
    image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
    imagePullPolicy: {{ .Values.image.pullPolicy }}
    command:
      - /bin/sh
      - -c
      - mkdir -p /static/code/admin &&
        cp -Rf /code/static_root/* /static/code/admin
    volumeMounts:
      - mountPath: /static
        name: static
  {{- end }}
  {{- include "osf.certificates.initContainer" . | nindent 2 }}
  {{- else }} []
  {{- end }}
{{- end -}}


{{/*
api initContainers
*/}}
{{- define "osf.api.initContainers" -}}
initContainers:
  {{- if or (not .Values.collectstatic.enabled) .Values.tls.enabled }}
  {{- if not .Values.collectstatic.enabled }}
  - name: {{ .Values.collectstatic.name }}
    image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
    imagePullPolicy: {{ .Values.image.pullPolicy }}
    command:
      - /bin/sh
      - -c
      - mkdir -p /static/code/api &&
        cp -Rf /code/api/static /static/code/api
    volumeMounts:
      - mountPath: /static
        name: static
  {{- end }}
  {{- include "osf.certificates.initContainer" . | nindent 2 }}
  {{- else }} []
  {{- end }}
{{- end -}}

{{/*
beat initContainers
*/}}
{{- define "osf.beat.initContainers" -}}
initContainers:
  - name: chown
    image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
    imagePullPolicy: {{ .Values.image.pullPolicy }}
    command:
      - /bin/bash
      - -c
      - chown -R www-data:www-data /beat &&
        chown -R www-data:www-data /log
    securityContext:
      runAsUser: 0
    volumeMounts:
      - mountPath: /beat
        name: beat
      - mountPath: /log
        name: log
  {{- include "osf.certificates.initContainer" . | nindent 2 }}
{{- end -}}

{{/*
migration initContainers
*/}}
{{- define "osf.migration.initContainers" -}}
initContainers:
  - name: chown
    image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
    imagePullPolicy: {{ .Values.image.pullPolicy }}
    command:
      - /bin/bash
      - -c
      - chown -R www-data:www-data /log
    securityContext:
      runAsUser: 0
    volumeMounts:
      - mountPath: /log
        name: log
  {{- include "osf.certificates.initContainer" . | nindent 2 }}
{{- end -}}

{{/*
task initContainers
*/}}
{{- define "osf.task.initContainers" -}}
initContainers:
  - name: chown
    image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
    imagePullPolicy: {{ .Values.image.pullPolicy }}
    command:
      - /bin/bash
      - -c
      - chown -R www-data:www-data /log
    securityContext:
      runAsUser: 0
    volumeMounts:
      - mountPath: /log
        name: log
  {{- include "osf.certificates.initContainer" . | nindent 2 }}
{{- end -}}

{{/*
web initContainers
*/}}
{{- define "osf.web.initContainers" -}}
initContainers:
  {{- if or (not .Values.collectstatic.enabled) .Values.tls.enabled }}
  {{- if not .Values.collectstatic.enabled }}
  - name: {{ .Values.collectstatic.name }}
    image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
    imagePullPolicy: {{ .Values.image.pullPolicy }}
    command:
      - /bin/sh
      - -c
      - mkdir -p /static/code/website &&
        cp -Rf /code/website/static /static/code/website &&
        find /code/addons/ -type f | grep -i /static/ | xargs -i cp -f --parents {} /static/
    volumeMounts:
      - mountPath: /static
        name: static
  {{- end }}
  {{- include "osf.certificates.initContainer" . | nindent 2 }}
  {{- else }} []
  {{- end }}
{{- end -}}

{{/*
worker initContainers
*/}}
{{- define "osf.worker.initContainers" -}}
initContainers:
  {{- if or (not .Values.task.enabled) .Values.tls.enabled }}
  {{- if not .Values.task.enabled }}
  - name: chown
    image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
    imagePullPolicy: {{ .Values.image.pullPolicy }}
    command:
      - /bin/bash
      - -c
      - chown -R www-data:www-data /log
    securityContext:
      runAsUser: 0
    volumeMounts:
      - mountPath: /log
        name: log
  {{- end }}
  {{- include "osf.certificates.initContainer" . | nindent 2 }}
  {{- else }} []
  {{- end }}
{{- end -}}

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