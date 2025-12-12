{{/* Render a CronJob for the component, reusing podSpec helpers and component enablement. */}}
{{- define "cos-common.cronjob" -}}
{{- $vals := default dict .values -}}
{{- $enabled := include "cos-common.componentEnabled" (dict "values" $vals) | fromYaml -}}
{{- if $enabled }}
{{- if not $vals.schedule }}
{{- fail (printf "component %s.schedule is required for cronjob" .name) }}
{{ end }}
{{- $jobTemplate := default dict $vals.jobTemplate -}}
{{- $jobTplLabels := default (dict) $jobTemplate.labels -}}
{{- $jobTplAnnotations := include "cos-common.annotations" (dict "values" $vals "resource" $jobTemplate.annotations "isWorkload" true) | fromJson -}}
{{- $fullnameOverride := $vals.fullnameOverride -}}
{{- $cronAnnotations := include "cos-common.annotations" (dict "values" $vals "isWorkload" true) | fromJson -}}
---
apiVersion: batch/v1
kind: CronJob
metadata:
  {{- include "cos-common.metadata" (dict "root" .root "name" .name "values" (dict "fullnameOverride" $fullnameOverride "labels" $vals.labels "annotations" $cronAnnotations)) | nindent 2 }}
spec:
  {{- /* Required schedule drives how often the jobTemplate runs. */}}
  schedule: {{ quote $vals.schedule }}
  {{- with $vals.timeZone }}
  timeZone: {{ . }}
  {{ end }}
  {{- with $vals.concurrencyPolicy }}
  concurrencyPolicy: {{ . }}
  {{ end }}
  {{- with $vals.suspend }}
  suspend: {{ . }}
  {{ end }}
  {{- with $vals.startingDeadlineSeconds }}
  startingDeadlineSeconds: {{ . }}
  {{ end }}
  {{- with $vals.successfulJobsHistoryLimit }}
  successfulJobsHistoryLimit: {{ . }}
  {{ end }}
  {{- with $vals.failedJobsHistoryLimit }}
  failedJobsHistoryLimit: {{ . }}
  {{ end }}
  jobTemplate:
    metadata:
      labels:
        {{- include "cos-common.labels" . | nindent 8 }}
        {{- if gt (len $jobTplLabels) 0 }}
        {{ tpl (toYaml $jobTplLabels) $.root | nindent 8 }}
        {{ end }}
      {{- if gt (len $jobTplAnnotations) 0 }}
      annotations:
        {{ tpl (toYaml $jobTplAnnotations) $.root | nindent 8 }}
      {{ end }}
    spec:
      {{- /* Reuse the same jobSpec helper so one-off Job and CronJob pods stay aligned. */}}
      {{- include "cos-common.jobSpec" (dict "root" .root "name" .name "values" $vals "suspend" $vals.jobSuspend) | nindent 6 }}
{{ end }}
{{ end }}
