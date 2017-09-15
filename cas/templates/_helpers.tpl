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
Create a default fully qualified postgresql name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "postgresql.fullname" -}}
{{- printf "%s-%s" .Release.Name "postgresql" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Volumes
*/}}
{{- define "cas.volumes" }}
- name: config-volume
  configMap:
    name: {{ template "cas.fullname" . }}
- name: secret-volume
  secret:
    secretName: {{ template "cas.fullname" . }}
{{- end -}}

{{/*
Apache volume mounts
*/}}
{{- define "cas.apache.filemapConfig" }}
shibboleth/accesserror.html: /etc/shibboleth/accessError.html
shibboleth/attrchecker.html: /etc/shibboleth/attrChecker.html
shibboleth/attribute-map.xml: /etc/shibboleth/attribute-map.xml
shibboleth/attribute-policy.xml: /etc/shibboleth/attribute-policy.xml
shibboleth/bindingtemplate.html: /etc/shibboleth/bindingTemplate.html
shibboleth/console.logger: /etc/shibboleth/console.logger
shibboleth/discoverytemplate.html: /etc/shibboleth/discoveryTemplate.html
shibboleth/globallogout.html: /etc/shibboleth/globalLogout.html
shibboleth/locallogout.html: /etc/shibboleth/localLogout.html
shibboleth/metadataerror.html: /etc/shibboleth/metadataError.html
shibboleth/native.logger: /etc/shibboleth/native.logger
shibboleth/partiallogout.html: /etc/shibboleth/partialLogout.html
shibboleth/posttemplate.html: /etc/shibboleth/postTemplate.html
shibboleth/protocols.xml: /etc/shibboleth/protocols.xml
shibboleth/security-policy.xml: /etc/shibboleth/security-policy.xml
shibboleth/sessionerror.html: /etc/shibboleth/sessionError.html
shibboleth/shibboleth2.xml: /etc/shibboleth/shibboleth2.xml
shibboleth/shibd.logger: /etc/shibboleth/shibd.logger
shibboleth/sslerror.html: /etc/shibboleth/sslError.html
shibboleth/syslog.logger: /etc/shibboleth/syslog.logger
shibboleth/upgrade.xsl: /etc/shibboleth/upgrade.xsl
sites-enabled/default.conf: /etc/apache2/sites-enabled/default.conf
{{- end -}}
{{- define "cas.apache.filemapSecret" }}
shibboleth/incommon-idp-signature.pem: /etc/shibboleth/incommon-idp-signature.pem
shibboleth/sp-cert.pem: /etc/shibboleth/sp-cert.pem
shibboleth/sp-key.pem: /etc/shibboleth/sp-key.pem
{{- end -}}
{{- define "cas.apache.volumeMounts" }}
{{- range $key, $value := (include "cas.apache.filemapConfig" . | fromYaml) }}
- name: config-volume
  subPath: {{ $key | replace "/" "-" }}
  mountPath: {{ $value }}
  readOnly: true
{{- end -}}
{{- range $key, $value := (include "cas.apache.filemapSecret" . | fromYaml) }}
- name: secret-volume
  subPath: {{ $key | replace "/" "-" }}
  mountPath: {{ $value }}
  #readOnly: true
{{- end -}}
{{- end -}}

{{/*
Jetty volume mounts
*/}}
{{- define "cas.jetty.filemapConfig" }}
cas.properties: /code/etc/cas.properties
jetty/institutions-auth.xsl: /code/etc/institutions-auth.xsl
log4j2.xml: /code/etc/log4j2.xml
jetty/jetty-http.xml: /code/etc/jetty/jetty-http.xml
jetty/jetty-context.xml: /code/etc/jetty/jetty-context.xml
jetty/jetty.xml: /code/etc/jetty/jetty.xml
services/cas.json: /code/etc/services/cas.json
services/oauth2.json: /code/etc/services/oauth2.json
services/osf.json: /code/etc/services/osf.json
services/osf-campaigns-erpc.json: /code/etc/services/osf-campaigns-erpc.json
services/osf-campaigns-prereg.json: /code/etc/services/osf-campaigns-prereg.json
services/preprints-osf.json: /code/etc/services/preprints-osf.json
{{- range $key, $val := (include "cas.preprint-services" . | fromYaml) }}
{{- $filename := printf "services/preprints-%s.json" $key }}
{{ $filename }}: /code/etc/{{ $filename }}
{{- end -}}
{{- end -}}
{{- define "cas.jetty.volumeMounts" }}
{{- range $key, $value := (include "cas.jetty.filemapConfig" . | fromYaml) }}
- name: config-volume
  subPath: {{ $key | replace "/" "-" }}
  mountPath: {{ $value }}
  readOnly: true
{{- end -}}
{{- end -}}

{{/*
Jetty environment variables
*/}}
{{- define "cas.environment" }}
{{- if .Values.postgresql.enabled }}
- name: DATABASE_HOST
  value: {{ template "postgresql.fullname" . }}
- name: DATABASE_NAME
  value: {{ .Values.postgresql.postgresDatabase }}
- name: DATABASE_USER
  value: {{ .Values.postgresql.postgresUser }}
- name: DATABASE_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ template "postgresql.fullname" . }}
      key: postgres-password
{{- end }}
{{- $fullname := include "cas.fullname" . -}}
{{- range $key, $value := .Values.configEnvs }}
- name: {{ $key }}
  valueFrom:
    configMapKeyRef:
      name: {{ $fullname }}
      key: {{ $key }}
{{- end }}
{{- range $key, $value := .Values.secretEnvs }}
- name: {{ $key }}
  valueFrom:
    secretKeyRef:
      name: {{ $fullname }}
      key: {{ $key }}
{{- end }}
{{- end -}}
