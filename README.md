# Flux GitOps Cluster Management

This repository implements a self-managing Flux architecture where Flux manages itself and all applications after a one-time bootstrap.

## Architecture

```
├── bootstrap/                    # One-time manual installation
│   ├── flux-system.yaml         # Flux components
│   └── gotk-sync.yaml           # Bootstrap sync configuration
├── clusters/
│   └── local/                   # Local cluster configuration
│       ├── kustomization.yaml   # Main cluster kustomization
│       └── flux-system/         # Flux self-management
│           ├── kustomization.yaml
│           ├── gotk-sync.yaml   # Self-management sync
│           ├── repos/           # GitRepository resources
│           │   ├── kustomization.yaml
│           │   └── cluster-repo.yaml
│           └── apps/            # Application Kustomizations
│               ├── kustomization.yaml
│               └── cluster-apps.yaml
└── apps/                        # Application definitions
    └── local/
        ├── cluster/             # Cluster-level applications
        └── env/
            ├── prod/            # Production applications
            └── dev/             # Development applications
```

## One-Time Bootstrap

### Step 1: Install Flux Components
```bash
kubectl apply -f bootstrap/flux-system.yaml
```

### Step 2: Enable Self-Management
```bash
kubectl apply -f bootstrap/gotk-sync.yaml
```

After this, Flux will manage itself and all configurations from the `clusters/local/` directory.

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
- **Automatic**: New repos and apps are picked up automatically
- **Organized**: Clear separation between system and application configs
- **Scalable**: Easy to add new clusters, environments, or applications
- **GitOps**: Everything is version controlled and auditable

## Flux Commands

```bash
# Check Flux status
flux get all

# Force reconciliation
flux reconcile source git flux-system

# Suspend/resume a kustomization
flux suspend kustomization cluster-apps-prod
flux resume kustomization cluster-apps-prod
``` 