# Flux GitOps Cluster Configuration

This repository contains the GitOps configuration for managing Kubernetes clusters using [Flux v2](https://fluxcd.io/) with Kustomize.

## Repository Structure

```
cluster/
├── clusters/
│   └── production/                 # Production cluster configuration
│       ├── flux-system/           # Flux system components
│       ├── infrastructure.yaml    # Infrastructure kustomizations
│       └── apps.yaml             # Application kustomizations
├── infrastructure/
│   ├── controllers/              # Infrastructure controllers (ingress, cert-manager, etc.)
│   └── configs/                  # Infrastructure configurations
├── apps/
│   ├── base/                    # Base application manifests
│   └── production/              # Production-specific overlays
└── bootstrap.sh                 # Bootstrap script
```

## Prerequisites

1. **Kubernetes Cluster**: A running Kubernetes cluster with admin access
2. **Flux CLI**: Install the Flux CLI following the [official guide](https://fluxcd.io/flux/installation/)
3. **GitHub Personal Access Token**: Create a token with `repo` permissions
4. **kubectl**: Configured to access your cluster

## Quick Start

### 1. Fork this Repository
Fork this repository to your GitHub account.

### 2. Set Environment Variables
```bash
export GITHUB_USER="your-github-username"
export GITHUB_TOKEN="your-github-token"
export GITHUB_REPO="cluster"
export CLUSTER_NAME="production"
```

### 3. Run Bootstrap Script
```bash
chmod +x bootstrap.sh
./bootstrap.sh
```

### 4. Verify Installation
```bash
# Check Flux components
flux check

# Check kustomizations
flux get kustomizations

# Check helm releases
flux get helmreleases -A
```

## Manual Bootstrap (Alternative)

If you prefer to bootstrap manually:

```bash
# Bootstrap Flux
flux bootstrap github \
  --owner=$GITHUB_USER \
  --repository=$GITHUB_REPO \
  --branch=main \
  --path=./clusters/production \
  --personal

# Apply workloads
kubectl apply -f clusters/production/infrastructure.yaml
kubectl apply -f clusters/production/apps.yaml
```

## Adding New Applications

### 1. Add Helm Application
Create a new file in `apps/base/`:

```yaml
# apps/base/my-app.yaml
apiVersion: source.toolkit.fluxcd.io/v1beta2
kind: HelmRepository
metadata:
  name: my-app
  namespace: flux-system
spec:
  interval: 5m
  url: https://charts.example.com
---
apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: my-app
  namespace: flux-system
spec:
  interval: 30m
  chart:
    spec:
      chart: my-app
      version: "1.x"
      sourceRef:
        kind: HelmRepository
        name: my-app
        namespace: flux-system
  targetNamespace: my-app
  createNamespace: true
  values:
    # Your values here
```

### 2. Update Kustomization
Add the new app to `apps/base/kustomization.yaml`:

```yaml
resources:
- podinfo.yaml
- my-app.yaml  # Add this line
```

## Adding Infrastructure Components

1. Create YAML files in `infrastructure/controllers/` or `infrastructure/configs/`
2. Update the respective `kustomization.yaml` file
3. Commit and push changes

## Monitoring and Troubleshooting

### Check Flux Status
```bash
# Overall health
flux check

# Kustomizations status
flux get kustomizations

# Helm releases status
flux get helmreleases -A

# Sources status
flux get sources all -A
```

### View Logs
```bash
# Flux controllers logs
flux logs --level=error --all-namespaces

# Specific controller logs
kubectl logs -n flux-system deployment/source-controller
kubectl logs -n flux-system deployment/kustomize-controller
kubectl logs -n flux-system deployment/helm-controller
```

### Common Issues

1. **GitHub Rate Limiting**: Increase sync interval or use GitHub App
2. **Resource Conflicts**: Check for duplicate resources across kustomizations
3. **Helm Chart Issues**: Verify chart versions and values

## Security Considerations

- Store sensitive data in Kubernetes Secrets
- Use Sealed Secrets or SOPS for encrypting secrets in Git
- Implement proper RBAC policies
- Regularly update Flux components

## Contributing

1. Create a feature branch
2. Make your changes
3. Test in a development cluster
4. Submit a pull request

## Additional Resources

- [Flux Documentation](https://fluxcd.io/flux/)
- [Kustomize Documentation](https://kustomize.io/)
- [Flux Community](https://github.com/fluxcd/community) 
