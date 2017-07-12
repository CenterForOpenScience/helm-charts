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
Overridable OSF database settings
*/}}
{{- define "osf.dbSettings" }}
- name: SENSITIVE_DATA_SALT
  valueFrom:
    secretKeyRef:
      key: sensitive-data-salt
      name: {{ .Values.osfSecretName }}
- name: SENSITIVE_DATA_SECRET
  valueFrom:
    secretKeyRef:
      key: sensitive-data-secret
      name: {{ .Values.osfSecretName }}
- name: OSF_DB_HOST
  value: {{ .Values.postgresHost }}
- name: OSF_DB_NAME
  value: {{ .Values.postgresDatabase }}
- name: OSF_DB_USER
  value: {{ .Values.postgresUser }}
- name: OSF_DB_PASSWORD
  valueFrom:
    secretKeyRef:
      key: postgres-password
      name: {{ .Values.postgresSecret }}
{{- end -}}

{{/*
Overridable OSF volume mounts
*/}}
{{- define "osf.volumeMounts" }}
- mountPath: /code/website/settings/local.py
  name: web-config-volume
  subPath: local.py
- mountPath: /code/addons/box/settings/local.py
  name: web-config-volume
  subPath: addons-box-local.py
- mountPath: /code/addons/dataverse/settings/local.py
  name: web-config-volume
  subPath: addons-dataverse-local.py
- mountPath: /code/addons/dropbox/settings/local.py
  name: web-config-volume
  subPath: addons-dropbox-local.py
- mountPath: /code/addons/figshare/settings/local.py
  name: web-config-volume
  subPath: addons-figshare-local.py
- mountPath: /code/addons/github/settings/local.py
  name: web-config-volume
  subPath: addons-github-local.py
- mountPath: /code/addons/googledrive/settings/local.py
  name: web-config-volume
  subPath: addons-googledrive-local.py
- mountPath: /code/addons/mendeley/settings/local.py
  name: web-config-volume
  subPath: addons-mendeley-local.py
- mountPath: /code/addons/osfstorage/settings/local.py
  name: web-config-volume
  subPath: addons-osfstorage-local.py
- mountPath: /code/addons/wiki/settings/local.py
  name: web-config-volume
  subPath: addons-wiki-local.py
- mountPath: /code/addons/zotero/settings/local.py
  name: web-config-volume
  subPath: addons-zotero-local.py
{{- end -}}

{{/*
Overridable OSF volumes
*/}}
{{- define "osf.volumes" }}
- name: web-config-volume
  configMap:
    name: {{ template "fullname" . }}
{{- end -}}