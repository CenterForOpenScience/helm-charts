{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "angular.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "angular.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified certificate name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "angular.certificate.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s-%s" .Release.Name $name .Values.certificate.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Overridable deployment annotations
*/}}
{{- define "angular.deploymentAnnotations" -}}
checksum/config: {{ include (print $.Template.BasePath "/configmap.yaml") . | sha256sum }}
{{- end -}}

{{- define "angular.environment" -}}
{{- $fullname := include "angular.fullname" . -}}
{{- range $key := keys .Values.configEnvs }}
- name: {{ $key }}
  valueFrom:
    configMapKeyRef:
      name: {{ $fullname }}
      key: {{ $key }}
{{- end -}}
{{- end -}}
