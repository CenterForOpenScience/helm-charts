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

{{- define "osf.dbSettings" }}
- name: SENSITIVE_DATA_SALT
  valueFrom:
    secretKeyRef:
      name: {{ .Release.Name }}-secret
      key: sensitive-data-salt
- name: SENSITIVE_DATA_SECRET
  valueFrom:
    secretKeyRef:
      name: {{ .Release.Name }}-secret
      key: sensitive-data-secret
- name: OSF_DB_HOST
  value: {{ .Release.Name }}-postgresql
- name: OSF_DB_NAME
  value: {{ .Values.global.postgresDatabase | quote }}
- name: OSF_DB_USER
  value: {{ .Values.global.postgresUser | quote }}
- name: OSF_DB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ .Release.Name }}-postgresql
      key: postgres-password
{{- end -}}

{{- define "osf.volumes" }}
- name: admin-config-volume
  configMap:
    name: {{ .Release.Name }}-osf-admin  
- name: api-config-volume
  configMap:
    name: {{ .Release.Name }}-osf-api
- name: web-config-volume
  configMap:
    name: {{ .Release.Name }}-osf-web
{{- end -}}

{{- define "osf.volumeMounts" }}
- mountPath: /code/admin/base/settings/local.py
  name: admin-config-volume
  subPath: local.py
- mountPath: /code/api/base/settings/local.py
  name: api-config-volume
  subPath: local.py
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
