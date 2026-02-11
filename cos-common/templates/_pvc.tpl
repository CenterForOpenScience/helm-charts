{{/*
Render PersistentVolumeClaims (PVCs) for a component that opts into persistence.

This template supports:
- component-level persistence
- per-volume persistence blocks
- deduplication of PVCs with identical configs
- strict validation to avoid ambiguous or unsafe storage setups
*/}}
{{- define "cos-common.pvc" -}}

{{- /* Component values shortcut (safe default). */ -}}
{{- $vals := default dict .values -}}

{{- /* Component must exist and not be explicitly disabled. */ -}}
{{- $componentEnabled := eq (include "cos-common.componentEnabled" (dict "values" $vals) | trim | lower) "true" -}}

{{- if and $componentEnabled $vals }}

  {{- /* Collected list of persistence definitions (component + volumes). */ -}}
  {{- $persistences := list -}}

  {{- /* Component-level persistence shortcut. */ -}}
  {{- $componentPersistence := default dict $vals.persistence -}}

  {{- if default false $componentPersistence.enabled }}

    {{- /* 
    Primary persistence block:
    Applies when persistence.enabled=true directly on the component.
    volumeName is empty → represents the "default" volume.
    */ -}}
    {{- $persistences = concat $persistences
          (list (dict "persistence" $componentPersistence "volumeName" ""))
    -}}
  {{- end }}

  {{- /*
  Collect persistence blocks from:
  - volumes[]
  - additionalVolumes[]

  Both lists are supported to keep backward compatibility.
  */ -}}
  {{- $volumeSets := list
        (default (list) $vals.volumes)
        (default (list) $vals.additionalVolumes)
  -}}

  {{- range $volumeSets }}
    {{- range . }}

      {{- /* Volume-level persistence shortcut. */ -}}
      {{- $p := default dict .persistence -}}

      {{- if and $p (default false $p.enabled) }}

        {{- /* Volume name is mandatory when persistence is enabled. */ -}}
        {{- $volName := default "" .name -}}
        {{- if not $volName -}}
          {{- fail (printf
              "component %s volume requires name when persistence.enabled=true"
              $.name)
          -}}
        {{- end -}}

        {{- /* Persistent volumes cannot be emptyDir-backed. */ -}}
        {{- if hasKey . "emptyDir" -}}
          {{- fail (printf
              "component %s volume %s cannot use emptyDir when persistence.enabled=true"
              $.name $volName)
          -}}
        {{- end -}}

        {{- /* 
        Collect persistence blocks defined on volumes.
        These will later be deduplicated by claim name.
        */ -}}
        {{- $persistences = concat $persistences
              (list (dict "persistence" $p "volumeName" $volName))
        -}}

      {{- end -}}
    {{- end }}
  {{- end }}

  {{- /* Map of claimName → persistence spec (used for deduplication). */ -}}
  {{- $claims := dict -}}

  {{- /* Separate list to preserve deterministic render order. */ -}}
  {{- $claimOrder := list -}}

  {{- range $persistences }}

    {{- $pvc := default dict .persistence -}}

    {{- /* Only render PVCs that are enabled and not referencing existingClaim. */ -}}
    {{- if and (default false $pvc.enabled) (not $pvc.existingClaim) }}

      {{- /* Compute final PVC name (component + volume-aware). */ -}}
      {{- $claimName := include "cos-common.persistenceClaimName"
            (dict
              "root" $.root
              "name" $.name
              "values" $vals
              "persistence" $pvc
              "volumeName" .volumeName
            )
      -}}

      {{- if hasKey $claims $claimName }}

        {{- /* Same PVC name defined more than once → configs must match exactly. */ -}}
        {{- $existing := index $claims $claimName -}}
        {{- if ne (toYaml $existing.persistence) (toYaml $pvc) -}}
          {{- fail (printf
              "component %s defines persistence for claim %s more than once with conflicting options"
              $.name $claimName)
          -}}
        {{- end -}}

      {{- else -}}

        {{- /* Store claim spec and remember order for stable rendering. */ -}}
        {{- $_ := set $claims $claimName
              (dict "persistence" $pvc "volumeName" .volumeName)
        -}}
        {{- $claimOrder = concat $claimOrder (list $claimName) -}}

      {{- end -}}
    {{- end -}}
  {{- end }}

  {{- /* Render PVC manifests in deterministic order. */ -}}
  {{- range $claimOrder }}

    {{- $spec := index $claims . -}}
    {{- $pvc := $spec.persistence -}}
    {{- $volumeName := $spec.volumeName -}}

    {{- /* Merge component-level and PVC-specific labels. */ -}}
    {{- $labels := merge (dict)
          (default (dict) $vals.labels)
          (default (dict) $pvc.labels)
    -}}

    {{- /* Build annotations using shared helper logic. */ -}}
    {{- $annotations := include "cos-common.annotations"
          (dict "values" $vals "resource" $pvc.annotations)
          | fromJson
    -}}

    {{- /* accessModes are mandatory for new PVCs. */ -}}
    {{- $accessModes := default (list) $pvc.accessModes -}}
    {{- if eq (len $accessModes) 0 -}}
      {{- if $volumeName -}}
        {{- fail (printf
            "component %s volume %s persistence.accessModes must be set when persistence.enabled=true and no existingClaim"
            $.name $volumeName)
        -}}
      {{- else -}}
        {{- fail (printf
            "component %s.persistence.accessModes must be set when persistence.enabled=true"
            $.name)
        -}}
      {{- end -}}
    {{- end -}}

{{- printf "\n---\n" -}}
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  {{- /* Standardized metadata rendering (name, labels, annotations). */}}
  {{- include "cos-common.metadata"
      (dict
        "root" $.root
        "name" $.name
        "values" (dict
          "fullnameOverride" .
          "labels" $labels
          "annotations" $annotations
        )
      ) | nindent 2
  }}

spec:
  accessModes:
    {{- range $accessModes }}
    - {{ . | quote }}
    {{- end }}

  resources:
    {{- /* Allow full override of resource requests if provided. */ -}}
    {{- if $pvc.resources }}
    {{- tpl (toYaml $pvc.resources) $.root | nindent 4 }}
    {{- else }}
    requests:
      storage: {{ default "1Gi" $pvc.size | quote }}
    {{- end }}

  {{- /* Optional PVC attributes follow Kubernetes API exactly. */ -}}
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

{{- /* Ensure a trailing newline so concatenated includes remain valid YAML. */ -}}
{{- printf "\n" -}}

{{- end }}
{{- end }}
{{- end }}
