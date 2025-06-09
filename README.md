# Flux GitOps Cluster Management

This repository implements a self-managing Flux architecture where Flux manages itself and all applications after a one-time bootstrap.

## Architecture

```
├── clusters/
│   ├── base/
│   │   └── bootstrap/           # Base Flux components (shared)
│   │       ├── kustomization.yaml
│   │       └── flux-system.yaml
│   ├── local/                   # Local cluster configuration
│   │   ├── bootstrap/           # Local cluster bootstrap
│   │   │   ├── kustomization.yaml
│   │   │   └── gotk-sync.yaml
│   │   ├── kustomization.yaml   # Main cluster kustomization
│   │   └── flux-system/         # Flux self-management
│   │       ├── kustomization.yaml
│   │       ├── gotk-sync.yaml   # Self-management sync
│   │       ├── repos/           # GitRepository resources
│   │       │   ├── kustomization.yaml
│   │       │   └── cluster-repo.yaml
│   │       └── apps/            # Application Kustomizations
│   │           ├── kustomization.yaml
│   │           └── cluster-apps.yaml
│   └── staging/                 # Example staging cluster
│       └── bootstrap/           # Staging-specific bootstrap
│           ├── kustomization.yaml
│           └── gotk-sync.yaml
└── apps/                        # Application definitions
    └── local/
        ├── cluster/             # Cluster-level applications
        └── env/
            ├── prod/            # Production applications
            └── dev/             # Development applications
```

## Cluster-Specific Bootstrap

### Bootstrap Local Cluster
```bash
# One command bootstrap for local cluster
make flux.bootstrap.local

# Or manually with kubectl
kubectl apply -k clusters/local/bootstrap
```

### Bootstrap Other Clusters
```bash
# For staging cluster
kubectl apply -k clusters/staging/bootstrap

# For production cluster (create clusters/prod/bootstrap first)
kubectl apply -k clusters/prod/bootstrap
```

After bootstrap, Flux will manage itself and all configurations from the respective `clusters/<cluster-name>/` directory.

### Adding New Clusters
1. Create `clusters/<cluster-name>/bootstrap/` directory
2. Copy and customize from `clusters/local/bootstrap/`
3. Update the `gotk-sync.yaml` to point to the correct cluster path
4. Run `kubectl apply -k clusters/<cluster-name>/bootstrap`

## Adding New Applications

### Cluster-level Applications
1. Add your application manifests to `apps/local/cluster/`
2. Update `apps/local/cluster/kustomization.yaml` to include them
3. Commit and push - Flux will automatically deploy

### Environment-specific Applications
1. Add to `apps/local/env/prod/` or `apps/local/env/dev/`
2. Update the respective `kustomization.yaml`
3. Commit and push - Flux will automatically deploy

## Adding New Repositories

1. Create a new GitRepository in `clusters/local/flux-system/repos/`
2. Add it to `clusters/local/flux-system/repos/kustomization.yaml`
3. Create corresponding Kustomizations in `clusters/local/flux-system/apps/`
4. Commit and push - Flux will automatically pick up the new repo

## Key Benefits

- **Self-Managing**: Flux manages its own configuration
- **Cluster-Specific**: Each cluster has its own bootstrap and configuration
- **Kustomize-Native**: Uses proper base/overlay pattern for configuration reuse
- **Automatic**: New repos and apps are picked up automatically
- **Organized**: Clear separation between system and application configs
- **Scalable**: Easy to add new clusters, environments, or applications
- **Multi-Cluster**: Support for different clusters with different configurations
- **GitOps**: Everything is version controlled and auditable

## Flux Commands

```bash
# Bootstrap Flux for specific cluster
make flux.bootstrap.local         # Bootstrap local cluster
make flux.bootstrap               # Show available clusters

# Check Flux status
make flux.status                  # Generic status
make flux.status.local           # Local cluster status
flux get all

# Force reconciliation
make flux.reconcile              # Generic reconcile
make flux.reconcile.local        # Local cluster reconcile
flux reconcile source git flux-system

# Suspend/resume a kustomization
flux suspend kustomization cluster-apps-prod
flux resume kustomization cluster-apps-prod
```

## Infrastructure Management

```bash
# Check cluster connectivity
make ansible.ping

# Set up Kubernetes cluster
make ansible.cluster.setup
``` 
