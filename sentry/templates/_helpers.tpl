{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "sentry.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "sentry.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "postgresql.fullname" -}}
{{- printf "%s-%s" .Release.Name "postgresql" | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- define "postgresql.master.fullname" -}}
{{- printf "%s-%s-%s" .Release.Name "postgresql" "master" | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- define "redis.fullname" -}}
{{- printf "%s-%s" .Release.Name "redis" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Standard Labels
*/}}
{{- define "sentry.labels.standard" -}}
app: {{ template "sentry.name" . }}
chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
heritage: {{ .Release.Service }}
release: {{ .Release.Name }}
{{- end -}}

{{/*
Workload annotations
*/}}
{{- define "sentry.workloadAnnotations" -}}
checksum/config: {{ include (print $.Template.BasePath "/configmap.yaml") . | sha256sum }}
checksum/secret: {{ include (print $.Template.BasePath "/secret.yaml") . | sha256sum }}
{{- end -}}

{{- define "sentry.environment" -}}
{{- $fullname := include "sentry.fullname" . -}}
{{- range $key := keys .Values.configEnvs }}
- name: {{ $key }}
  valueFrom:
    configMapKeyRef:
      name: {{ $fullname }}
      key: {{ $key }}
{{- end }}
{{- range $key := keys .Values.secretEnvs }}
- name: {{ $key }}
  valueFrom:
    secretKeyRef:
      name: {{ $fullname }}
      key: {{ $key }}
{{- end }}
{{- if and .Values.persistence.enabled .Values.persistence.mountPath }}
- name: SENTRY_FILESTORE_DIR
  value: {{ .Values.persistence.mountPath }}
{{- end }}
{{- if .Values.postgresql.enabled }}
- name: SENTRY_DB_USER
  valueFrom:
    secretKeyRef:
      name: {{ template "postgresql.fullname" . }}
      key: POSTGRES_USER
- name: SENTRY_DB_NAME
  valueFrom:
    secretKeyRef:
      name: {{ template "postgresql.fullname" . }}
      key: POSTGRES_DB
- name: SENTRY_DB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ template "postgresql.fullname" . }}
      key: POSTGRES_PASSWORD
- name: SENTRY_POSTGRES_HOST
  value: {{ template "postgresql.master.fullname" . }}
- name: SENTRY_POSTGRES_PORT
  value: {{ .Values.postgresql.master.service.port | quote }}
{{- end }}
{{- if .Values.redis.enabled }}
- name: SENTRY_REDIS_HOST
  value: {{ template "redis.fullname" . }}
- name: SENTRY_REDIS_PORT
  value: {{ .Values.redis.service.port | quote }}
- name: SENTRY_REDIS_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ template "redis.fullname" . }}
      key: REDIS_PASSWORD
{{- end }}
{{- end -}}