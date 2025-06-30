# Operators

This directory contains operator configurations for your cluster.

## Adding Operators

### Helm-based Operators (Recommended)
```yaml
# my-operator.yaml
apiVersion: source.toolkit.fluxcd.io/v1beta2
kind: HelmRepository
metadata:
  name: my-operator-repo
  namespace: flux-system
spec:
  interval: 24h
  url: https://charts.example.com
---
apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: my-operator
  namespace: flux-system
spec:
  interval: 30m
  chart:
    spec:
      chart: my-operator
      version: "1.x"
      sourceRef:
        kind: HelmRepository
        name: my-operator-repo
        namespace: flux-system
  targetNamespace: my-operator-system
  install:
    createNamespace: true
  values:
    # operator values here
```

### Direct YAML Manifests
```yaml
# operator-manifests.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: my-operator-system
---
# Add your operator manifests here
```

## Usage

1. Add your operator YAML files to this directory
2. Update `kustomization.yaml` to include your new files
3. Commit and push - Flux will deploy automatically 