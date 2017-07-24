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
Create a default fully qualified osf name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "osf.fullname" -}}
{{- printf "%s-%s" .Release.Name "osf" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified postgresql name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "postgresql.fullname" -}}
{{- printf "%s-%s" .Release.Name "postgresql" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified rabbitmq name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "rabbitmq.fullname" -}}
{{- printf "%s-%s" .Release.Name "rabbitmq" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Overridable OSF deployment annotations
*/}}
{{- define "osf.deploymentAnnotations" }}
checksum/secrets: {{ include (print $.Template.BasePath "/secrets.yaml") . | sha256sum }}
{{- end -}}

{{/*
Overridable OSF database settings
*/}}
{{- define "osf.dbSettings" }}
- name: SENSITIVE_DATA_SALT
  valueFrom:
    secretKeyRef:
      name: {{ template "osf.fullname" . }}
      key: SENSITIVE_DATA_SALT
- name: SENSITIVE_DATA_SECRET
  valueFrom:
    secretKeyRef:
      name: {{ template "osf.fullname" . }}
      key: SENSITIVE_DATA_SECRET
- name: OSF_DB_HOST
  value: {{ template "postgresql.fullname" . }}
- name: OSF_DB_NAME
  value: {{ .Values.global.postgresDatabase | quote }}
- name: OSF_DB_USER
  value: {{ .Values.global.postgresUser | quote }}
- name: OSF_DB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ template "postgresql.fullname" . }}
      key: postgres-password
- name: RABBITMQ_URL
  value: amqp://{{ template "rabbitmq.fullname" . }}:5672
{{- end -}}

{{/*
Overridable OSF volumes
*/}}
{{- define "osf.volumes" }}
- name: secret-volume
  secret:
    secretName: {{ template "osf.fullname" . }}
{{- end -}}

{{/*
Overridable OSF volume mounts
*/}}
{{- define "filemap" }}
admin-local.py: /code/admin/base/settings/local.py
api-local.py: /code/api/base/settings/local.py
web-local.py: /code/website/settings/local.py
addons-box-local.py: /code/addons/box/settings/local.py
addons-dataverse-local.py: /code/addons/dataverse/settings/local.py
addons-dropbox-local.py: /code/addons/dropbox/settings/local.py
addons-figshare-local.py: /code/addons/figshare/settings/local.py
addons-github-local.py: /code/addons/github/settings/local.py
addons-googledrive-local.py: /code/addons/googledrive/settings/local.py
addons-mendeley-local.py: /code/addons/mendeley/settings/local.py
addons-osfstorage-local.py: /code/addons/osfstorage/settings/local.py
addons-wiki-local.py: /code/addons/wiki/settings/local.py
addons-zotero-local.py: /code/addons/zotero/settings/local.py
{{- end -}}
{{- define "osf.volumeMounts" }}
{{- range $key, $value := (include "filemap" . | fromYaml) }}
- name: secret-volume
  subPath: {{ $key }}
  mountPath: {{ $value }}
  readOnly: true
{{- end -}}
{{- end -}}
