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
Overridable OSF database settings
*/}}
{{- define "osf.dbSettings" }}
- name: SENSITIVE_DATA_SALT
  valueFrom:
    secretKeyRef:
      key: sensitive-data-salt
      name: {{ .Values.osfSecretName }}
- name: SENSITIVE_DATA_SECRET
  valueFrom:
    secretKeyRef:
      key: sensitive-data-secret
      name: {{ .Values.osfSecretName }}
- name: OSF_DB_HOST
  value: {{ .Values.postgresHost }}
- name: OSF_DB_NAME
  value: {{ .Values.postgresDatabase }}
- name: OSF_DB_USER
  value: {{ .Values.postgresUser }}
- name: OSF_DB_PASSWORD
  valueFrom:
    secretKeyRef:
      key: postgres-password
      name: {{ .Values.postgresSecret }}
{{- end -}}

{{/*
Overridable OSF volume mounts
*/}}
{{- define "osf.volumeMounts" }}
{{- end -}}

{{/*
Overridable OSF volumes
*/}}
{{- define "osf.volumes" }}
{{- end -}}