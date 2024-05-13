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
