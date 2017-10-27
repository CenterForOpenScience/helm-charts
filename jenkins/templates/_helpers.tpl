{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "jenkins.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "jenkins.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified agent name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "jenkins.agent.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s-%s" .Release.Name $name .Values.agent.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/* CUSTOM START */}}
{{/*
InitContainers
*/}}
{{- define "jenkins.master.initContainers" -}}
initContainers:
  - name: copy-default-config
    image: "{{ .Values.master.image.repository }}:{{ .Values.master.image.tag }}"
    imagePullPolicy: {{ .Values.master.image.pullPolicy }}
    command:
      - sh
      - /var/jenkins_config/apply_config.sh
    volumeMounts:
      - name: config-volume
        mountPath: /var/jenkins_config
      - name: persistent-storage
        mountPath: /var/jenkins_home
      - name: plugins-volume
        mountPath: /usr/share/jenkins/ref/plugins/
      - name: secrets-volume
        mountPath: /usr/share/jenkins/ref/secrets/
{{- end -}}
{{/* */}}