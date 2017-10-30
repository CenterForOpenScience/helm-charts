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
      - /bin/sh
      - -c
      - export dir=/var/lib/barman/.postgresql && 
        mkdir -p ${dir} && 
        cp -f /certs/.* ${dir} && 
        chown -R barman:barman ${dir} && 
        chmod -R 0600 ${dir}/*
    volumeMounts:
      - mountPath: /var/lib/barman
        name: data
        subPath: data
      {{- range $key := keys .Values.tls.files }}
      - mountPath: /certs/{{ $key }}
        name: secret
        subPath: certs-{{ $key }}
        readOnly: true
      {{- end }}
  {{- else }} []
  {{- end }}
{{- end -}}