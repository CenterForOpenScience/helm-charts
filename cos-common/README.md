cos-common
==========

Reusable Helm **library** chart that bundles the common building blocks used by Center for Open Science application charts. You do **not** install it on its own; instead, your application chart imports it and renders the pieces you need (workloads, traffic, config, secrets, network policy, certs, etc.).

Helm: v3 (library chart). Kubernetes: `>=1.32` (see `Chart.yaml`).

## Contents
- Workloads: `deployment`, `statefulset`, `job`, `cronjob`
- Traffic: `service`, `ingress`
- Ops: `hpa`, `pdb`, `networkpolicy`
- Config: `configmap`, `secret` (auto base64, optional TLS merge), cert-manager `certificate`
- Helpers: naming/labels, pod spec builder (env, probes, volumes, init/sidecars, pod options), tpl-aware map/list rendering, checksum helper

## Adding the dependency
In your application `Chart.yaml`:

```yaml
apiVersion: v2
name: my-app
version: 0.1.0
dependencies:
  - name: cos-common
    version: 0.1.0
    repository: "file://../cos-common"
  # OR as a package
  - name: cos-common
    version: 0.1.0
    repository: https://centerforopenscience.github.io/helm-charts/
```

Run `helm dependency update` so the library is available during rendering.

## How to use the templates
Call the templates you need from your chart under `templates/`. Each include takes:
- `root`: the parent Helm context (usually `.`)
- `name`: component name (used for naming/labels)
- `values`: the component values block

```yaml
# templates/app.yaml
{{- include "cos-common.configmap"   (dict "root" . "name" "app" "values" .Values.app) }}
{{- include "cos-common.secret"      (dict "root" . "name" "app" "values" .Values.app) }}
{{- include "cos-common.deployment"  (dict "root" . "name" "app" "values" .Values.app) }}
{{- include "cos-common.service"     (dict "root" . "name" "app" "values" .Values.app) }}
{{- include "cos-common.ingress"     (dict "root" . "name" "app" "values" .Values.app) }}
{{- include "cos-common.hpa"         (dict "root" . "name" "app" "values" .Values.app) }}
{{- include "cos-common.pdb"         (dict "root" . "name" "app" "values" .Values.app) }}
{{- include "cos-common.pvc"         (dict "root" . "name" "app" "values" .Values.app) }}
{{- include "cos-common.certificate" (dict "root" . "name" "app" "values" .Values.app) }}
```

Use `cos-common.statefulset`, `cos-common.job`, or `cos-common.cronjob` the same way when you need those workload types.

## Template reference (what each tpl renders)
- `cos-common.deployment`: Deployment with component labels/selectors, strategy, replicas, pod template built from component values.
- `cos-common.statefulset`: StatefulSet with serviceName, update/retention policies, volumeClaimTemplates, pod template.
- `cos-common.job`: Batch Job with parallelism/completions/backoff, pod template.
- `cos-common.cronjob`: CronJob with required `schedule`, job history limits, job spec/pod template (shares the same job spec fields as `cos-common.job`).
- `cos-common.service`: Service with type/ports, optional LB fields, selector wired to component labels.
- `cos-common.ingress`: Ingress with hosts+paths or defaultBackend, TLS, ingressClassName; backend defaults to the component service and can shift to a maintenance service when `.Values.maintenance.enabled` is true.
- `cos-common.hpa`: HorizontalPodAutoscaler pointing to the component deployment/statefulset; requires min/max/metrics when enabled.
- `cos-common.pdb`: PodDisruptionBudget with minAvailable or maxUnavailable.
- `cos-common.pvc`: PersistentVolumeClaims when `persistence.enabled` (component-level) or `volumes[].persistence.enabled`; auto-skips `existingClaim`; supports size/class/selector and spec overrides.
- `cos-common.networkpolicy`: NetworkPolicy defaulting to namespace-local ingress allow; optional egress and extra ingress/egress rules; supports additional named policies.
- `cos-common.configmap`: Main ConfigMap (tpl-aware) plus `additionalConfigMaps[]`.
- `cos-common.secret`: Main Secret (auto base64, optional tls merge, accepts pre-encoded `base64Files`) plus `additionalSecrets[]`.
- `cos-common.certificate`: cert-manager Certificate from `certificate` block plus `additionalCertificates[]`.
- Helpers: `cos-common.componentChecksum` to hash rendered resources; label/name helpers; pod spec builder for containers/init/sidecars/volumes, etc.

## Values layout and expectations
Define one top-level block per component (`app`, `worker`, `migration`, etc.). A minimal workload needs an `image.repository`; everything else is optional/opt-in. `.Values.global` is intentionally open: put shared settings there (URLs, credentials, defaults) and reference them from components; nothing renders from `global` automatically.

