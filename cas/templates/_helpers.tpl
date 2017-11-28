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
{{- define "cas.volumes" -}}
- name: services
  emptyDir: {}
- name: config
  configMap:
    name: {{ template "cas.fullname" . }}
- name: secret
  secret:
    secretName: {{ template "cas.fullname" . }}
{{- if .Values.tls.enabled }}
- name: certs
  emptyDir: {}
{{- end }}
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
{{- define "cas.apache.volumeMounts" -}}
{{- range $key, $value := (include "cas.apache.filemapConfig" . | fromYaml) }}
- name: config
  subPath: {{ $key | replace "/" "-" }}
  mountPath: {{ $value }}
  readOnly: true
{{- end -}}
{{- range $key, $value := (include "cas.apache.filemapSecret" . | fromYaml) }}
- name: secret
  subPath: {{ $key | replace "/" "-" }}
  mountPath: {{ $value }}
  #readOnly: true
{{- end -}}
{{- end -}}

{{/*
Jetty volume mounts
*/}}
{{- define "cas.jetty.filemapConfig" }}
cas.properties: /etc/cas/cas.properties
institutions-auth.xsl: /etc/cas/institutions-auth.xsl
log4j2.xml: /etc/cas/log4j2.xml
services/cas.json: /etc/cas/services/cas.json
services/oauth2.json: /etc/cas/services/oauth2.json
services/osf.json: /etc/cas/services/osf.json
services/osf-campaigns-erpc.json: /etc/cas/services/osf-campaigns-erpc.json
services/osf-campaigns-prereg.json: /etc/cas/services/osf-campaigns-prereg.json
services/preprints-osf.json: /etc/cas/services/preprints-osf.json
{{- range $key, $val := (include "cas.preprint-services" . | fromYaml) }}
{{- $filename := printf "services/preprints-%s.json" $key }}
{{ $filename }}: /etc/cas/{{ $filename }}
{{- end -}}
{{- end -}}
{{- define "cas.jetty.volumeMounts" -}}
- mountPath: /etc/cas/services
  name: services
{{- range $key, $value := (include "cas.jetty.filemapConfig" . | fromYaml) }}
- name: config
  subPath: {{ $key | replace "/" "-" }}
  mountPath: {{ $value }}
  readOnly: true
{{- end -}}
{{- if .Values.tls.enabled }}
- mountPath: /home/jetty/.postgresql
  name: certs
{{- end }}
{{- end -}}

{{/*
Jetty environment variables
*/}}
{{- define "cas.environment" -}}
- name: SESSION_SECURE_COOKIES
  value: "true"
{{- if .Values.postgresql.enabled }}
- name: DATABASE_URL
  value: jdbc:postgresql://{{ template "postgresql.fullname" . }}/{{ .Values.postgresql.postgresDatabase }}?targetServerType=master
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
