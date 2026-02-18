
# GCP SQL Proxy

[sql-proxy](https://cloud.google.com/sql/docs/postgres/sql-proxy) The Cloud SQL Proxy provides secure access to your Cloud SQL Postgres/MySQL instances without having to whitelist IP addresses or configure SSL.

Accessing your Cloud SQL instance using the Cloud SQL Proxy offers these advantages:

* Secure connections: The proxy automatically encrypts traffic to and from the database; SSL certificates are used to verify client and server identities.
* Easier connection management: The proxy handles authentication with Google Cloud SQL, removing the need to provide static IP addresses of your GKE/GCE Kubernetes nodes.

## Introduction

This chart creates a Google Cloud SQL proxy deployment and service on a Kubernetes cluster using the Helm package manager.
You need to enable Cloud SQL Administration API and create a service account for the proxy as per these [instructions](https://cloud.google.com/sql/docs/postgres/connect-container-engine).

## Prerequisites

- Kubernetes cluster on Google Container Engine (GKE)
- Kubernetes cluster on Google Compute Engine (GCE)
- Cloud SQL Administration API enabled
- GCP Service account for the proxy with `Cloud SQL Client` role

## Installing the Chart

Install from remote URL with the release name `pg-sqlproxy` into namespace `sqlproxy`, set GCP service account and SQL instances and ports:

```console
$ helm upgrade --install pg-sqlproxy rimusz/gcloud-sqlproxy --namespace sqlproxy \
    --set serviceAccountKey="$(cat service-account.json | base64 | tr -d '\n')" \
    --set cloudsql.instances[0].instance=INSTANCE \
    --set cloudsql.instances[0].project=PROJECT \
    --set cloudsql.instances[0].region=REGION \
    --set cloudsql.instances[0].port=5432 -i
```

Replace Postgres/MySQL host with: if access is from the same namespace with `pg-sqlproxy-gcloud-sqlproxy` or if it is from a different namespace with `pg-sqlproxy-gcloud-sqlproxy.sqlproxy`, the rest database connections settings do not have to be changed.

> **Tip**: List all releases using `helm list`

> **Tip**: If you encounter a YAML parse error on `gcloud-sqlproxy/templates/secrets.yaml`, you might need to set `-w 0` option to `base64` command.

> **Tip**: If you are using a MySQL instance, you may want to replace `pg-sqlproxy` with `mysql-sqlproxy` and `5432` with `3306`.

> **Tip**: Because of limitations on the length of port names, the `instance` value for each of the instances must be unique for the first 15 characters.

> **Tip**: If you wish to source some `cloussql.instances[]` parameter values from ConfigMaps or Secrets, you may fetch them via `env` parameter and refer
  to them via `$()` [interpolation syntax](https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/#use-configmap-defined-environment-variables-in-pod-commands),
  e.g.: `cloudsql.instances[0].region=$(REGION)`

## Uninstalling the Chart

To uninstall/delete the `my-release-name` deployment:

```console
$ helm delete my-release-name
```

The command removes all the Kubernetes components associated with the chart and deletes the release.

## Configuration

The following table lists the configurable parameters of the `gcloud-sqlproxy` chart and their default values.

| Parameter                         | Description                             | Default                                                                                     |
| --------------------------------- | --------------------------------------  | ---------------------------------------------------------                                   |
| `image`                           | SQLProxy image                          | `gcr.io/cloudsql-docker/gce-proxy`                                                        |
| `image.tag`                        | SQLProxy image tag                      | AppVersion: `1.30.1`                                                                                      |
| `imagePullPolicy`                 | Image pull policy                       | `IfNotPresent`                                                                              |
| `replicasCount`                   | Replicas count                          | `1`                                                                                         |
| `deploymentStrategy`              | Deployment strategy for pods            | `{}`                                                                                        |
| `commonLabels`                    | Common labels for all K8S objects       |                                                                                             |
| `serviceAccountKey`               | Service account key JSON file           | Must be provided and base64 encoded when no existing secret is used, in this case a new secret will be created holding this service account |
| `existingSecret`                  | Name of an existing secret to be used for the cloud-sql credentials | `""`                                                            |
| `existingSecretKey`               | The key to use in the provided existing secret   | `""`                                                                               |
| `usingGCPController`              | enable the use of the GCP Service Account Controller     | `""`                                                                       |
| `serviceAccountName`              | specify a service account name to use with GCP Controller | `""`                                                                                        |
| `cloudsql.instances`              | List of PostgreSQL/MySQL instances      | [{instance: `instance`, project: `project`, region: `region`, port: 5432}] must be provided |
| `resources`                       | CPU/Memory resource requests/limits     | Memory: `100/150Mi`, CPU: `100/150m`                                                        |
| `env`                             | Extra [environment variables](https://kubernetes.io/docs/tasks/inject-data-application/define-environment-variable-container/) for container | `{}` |
| `lifecycleHooks`                  | Container lifecycle hooks               | `{}`                                                                                        |
| `autoscaling.enabled`             | Enable CPU/Memory horizontal pod autoscaler | `false`                                                                                 |
| `autoscaling.minReplicas`         | Autoscaler minimum pod replica count    | `1`                                                                                         |
| `autoscaling.maxReplicas`         | Autoscaler maximum pod replica count    | `3`                                                                                         |
| `autoscaling.targetCPUUtilizationPercentage` | Scaling target for CPU Utilization Percentage | `50`                                                                       |
| `autoscaling.targetMemoryUtilizationPercentage` | Scaling target for Memory Utilization Percentage | `50`                                                                 |
| `terminationGracePeriodSeconds`   | # of seconds to wait before pod killed  | `30` (Kubernetes default)                                                                   |
| `podAnnotations`                  | Pod Annotations                         |                                                                                             |
| `podLabels`                       | Pod Labels                              |                                                                                             |
| `priorityClassName`                  | Priority Class Name                  | `""`                                                                                         |
| `nodeSelector`                    | Node Selector                           |                                                                                             |
| `podDisruptionBudget`             | Pod disruption budget                   | `maxUnavailable: 1` if `replicasCount` > 1, does not create the PDB otherwise               |
| `service.enabled`                 | Toggle Service Creation                 | `true`
| `service.type`                    | Kubernetes LoadBalancer type            | `ClusterIP`                                                                                 |
| `service.internalLB`              | Create service with `cloud.google.com/load-balancer-type: "Internal"` | Default `false`, when set to `true` you have to set also `service.type=LoadBalancer` |
| `service.loadBalancerIP`          | Set custom Load Balancer IP             | `""`                                                                                                    |
| `service.annotations`             | Set custom service annotations          | `""`                                                                                                    |
| `rbac.create`                     | Create RBAC configuration w/ SA         | `false`                                                                                     |
| `serviceAccount.create` | Create a service account | `true` |
| `serviceAccount.annotations` | Annotations for the service account | `{}` |
| `serviceAccount.name` |  Service account name | Generated using the fullname template |
| `networkPolicy.enabled`           | Enable NetworkPolicy                    | `true`                                                                                      |
| `networkPolicy.ingress.from`      | List of sources which should be able to access the pods selected for this rule. If empty, allows all sources. | `[]`                  |
| `extraArgs`                       | Additional container arguments          | `{}`                                                                                        |
| `extraFlags`                      | Additional container flags              | `[]`                                                                                        |
| `podSecurityContext`              | Configure Pod Security Context          | `{}` |
| `containerSecurityContext`        | Configure Container Security Context    | `{}` |
| `httpPortProbe`                   | The port to check liveness, readiness & startup probe | 9090                                                                          |
| `livenessProbe.enabled`           | Would you like a livenessProbe to be enabled  | `false`                                                                               |
| `livenessProbe.port`              | The port which will be checked by the probe | 9090                                                                                   |
| `livenessProbe.initialDelaySeconds` | Delay before liveness probe is initiated    | 30                                                                                    |
| `livenessProbe.periodSeconds`     | How often to perform the probe                | 10                                                                                    |
| `livenessProbe.timeoutSeconds`    | When the probe times out                      | 5                                                                                     |
| `livenessProbe.failureThreshold`  | Minimum consecutive failures for the probe to be considered failed after having succeeded.  | 18                                       |
| `livenessProbe.successThreshold`  | Minimum consecutive successes for the probe to be considered successful after having failed | 1                                       |
| `readinessProbe.enabled`          | would you like a readinessProbe to be enabled | `false`                                                                               |
| `readinessProbe.port`             | The port which will be checked by the probe | 9090                                                                                   |
| `readinessProbe.initialDelaySeconds` | Delay before readiness probe is initiated  | 5                                                                                     |
| `readinessProbe.periodSeconds`    | How often to perform the probe                | 10                                                                                    |
| `readinessProbe.timeoutSeconds`   | When the probe times out                      | 5                                                                                     |
| `readinessProbe.failureThreshold` | Minimum consecutive failures for the probe to be considered failed after having succeeded.  | 6                                       |
| `readinessProbe.successThreshold` | Minimum consecutive successes for the probe to be considered successful after having failed | 1                                       |
| `startupProbe.enabled`          | would you like a startupProbe to be enabled | `false`                                                                               |
| `startupProbe.port`                | The port which will be checked by the probe | 9090                                                                                   |
| `startupProbe.initialDelaySeconds` | Delay before startup probe is initiated  |  5                                                                                     |
| `startupProbe.periodSeconds`    | How often to perform the probe                | 10                                                                                    |
| `startupProbe.timeoutSeconds`   | When the probe times out                      | 5                                                                                     |
| `startupProbe.failureThreshold` | Minimum consecutive failures for the probe to be considered failed after having succeeded.  | 1                                       |
| `startupProbe.successThreshold` | Minimum consecutive successes for the probe to be considered successful after having failed | 1                                       |
| `useStatefulset`                  | Deploy as a statefulset rather than a deployment                                            | false                                       |
| `httpReadinessProbe.enabled`      | Enables http readiness probe                  | `false`                                       |
| `httpLivenessProbe.enabled`       | Enables http liveness  probe                  | `false`                                       |
| `httpStartupProbe.enabled`        | Enables http startup probe                  | `false`                                       |
| `topologySpreadConstraints`        | List of TopologySpreadConstraints             | `[]`                                        |


Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`.

The `extraArgs` can be provided via dot notation, e.g. `--set extraArgs.admin-port=8091` passes `--admin-port=8091` to the SQL Proxy command.

Alternatively, a YAML file that specifies the values for the above parameters can be provided while installing the chart. For example,

```console
$ helm install --name my-release -f values.yaml rimusz/gcloud-sqlproxy
```

> **Tip**: You can use the default [values.yaml](values.yaml)

### Auto generating the gcp service account
By enabling the flag `usingGCPController` and having a GCP Service Account Controller deployed in your cluster, it is possible to autogenerate and inject the service account used for connecting to the database. For more information see https://github.com/kiwigrid/helm-charts/tree/master/charts/gcp-serviceaccount-controller

### Handling A Large Number of Instances

GCP does not support more than 5 endpoints on an Internal Load Balancer. To work around this, you can deploy this as a Statefulset to get all the hostname-guarantees associated with statefulsets. You can then access the headless service, e.g.: `cloudsql-proxy-headless.cloudsql-proxy.svc.cluster.local`

## Documentation

- [Cloud SQL Proxy for Postgres](https://cloud.google.com/sql/docs/postgres/sql-proxy)
- [Cloud SQL Proxy for MySQL](https://cloud.google.com/sql/docs/mysql/sql-proxy)
- [GKE samples](https://github.com/GoogleCloudPlatform/container-engine-samples/tree/master/cloudsql)


## Upgrading

**From <= 0.24.2 to >= 0.25.0**

Please note, as of `0.25.0` use [cloud-sql-proxy v2](https://github.com/GoogleCloudPlatform/cloud-sql-proxy/blob/main/migration-guide.md). The `httpPortProbe` replaced `httpLivenessProbe.port` & `httpReadinessProbe.port`.


Please note, as of `0.25.3`, if the value of `cloudsql.instances[].instanceShortName` remains undefined, an instanceShortName of 15 characters length will be generated, with a combination of first 5 letters of the instance name, then a hypen "-" and the remaining 9 characters will be autogenerated using sha1sum of the `instance` name.

**From <= 0.22.2 to >= 0.23.0**

Please note, the `securityContext` has been renamed into `podSecurityContext`.

**From < 0.22.0 to >= 0.22.2**

Please note, as of `0.22.1` image `repository`, `tag` and `pullPolicy` values use new variables, if not using the defaults, you will need to rename them.

**From < 0.10.0 to >= 0.10.0**

Please note, if chart name is included in release name, it will now be used as full name.
E.g. service `gcloud-sqlproxy-gcloud-sqlproxy` will now show up as `gcloud-sqlproxy`.

**From < 0.11.0 to >= 0.11.0**

Please note, as of `0.11.0` recommended labels are used. Please take into anything that may target your release's objects via labels.

## Support

Kubernetes versions older than 1.9 are not supported by this chart.