```yaml
global:
  dbPassword: superpass

app:
  image:
    repository: ghcr.io/example/app
    tag: v1.2.3
  replicas: 2
  ports:
    - name: http
      containerPort: 8080
  service:
    enabled: true
    ports:
      - port: 80
        targetPort: http
  ingress:
    enabled: true
    hosts:
      - host: example.org
        paths:
          - path: /
            pathType: Prefix
            port: http
  hpa:
    enabled: true
    minReplicas: 2
    maxReplicas: 5
    metrics:
      - type: Resource
        resource:
          name: cpu
          target:
            type: Utilization
            averageUtilization: 75
  pdb:
    enabled: true
    minAvailable: 1
  networkPolicy:
    enabled: true
    allowEgress: true
  configMap:
    enabled: true
    tpl: true
    data:
      APP_MODE: production
  secret:
    enabled: true
    data:
      password: "{{ .Values.global.dbPassword }}"
  certificate:
    enabled: true
    issuerRef:
      name: letsencrypt-prod
      kind: ClusterIssuer
    dnsNames: [example.org]
```

### Notable behaviors
- **Enablement**: `enabled: false` on the component skips all its resources. Most sub-blocks (`service`, `ingress`, `hpa`, `pdb`, etc.) also have their own `enabled` flag.
- **Naming/labels**: standard Helm labels are applied; `fullnameOverride` works at both component and sub-resource level. Names are trimmed to 63 chars.
- **ConfigMap**: `tpl: true` renders `.data` through Helm’s engine. `additionalConfigMaps[]` lets you emit extra ConfigMaps without new templates.
- **Secret**: `.data` is auto base64’d. `includeTls: true` can merge TLS files from `.Values.tls.*.files`. `additionalSecrets[]` is supported.
- **Ingress**: requires `hosts` or `defaultBackend`. Besides the legacy `hosts[]` block, you can use grouped hosts via `hosts.primary`/`hosts.additional` with `rules[]` (per-rule enablement and `includeForPrimaryHost`/`includeForAdditionalHost`) to fan out shared path sets across host groups; `servicePort` defaults to `service.ports[0]` when not set on a path/backend.
- **Maintenance**: when `.Values.maintenance.enabled` is true, ingress targets the maintenance service/port (`maintenance.service.externalPort` or `maintenance.servicePort`) instead of the component service; override the maintenance service name with `maintenance.service.name` when needed.
- **Affinity**: use `affinity` for your base rules and `additionalAffinities[]` to layer on more affinity snippets; later entries override earlier keys.
- **HPA**: when `enabled`, `minReplicas`, `maxReplicas`, and `metrics` are required.
- **PDB**: when `enabled`, set either `minAvailable` or `maxUnavailable` (not both).
- **NetworkPolicy**: defaults to namespace-local ingress allow; egress only if `allowEgress: true` or `extraEgressRules` present. Use `componentScoped: false` to drop the component label when you want one policy to cover multiple components. `additionalNetworkPolicies[]` supported.
- **Certificates**: renders cert-manager `Certificate`; `issuerRef` required when enabled. `certificate.acmeConfig` maps to `spec.acme.config[]` (defaults `http01.ingress` to the chart fullname when not set). `additionalCertificates[]` available.
- **TLS init container image**: override the cert-copy init container image via `enabledInitContainersCertificate.image` (repository/tag/digest/pullPolicy); any fields not set fall back to the component `image`.
- **Persistence**: component-level `persistence` or `volumes[].persistence` can auto-create PVCs (unless `existingClaim`); per-volume persistence forbids `emptyDir` and wires the volume to the claim automatically.
- **Additional containers**: `sidecars`/`additionalContainers` can inherit env, mounts, or resources from another container in the same component via `inheritEnvFrom` / `inheritVolumeMountsFrom` / `inheritResourcesFrom` (explicit fields on the child override inherited ones).
- **CronJob**: `schedule` is required; job-spec knobs (`parallelism`, `backoffLimit`, `podFailurePolicy`, etc.) live directly under the component block.
- **Annotations**: `annotations` apply broadly by default; set `annotationsWorkloadOnly: true` or use `workloadAnnotations` to scope/override annotations on the workload resources only (deployment/statefulset/job/cronjob), e.g., for Helm hooks.
- **StatefulSet**: define `serviceName` and `volumeClaimTemplates` as needed; supports `persistentVolumeClaimRetentionPolicy`.
- **Checksums**: `cos-common.componentChecksum` can hash a rendered resource (configmap/secret/etc.) for restart-on-change annotations.

## Tips
- Keep component names short; helpers trim names to 63 chars for DNS compatibility.
- Use `.Values.global` for shared knobs and reference them with `{{ .Values.global.* }}` or via `tpl`.
- When annotating a pod template for restarts on config changes, use something like `checksum/config: {{ include "cos-common.componentChecksum" (dict "root" . "name" "app" "values" .Values.app "resource" "configmap") }}`.
- For CronJobs, set `schedule` and any job fields you need directly under the component block.
- For StatefulSets, set `serviceName` and `volumeClaimTemplates` when you need stable identities.

## Example chart
See `angular-osf/templates/main.yaml` and `angular-osf/values.yaml` in this repo for a complete working example that wires together config map, secret, deployment, service, ingress, HPA, PDB, and certificate using this library.
