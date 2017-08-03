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
Create a default fully qualified postgresql name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "postgresql.fullname" -}}
{{- printf "%s-%s" .Release.Name "postgresql" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Volumes
*/}}
{{- define "volumes" }}
- name: config-volume
  configMap:
    name: {{ template "fullname" . }}
- name: secret-volume
  secret:
    secretName: {{ template "fullname" . }}
{{- end -}}

{{/*
Apache volume mounts
*/}}
{{- define "apacheFilemapConfig" }}
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
{{- define "apacheFilemapSecret" }}
shibboleth/incommon-idp-signature.pem: /etc/shibboleth/incommon-idp-signature.pem
shibboleth/sp-cert.pem: /etc/shibboleth/sp-cert.pem
shibboleth/sp-key.pem: /etc/shibboleth/sp-key.pem
{{- end -}}
{{- define "apacheVolumeMounts" }}
{{- range $key, $value := (include "apacheFilemapConfig" . | fromYaml) }}
- name: config-volume
  subPath: {{ $key | replace "/" "-" }}
  mountPath: {{ $value }}
  readOnly: true
{{- end -}}
{{- range $key, $value := (include "apacheFilemapSecret" . | fromYaml) }}
- name: secret-volume
  subPath: {{ $key | replace "/" "-" }}
  mountPath: {{ $value }}
  #readOnly: true
{{- end -}}
{{- end -}}

{{/*
Jetty volume mounts
*/}}
{{- define "jettyFilemapConfig" }}
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
services/preprints-engrxiv.json: /code/etc/services/preprints-engrxiv.json
services/preprints-osf.json: /code/etc/services/preprints-osf.json
services/preprints-psyarxiv.json: /code/etc/services/preprints-psyarxiv.json
services/preprints-socarxiv.json: /code/etc/services/preprints-socarxiv.json
{{- end -}}
{{- define "jettyVolumeMounts" }}
{{- range $key, $value := (include "jettyFilemapConfig" . | fromYaml) }}
- name: config-volume
  subPath: {{ $key | replace "/" "-" }}
  mountPath: {{ $value }}
  readOnly: true
{{- end -}}
{{- end -}}

{{/*
Jetty environment variables
*/}}
{{- define "jettyVarsSecret" }}
vars:
- OAUTH_ORCID_CLIENT_ID
- OAUTH_ORCID_CLIENT_SECRET
- OSF_DB_URL
- OSF_DB_USER
- OSF_DB_PASSWORD
- OSF_JWE_SECRET
- OSF_JWT_SECRET
- TGC_ENCRYPTION_KEY
- TGC_SIGNING_KEY
{{- end }}
{{- define "jettyEnv" }}
- name: DATABASE_NAME
  value: {{ .Values.postgresql.postgresDatabase }}
- name: DATABASE_USER
  value: {{ .Values.postgresql.postgresUser }}
- name: DATABASE_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ template "postgresql.fullname" . }}
      key: postgres-password
{{- $fullname := (include "fullname" .) -}}
{{- range (include "jettyVarsSecret" . | fromYaml).vars }}
- name: {{ . }}
  valueFrom:
    secretKeyRef:
      name: {{ $fullname }}
      key: {{ . }}
{{- end }}
{{- end -}}
