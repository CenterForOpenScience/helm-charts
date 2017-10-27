{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "barman.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "barman.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "barman.initContainers" -}}
initContainers:
  {{- if .Values.tls.enabled }}
  - name: certificates
    image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
    imagePullPolicy: {{ .Values.image.pullPolicy }}
    command:
      - /bin/bash
      - -c
      - mkdir -p /var/lib/barman/.postgresql/ &&
          cp -f /certs/{postgresql,root}.* /var/lib/barman/.postgresql/ &&
          chown -R barman:barman /var/lib/barman/.postgresql &&
          chmod -R 0600 /var/lib/barman/.postgresql/*
    volumeMounts:
      - mountPath: /var/lib/barman
        name: data
        subPath: data
      - mountPath: /certs/root.crt
        name: secret
        subPath: certs-root.crt
        readOnly: true
      - mountPath: /certs/root.crl
        name: secret
        subPath: certs-root.crl
        readOnly: true
      - mountPath: /certs/postgresql.crt
        name: secret
        subPath: certs-postgresql.crt
        readOnly: true
      - mountPath: /certs/postgresql.key
        name: secret
        subPath: certs-postgresql.key
        readOnly: true
  {{- else }} []
  {{- end }}
{{- end -}}