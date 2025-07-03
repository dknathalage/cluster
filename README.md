# Flux GitOps Cluster Configuration

This repository contains the GitOps configuration for managing Kubernetes clusters using [Flux v2](https://fluxcd.io/) with Kustomize. This setup follows an "everything is an app" approach where all components, including infrastructure, are treated as applications.

## Repository Structure

```
cluster/
├── clusters/
│   └── local/                     # Local cluster configuration
│       ├── flux-system/           # Flux system components
│       └── apps.yaml             # Application kustomizations
├── apps/
│   ├── base/                     # Base application manifests
│   │   ├── simple-frontend/      # Example frontend application
│   │   └── cloudflared/          # Cloudflare tunnel app
│   └── overlays/
│       └── local/                # Local environment overlays
│           ├── kustomization.yaml
│           ├── simple-frontend/   # Local frontend overrides
│           └── cloudflared/       # Local tunnel overrides
├── bootstrap.sh                  # Bootstrap script
├── CLOUDFLARE_TUNNEL_SETUP.md   # Cloudflare tunnel setup guide
└── TUNNEL_DASHBOARD_UPDATE.md    # Tunnel dashboard update guide
```

## Everything is an App Philosophy

In this setup, we treat all components as applications:
- **Infrastructure components** (ingress controllers, cert-manager, monitoring) are apps
- **Application services** (frontend, backend, databases) are apps
- **Utilities** (tunnels, dashboards, tools) are apps

This approach provides:
- **Consistency**: All components follow the same deployment pattern
- **Simplicity**: One way to manage everything
- **Flexibility**: Easy to customize per environment using Kustomize overlays

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
export CLUSTER_NAME="local"
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

# Check all resources
kubectl get all -A
```

## Manual Bootstrap (Alternative)

If you prefer to bootstrap manually:

```bash
# Bootstrap Flux
flux bootstrap github \
  --owner=$GITHUB_USER \
  --repository=$GITHUB_REPO \
  --branch=main \
  --path=./clusters/local \
  --personal
```

## Adding New Applications

### 1. Create Base Application
Create a new directory in `apps/base/`:

```bash
mkdir -p apps/base/my-app
```

Create the application manifests:

```yaml
# apps/base/my-app/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - deployment.yaml
  - service.yaml
  - configmap.yaml

# apps/base/my-app/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
      - name: my-app
        image: my-app:latest
        ports:
        - containerPort: 8080
```

### 2. Add to Overlay
Add your app to the local overlay:

```bash
mkdir -p apps/overlays/local/my-app
```

Create overlay configuration:
```yaml
# apps/overlays/local/my-app/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - ../../../base/my-app
patchesStrategicMerge:
  - deployment-patch.yaml
```

### 3. Update Main Kustomization
Add the new app to `apps/overlays/local/kustomization.yaml`:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - cloudflared
  - simple-frontend
  - my-app  # Add this line
```

## Adding Infrastructure as Apps

Infrastructure components are added the same way as regular apps:

### Example: Adding an Ingress Controller
1. Create `apps/base/nginx-ingress/`
2. Add Helm repository and release manifests
3. Create overlay in `apps/overlays/local/nginx-ingress/`
4. Add to the main kustomization

### Example: Adding Monitoring
1. Create `apps/base/monitoring/`
2. Add Prometheus, Grafana, and AlertManager manifests
3. Create environment-specific overlays
4. Add to the main kustomization

## Monitoring and Troubleshooting

### Check Flux Status
```bash
# Overall health
flux check

# Kustomizations status
flux get kustomizations

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
```

### Common Issues

1. **GitHub Rate Limiting**: Increase sync interval in kustomization specs
2. **Resource Conflicts**: Check for duplicate resources across apps
3. **Kustomization Failures**: Check paths and resource references

## Security Considerations

- Store sensitive data in Kubernetes Secrets
- Use Sealed Secrets or SOPS for encrypting secrets in Git
- Implement proper RBAC policies for each app
- Regularly update Flux components and app images

## Environment Management

The overlay structure allows for easy environment management:
- `apps/overlays/local/` - Local development environment
- `apps/overlays/staging/` - Staging environment (can be added)
- `apps/overlays/production/` - Production environment (can be added)

Each environment can have different:
- Resource limits
- Replica counts
- Configuration values
- Secrets and ConfigMaps

## Contributing

1. Create a feature branch
2. Add or modify apps in the appropriate directories
3. Test in a development cluster
4. Submit a pull request

## Additional Resources

- [Flux Documentation](https://fluxcd.io/flux/)
- [Kustomize Documentation](https://kustomize.io/)
- [Flux Community](https://github.com/fluxcd/community) 
