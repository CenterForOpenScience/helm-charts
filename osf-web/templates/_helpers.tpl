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
Overridable OSF deployment annotations
*/}}
{{- define "osf.deploymentAnnotations" }}
checksum/secrets: {{ include (print $.Template.BasePath "/secrets.yaml") . | sha256sum }}
{{- end -}}

{{/*
Overridable OSF database settings
*/}}
{{- define "osf.dbSettings" }}
{{- $fullname := (include "fullname" .) -}}
{{- range tuple "SENSITIVE_DATA_SALT" "SENSITIVE_DATA_SECRET" "OSF_DB_HOST" "OSF_DB_NAME" "OSF_DB_USER" "OSF_DB_PASSWORD" }}
- name: {{ . }}
  valueFrom:
    secretKeyRef:
      name: {{ $fullname }}
      key: {{ . }}
{{- end -}}
{{- end -}}

{{/*
Overridable OSF volumes
*/}}
{{- define "osf.volumes" }}
- name: secret-volume
  secret:
    secretName: {{ template "fullname" . }}
{{- end -}}

{{/*
Overridable OSF volume mounts
*/}}
{{- define "filemap" }}
admin-local.py: /code/admin/base/settings/local.py
api-local.py: /code/api/base/settings/local.py
web-local.py: /code/website/settings/local.py
addons-bitbucket-local.py: /code/addons/bitbucket/settings/local.py
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

{{- define "osf-ember-preprints.fullname" -}}
{{ .Values.preprintsDomain }}
{{- end -}}

{{- define "osf-ember-registries.fullname" -}}
{{ .Values.registriesDomain }}
{{- end -}}
