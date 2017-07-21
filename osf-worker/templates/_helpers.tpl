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
Overridable OSF deployment annotations
*/}}
{{- define "osf.deploymentAnnotations" }}
{{- end -}}

{{/*
Overridable OSF database settings
*/}}
{{- define "osf.dbSettings" }}
{{- $fullname := (include "fullname" .) -}}
{{- range tuple "SENSITIVE_DATA_SALT" "SENSITIVE_DATA_SECRET" "OSF_DB_HOST" "OSF_DB_NAME" "OSF_DB_USER" "OSF_DB_PASSWORD" }}
- name: {{ . }}
  valueFrom:
    secretKeyRef:
      name: {{ $fullname }}
      key: {{ . }}
{{- end -}}
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