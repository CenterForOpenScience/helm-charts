{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "lookit.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "lookit.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified collectstatic name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "lookit.collectstatic.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s-%s" .Release.Name $name .Values.collectstatic.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified migration name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "lookit.migration.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s-%s" .Release.Name $name .Values.migration.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified web name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "lookit.web.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s-%s" .Release.Name $name .Values.web.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified worker name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "lookit.worker.fullname" -}}
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

{{- define "lookit.environment" }}
- name: DB_NAME
  value: {{ .Values.postgresql.postgresDatabase | quote }}
- name: DB_USER
  value: {{ .Values.postgresql.postgresUser | quote }}
- name: DB_HOST
{{- if .Values.postgresql.enabled }}
  value: {{ template "postgresql.fullname" . }}
{{- else }}
  value: {{ .Values.postgresql.postgresHost }}
{{- end }}
- name: DB_PASSWORD
  valueFrom:
    secretKeyRef:
{{- if .Values.postgresql.enabled }}
      name: {{ template "postgresql.fullname" . }}
{{- else }}
      name: {{ template "lookit.fullname" . }}
{{- end }}
      key: postgres-password
- name: RABBITMQ_HOST
{{- if .Values.rabbitmq.enabled }}
  value: {{ template "rabbitmq.fullname" . }}
{{- else }}
  value: {{ .Values.rabbitmq.rabbitmqHost | quote }}
{{- end }}
- name: RABBITMQ_PORT
  value: {{ .Values.rabbitmq.rabbitmqNodePort | quote }}
- name: RABBITMQ_VHOST
  value: {{ .Values.rabbitmq.rabbitmqVhost | quote }}
- name: RABBITMQ_USERNAME
  value: {{ .Values.rabbitmq.rabbitmqUsername | quote }}
- name: RABBITMQ_PASSWORD
  valueFrom:
    secretKeyRef:
{{- if .Values.rabbitmq.enabled }}
      name: {{ template "rabbitmq.fullname" . }}
{{- else }}
      name: {{ template "lookit.fullname" . }}
{{- end }}
      key: rabbitmq-password
{{- $fullname := include "lookit.fullname" . -}}
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
