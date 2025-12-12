{{/* Render a PersistentVolumeClaim for components that opt in. */}}
{{- define "cos-common.pvc" -}}
{{- $vals := default dict .values -}}
{{- $componentEnabled := include "cos-common.componentEnabled" (dict "values" $vals) | fromYaml -}}
{{- if and $componentEnabled $vals }}
  {{- $persistences := list -}}
  {{- $componentPersistence := default dict $vals.persistence -}}
  {{- if default false $componentPersistence.enabled }}
    {{- /* Primary persistence block applies when persistence.enabled=true at component root. */}}
    {{- $persistences = concat $persistences (list (dict "persistence" $componentPersistence "volumeName" "")) -}}
  {{- end }}

  {{- $volumeSets := list (default (list) $vals.volumes) (default (list) $vals.additionalVolumes) -}}
  {{- range $volumeSets }}
    {{- range . }}
      {{- $p := default dict .persistence -}}
      {{- if and $p (default false $p.enabled) }}
        {{- $volName := default "" .name -}}
        {{- if not $volName -}}
          {{- fail (printf "component %s volume requires name when persistence.enabled=true" $.name) -}}
        {{- end -}}
        {{- if hasKey . "emptyDir" -}}
          {{- fail (printf "component %s volume %s cannot use emptyDir when persistence.enabled=true" $.name $volName) -}}
        {{- end -}}
        {{- /* Collect persistence blocks from volume definitions as well. */}}
        {{- $persistences = concat $persistences (list (dict "persistence" $p "volumeName" $volName)) -}}
      {{- end -}}
    {{- end }}
  {{- end }}

  {{- $claims := dict -}}
  {{- $claimOrder := list -}}
  {{- range $persistences }}
    {{- $pvc := default dict .persistence -}}
    {{- if and (default false $pvc.enabled) (not $pvc.existingClaim) }}
      {{- $claimName := include "cos-common.persistenceClaimName" (dict "root" $.root "name" $.name "values" $vals "persistence" $pvc "volumeName" .volumeName) -}}
      {{- if hasKey $claims $claimName -}}
        {{- $existing := index $claims $claimName -}}
        {{- if ne (toYaml $existing.persistence) (toYaml $pvc) -}}
          {{- fail (printf "component %s defines persistence for claim %s more than once with conflicting options" $.name $claimName) -}}
        {{- end -}}
      {{- else -}}
        {{- /* Remember order to keep rendered manifests deterministic. */}}
        {{- $_ := set $claims $claimName (dict "persistence" $pvc "volumeName" .volumeName) -}}
        {{- $claimOrder = concat $claimOrder (list $claimName) -}}
      {{- end -}}
    {{- end -}}
  {{- end }}

  {{- range $claimOrder }}
    {{- $spec := index $claims . -}}
    {{- $pvc := $spec.persistence -}}
    {{- $volumeName := $spec.volumeName -}}
    {{- $labels := merge (dict) (default (dict) $vals.labels) (default (dict) $pvc.labels) -}}
    {{- $annotations := include "cos-common.annotations" (dict "values" $vals "resource" $pvc.annotations) | fromJson -}}
    {{- $accessModes := default (list) $pvc.accessModes -}}
    {{- if eq (len $accessModes) 0 -}}
      {{- if $volumeName -}}
        {{- fail (printf "component %s volume %s persistence.accessModes must be set when persistence.enabled=true and no existingClaim" $.name $volumeName) -}}
      {{- else -}}
        {{- fail (printf "component %s.persistence.accessModes must be set when persistence.enabled=true" $.name) -}}
      {{- end -}}
    {{- end -}}
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  {{- include "cos-common.metadata"
      (dict "root" $.root "name" $.name "values"
        (dict "fullnameOverride" . "labels" $labels "annotations" $annotations)
      ) | nindent 2
  }}
spec:
  accessModes:
    {{- range $accessModes }}
    - {{ . | quote }}
    {{- end }}
  resources:
    {{- if $pvc.resources }}
    {{- tpl (toYaml $pvc.resources) $.root | nindent 4 }}
    {{- else }}
    requests:
      storage: {{ default "1Gi" $pvc.size | quote }}
    {{- end }}
  {{- with $pvc.storageClass }}
  storageClassName: {{ . | quote }}
  {{- end }}
  {{- with $pvc.volumeMode }}
  volumeMode: {{ . }}
  {{- end }}
  {{- with $pvc.volumeName }}
  volumeName: {{ . | quote }}
  {{- end }}
  {{- with $pvc.selector }}
  selector:
{{ tpl (toYaml .) $.root | nindent 4 }}
  {{- end }}
  {{- with $pvc.dataSource }}
  dataSource:
{{ tpl (toYaml .) $.root | nindent 4 }}
  {{- end }}
  {{- with $pvc.dataSourceRef }}
  dataSourceRef:
{{ tpl (toYaml .) $.root | nindent 4 }}
  {{- end }}
  {{- with $pvc.volumeAttributesClassName }}
  volumeAttributesClassName: {{ . | quote }}
  {{- end }}
{{- end }}
{{- end }}
{{- end }}
