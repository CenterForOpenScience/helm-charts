{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "sharejs.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "sharejs.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified mongodb name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "mongodb.fullname" -}}
{{- $name := "mongodb" -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Overridable deployment annotations
*/}}
{{- define "sharejs.deploymentAnnotations" -}}
checksum/config: {{ include (print $.Template.BasePath "/configmap.yaml") . | sha256sum }}
checksum/secret: {{ include (print $.Template.BasePath "/secret.yaml") . | sha256sum }}
{{- end -}}

{{- define "sharejs.environment" -}}
{{- $fullname := include "sharejs.fullname" . -}}
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
{{- if .Values.tls.enabled }}
- name: MONGO_SSL
  value: 'true'
{{- if .Values.tls.files }}
- name: MONGO_SSL_CERT_FILE
  value: /etc/ssl/mongo/cert.pem
- name: MONGO_SSL_KEY_FILE
  value: /etc/ssl/mongo/key.pem
{{- end }}
{{- if .Values.tls.caFiles }}
- name: MONGO_SSL_CA_DIR
  value: /etc/ssl/mongo/CAs/
{{- end }}
{{- end }}
{{- end -}}
