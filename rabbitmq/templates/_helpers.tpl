{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "rabbitmq.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "rabbitmq.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "rabbitmq.environment" }}
- name: RABBITMQ_NODE_PORT_NUMBER
  value: {{ .Values.service.ports.amqp | quote }}
- name: RABBITMQ_MANAGER_PORT_NUMBER
  value: {{ .Values.service.ports.stats | quote }}
{{- $fullname := include "rabbitmq.fullname" . -}}
{{- range $key, $val := .Values.configEnvs }}
- name: {{ $key }}
  valueFrom:
    configMapKeyRef:
      name: {{ $fullname }}
      key: {{ $key }}
{{- end }}
{{- range $key, $val := .Values.secretEnvs }}
- name: {{ $key }}
  valueFrom:
    secretKeyRef:
      name: {{ $fullname }}
      key: {{ $key }}
{{- end }}
{{- end -}}

{{- define "rabbitmq.volumeMounts" }}
{{- if and .Values.configEnvs.RABBITMQ_SSL_CERTFILE (index .Values.secretFiles "server_certificate.pem") }}
- name: secret-volume
  subPath: server_certificate.pem
  mountPath: {{ .Values.configEnvs.RABBITMQ_SSL_CERTFILE }}
  readOnly: true
{{- end }}
{{- if and .Values.configEnvs.RABBITMQ_SSL_KEYFILE (index .Values.secretFiles "server_key.pem") }}
- name: secret-volume
  subPath: server_key.pem
  mountPath: {{ .Values.configEnvs.RABBITMQ_SSL_KEYFILE }}
  readOnly: true
{{- end }}
{{- if and .Values.configEnvs.RABBITMQ_SSL_CACERTFILE (index .Values.secretFiles "ca_certificate.pem") }}
- name: secret-volume
  subPath: ca_certificate.pem
  mountPath: {{ .Values.configEnvs.RABBITMQ_SSL_CACERTFILE }}
  readOnly: true
{{- end }}
{{- end -}}