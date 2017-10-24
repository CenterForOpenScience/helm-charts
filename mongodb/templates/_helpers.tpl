{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "mongodb.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "mongodb.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "mongodb.environment" -}}
{{- $fullname := (include "mongodb.fullname" .) -}}
{{- range $key := keys .Values.secretEnvs }}
- name: {{ $key }}
  valueFrom:
    secretKeyRef:
      name: {{ $fullname }}
      key: {{ $key }}
{{- end }}
{{- range $key := keys .Values.configEnvs }}
- name: {{ $key }}
  valueFrom:
    configMapKeyRef:
      name: {{ $fullname }}
      key: {{ $key }}
{{- end }}
{{- end -}}

{{- define "mongodb.probeExec" -}}
exec:
  command:
    - gosu
    - mongodb
    - mongo
    {{- if .Values.tls.enabled }}
    - --ssl
    - --sslAllowInvalidHostnames
    - --sslCAFile=/etc/ssl/ca.pem
    - --sslCRLFile=/etc/ssl/ca-crl.pem
    - --sslPEMKeyFile=/etc/ssl/client.pem
    {{- end }}
    - --eval
    - "db.adminCommand('ping')"
{{- end -}}

{{- define "mongodb.volumes" -}}
- name: config
  configMap:
    name: {{ template "mongodb.fullname" . }}
- name: secret
  secret:
    secretName: {{ template "mongodb.fullname" . }}
{{- if .Values.tls.enabled }}
- name: certificates
  emptyDir: {}
{{- end }}
{{- if not .Values.persistence.enabled }}
- name: data
  emptyDir: {}
{{- end }}
{{- end -}}

{{- define "mongodb.volumeMounts" -}}
- name: data
  mountPath: /data/db
{{- if .Values.tls.enabled }}
- name: certificates
  mountPath: /etc/ssl
{{- end }}
{{- end -}}
