{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified postgresql name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "postgresql.fullname" -}}
{{- printf "%s-%s" .Release.Name "postgresql" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "environment" }}
- name: DJANGO_SETTINGS_MODULE
  value: project.settings
- name: GEVENT
  value: '1'
- name: DB_NAME
  value: {{ .Values.postgresql.postgresDatabase | quote }}
- name: DB_USER
  value: {{ .Values.postgresql.postgresUser | quote }}
- name: DB_HOST
  value: {{ template "postgresql.fullname" . }}
- name: DB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ template "postgresql.fullname" . }}
      key: postgres-password
- name: GOOGLE_APPLICATION_CREDENTIALS
  value: /etc/googleAppCreds.json
- name: MEDIA_URL
  value: {{ .Values.mediaUrl | quote }}
- name: STATIC_URL
  value: {{ .Values.staticUrl | quote }}
- name: GS_BUCKET_NAME
  value: {{ .Values.gsBucketName | quote }}
- name: GS_PROJECT_ID
  value: {{ .Values.gsProjectId | quote }}
{{- end -}}
