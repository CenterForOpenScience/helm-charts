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
Overridable OSF volume mounts
*/}}
{{- define "osf.volumeMounts" }}
- mountPath: /code/website/settings/local.py
  name: web-secret-volume
  subPath: website-local.py
  readOnly: true
- mountPath: /code/addons/box/settings/local.py
  name: web-secret-volume
  subPath: addons-box-local.py
  readOnly: true
- mountPath: /code/addons/dataverse/settings/local.py
  name: web-secret-volume
  subPath: addons-dataverse-local.py
  readOnly: true
- mountPath: /code/addons/dropbox/settings/local.py
  name: web-secret-volume
  subPath: addons-dropbox-local.py
  readOnly: true
- mountPath: /code/addons/figshare/settings/local.py
  name: web-secret-volume
  subPath: addons-figshare-local.py
  readOnly: true
- mountPath: /code/addons/github/settings/local.py
  name: web-secret-volume
  subPath: addons-github-local.py
  readOnly: true
- mountPath: /code/addons/googledrive/settings/local.py
  name: web-secret-volume
  subPath: addons-googledrive-local.py
  readOnly: true
- mountPath: /code/addons/mendeley/settings/local.py
  name: web-secret-volume
  subPath: addons-mendeley-local.py
  readOnly: true
- mountPath: /code/addons/osfstorage/settings/local.py
  name: web-secret-volume
  subPath: addons-osfstorage-local.py
  readOnly: true
- mountPath: /code/addons/wiki/settings/local.py
  name: web-secret-volume
  subPath: addons-wiki-local.py
  readOnly: true
- mountPath: /code/addons/zotero/settings/local.py
  name: web-secret-volume
  subPath: addons-zotero-local.py
  readOnly: true
{{- end -}}

{{/*
Overridable OSF volumes
*/}}
{{- define "osf.volumes" }}
- name: web-secret-volume
  secret:
    secretName: {{ template "fullname" . }}-{{ .Release.Time.Seconds }}
{{- end -}}