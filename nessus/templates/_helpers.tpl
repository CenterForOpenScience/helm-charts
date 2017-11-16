{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "nessus.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "nessus.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "nessus.initContainers" -}}
initContainers:
  {{- if .Values.tls.enabled }}
  - name: certificates
    image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
    imagePullPolicy: {{ .Values.image.pullPolicy }}
    command:
      - /bin/sh
      - -c
      - export dir=/opt/nessus/var/nessus/CA && 
        mkdir -p ${dir} &&
        cp -f /certs/* ${dir} &&
        chown -R root:root ${dir} &&
        chmod -R 0400 ${dir}/*
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