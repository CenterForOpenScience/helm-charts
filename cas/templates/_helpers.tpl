{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "cas.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "cas.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified maintenance name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "maintenance.fullname" -}}
{{- $name := "maintenance" -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified postgresql name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "postgresql.fullname" -}}
{{- printf "%s-%s" .Release.Name "postgresql" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Apache volume mounts
*/}}
{{- define "cas.apache.volumeMounts" }}
{{- range $key := keys (merge .Values.apache.configFiles (include "cas.apache.inlineconfigs" . | fromYaml) (include "cas.apache.fileconfigs" . | fromYaml)) }}
- mountPath: /etc/{{ $key }}
  name: config
  subPath: apache-{{ $key | replace "/" "-" }}
  readOnly: true
{{- end }}
{{- range $key := keys .Values.apache.secretFiles }}
- mountPath: /etc/{{ $key }}
  name: secret
  subPath: apache-{{ $key | replace "/" "-" }}
  readOnly: true
{{- end }}
{{- end }}

{{- define "cas.jetty.volumeMounts" }}
{{- range $key := keys (merge .Values.jetty.configFiles (include "cas.jetty.inlineconfigs" . | fromYaml) (include "cas.jetty.fileconfigs" . | fromYaml)) }}
- mountPath: /etc/cas/{{ $key }}
  name: config
  subPath: jetty-{{ $key | replace "/" "-" }}
  readOnly: true
{{- end }}
{{- range $key := keys .Values.jetty.secretFiles }}
- mountPath: /etc/cas/{{ $key }}
  name: secret
  subPath: jetty-{{ $key | replace "/" "-" }}
  readOnly: true
{{- end }}
{{- end }}

{{/*
Apache environment variables
*/}}
{{- define "cas.apache.environment" -}}
{{- $fullname := include "cas.fullname" . -}}
{{- range $key := keys .Values.apache.configEnvs }}
- name: {{ $key }}
  valueFrom:
    configMapKeyRef:
      name: {{ $fullname }}
      key: apache-{{ $key }}
{{- end }}
{{- range $key := keys .Values.apache.secretEnvs }}
- name: {{ $key }}
  valueFrom:
    secretKeyRef:
      name: {{ $fullname }}
      key: apache-{{ $key }}
{{- end }}
{{- end -}}

{{/*
Jetty environment variables
*/}}
{{- define "cas.jetty.environment" -}}
- name: SESSION_SECURE_COOKIES
  value: "true"
{{- if .Values.postgresql.enabled }}
- name: DATABASE_URL
  value: jdbc:postgresql://{{ template "postgresql.fullname" . }}/{{ .Values.postgresql.postgresDatabase }}?targetServerType=master
- name: DATABASE_USER
  value: {{ .Values.postgresql.postgresUser }}
- name: DATABASE_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ template "postgresql.fullname" . }}
      key: postgres-password
{{- end }}
{{- $fullname := include "cas.fullname" . -}}
{{- range $key := keys .Values.jetty.configEnvs }}
- name: {{ $key }}
  valueFrom:
    configMapKeyRef:
      name: {{ $fullname }}
      key: jetty-{{ $key }}
{{- end }}
{{- range $key := keys .Values.jetty.secretEnvs }}
- name: {{ $key }}
  valueFrom:
    secretKeyRef:
      name: {{ $fullname }}
      key: jetty-{{ $key }}
{{- end }}
{{- end -}}
