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
{{- end -}}

{{- define "rabbitmq.volumeMounts" }}
{{- if .Values.tls.enabled }}
- name: secret
  subPath: server_certificate.pem
  mountPath: /etc/ssl/server_certificate.pem
  readOnly: true
- name: secret
  subPath: server_key.pem
  mountPath: /etc/ssl/server_key.pem
  readOnly: true
- name: secret
  subPath: ca_certificate.pem
  mountPath: /etc/ssl/ca_certificate.pem
  readOnly: true
{{- end }}
{{- if .Values.volumeMounts }}
{{ toYaml .Values.volumeMounts }}
{{- end }}
{{- end -}}