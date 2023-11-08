# helm-charts
Kubernetes Helm Charts for the Open Science Framework

[![Build Status](https://travis-ci.org/CenterForOpenScience/helm-charts.svg?branch=master)](https://travis-ci.org/CenterForOpenScience/helm-charts)

# Installation

## Prerequisites
- Install [Helm](https://docs.helm.sh/using_helm/#installing-helm)
  - tl;dr `brew install kubernetes-helm && helm init --client-only`
- A running Kubernetes cluster

## Configuring the charts repository
```bash
# Add the charts repository
helm repo add cos https://centerforopenscience.github.io/helm-charts/
# List the available charts
helm search repo cos/
```

## Check which charts are installed
```bash
helm ls
```

## Update/upgrade a release
The namespace from the installation will be used.
```bash
helm upgrade -i <release-name> -f /path/to/values.yaml
```

## Delete a release
```bash
helm del --purge <release-name>
```

## nginx-ingress
kubernetes/charts@f8d3a1197e4a7167143d42d2081fb05aab1ba396 : stable/nginx-ingress

## elasticsearch
https://github.com/cos-forks/kubernetes-charts/tree/feature/elasticsearch-v5 : incubator/elasticsearch
 - https://github.com/kubernetes/charts/pull/2530
