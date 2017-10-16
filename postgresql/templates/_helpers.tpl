{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "postgresql.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "postgresql.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified master name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "postgresql.master.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s-%s" .Release.Name $name .Values.master.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified standby name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "postgresql.standby.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s-%s" .Release.Name $name .Values.standby.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Return the appropriate apiVersion for networkpolicy.
*/}}
{{- define "postgresql.networkPolicy.apiVersion" -}}
{{- if and (ge .Capabilities.KubeVersion.Minor "4") (le .Capabilities.KubeVersion.Minor "6") -}}
"extensions/v1beta1"
{{- else if ge .Capabilities.KubeVersion.Minor "7" -}}
"networking.k8s.io/v1"
{{- end -}}
{{- end -}}

{{- define "postgresql.environment" }}
- name: PGDATA
  value: /var/lib/postgresql/data/pgdata
- name: MASTER_SERVICE
  value: {{ template "postgresql.master.fullname" . }}
# - name: STANDBY_SERVICE
#   value: {{ template "postgresql.standby.fullname" . }}
- name: POD_NAME
  valueFrom:
    fieldRef:
      fieldPath: metadata.name
- name: POD_IP
  valueFrom:
    fieldRef:
      fieldPath: status.podIP
{{- if .Values.tls.enabled }}
- name: PGSSLMODE
  value: verify-ca
- name: PGSSLCERT
  value: /etc/ssl/certs/client_certificate.pem
- name: PGSSLKEY
  value: /etc/ssl/private/client_key.pem
- name: PGSSLROOTCERT
  value: /etc/ssl/certs/ca_certificate.pem
- name: PGSSLCRL
  value: /etc/ssl/crl/ca_crl.pem
{{- end }}
{{- $fullname := (include "postgresql.fullname" .) -}}
{{- range tuple "POSTGRES_DB" "POSTGRES_USER" "POSTGRES_PASSWORD" "POSTGRES_INITDB_ARGS" "REPMGR_PASSWORD" }}
- name: {{ . }}
  valueFrom:
    secretKeyRef:
      name: {{ $fullname }}
      key: {{ . }}
{{- end }}
- name: PGUSER
  valueFrom:
    secretKeyRef:
      name: {{ $fullname }}
      key: POSTGRES_USER
{{- end -}}

{{- define "postgresql.volumes" }}
- name: config-volume
  configMap:
    name: {{ template "postgresql.fullname" . }}
- name: secret-volume
  secret:
    secretName: {{ template "postgresql.fullname" . }}
{{- if and .Values.metrics.enabled .Values.metrics.customMetrics }}
- name: custom-metrics
  secret:
    secretName: {{ template "postgresql.fullname" . }}
    items:
      - key: custom-metrics.yaml
        path: custom-metrics.yaml
{{- end }}
{{- end -}}

{{- define "postgresql.volumeMounts" }}
- name: data
  mountPath: /var/lib/postgresql/data
  subPath: pgdata
- name: config-volume
  mountPath: /etc/repmgr.conf.tpl
  subPath: repmgr.conf
- name: config-volume
  mountPath: /etc/supervisor/conf.d/supervisord.conf
  subPath: supervisord.conf
  readOnly: true
- name: config-volume
  mountPath: /usr/local/bin/entrypoint.sh
  subPath: entrypoint.sh
{{- if .Values.tls.enabled }}
- name: secret-volume
  mountPath: /etc/ssl/certs/server_certificate.pem
  subPath: server_certificate.pem
- name: secret-volume
  mountPath: /etc/ssl/private/server_key.pem
  subPath: server_key.pem
- name: secret-volume
  mountPath: /etc/ssl/certs/client_certificate.pem
  subPath: client_certificate.pem
- name: secret-volume
  mountPath: /etc/ssl/private/client_key.pem
  subPath: client_key.pem
- name: secret-volume
  mountPath: /etc/ssl/certs/ca_certificate.pem
  subPath: ca_certificate.pem
- name: secret-volume
  mountPath: /etc/ssl/crl/ca_crl.pem
  subPath: ca_crl.pem
{{- end }}
{{- end }}