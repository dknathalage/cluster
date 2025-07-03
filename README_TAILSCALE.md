# Tailscale GitOps Integration - Quick Start

## What's Been Created

Perfect GitOps integration for Tailscale with your existing Flux setup! 🎉

### Files Structure
```
apps/
├── base/tailscale/               # Tailscale base configuration
│   ├── helm-repository.yaml     # Official Tailscale Helm repo
│   ├── namespace.yaml            # tailscale namespace  
│   ├── oauth-secret.yaml         # OAuth secret template
│   ├── helm-release.yaml         # HelmRelease for operator
│   └── kustomization.yaml        # Base kustomization
└── overlays/local/
    └── kustomization.yaml        # Updated to include Tailscale
```

### Key Benefits
- ✅ **Official Helm Chart**: Maintained by Tailscale
- ✅ **Pure GitOps**: No scripts, Flux handles everything
- ✅ **Secure**: OAuth secrets not committed to Git
- ✅ **Automatic**: Deploys on Git push

## Quick Start (2 Steps!)

### Step 1: Create OAuth Secret
```bash
# Get credentials from: https://login.tailscale.com/admin/settings/oauth
# Required scopes: 'devices' and 'all'

kubectl create secret generic operator-oauth \
  --from-literal=client_id=your_actual_client_id \
  --from-literal=client_secret=your_actual_client_secret \
  --namespace=tailscale
```

### Step 2: Commit and Deploy
```bash
# Add Tailscale configuration
git add apps/base/tailscale/ apps/overlays/local/kustomization.yaml

# Commit changes
git commit -m "Add Tailscale operator with Helm and Flux

- Official Tailscale Helm chart integration
- Pure GitOps deployment via Flux
- OAuth secret managed separately for security"

# Deploy via GitOps (Flux will handle everything)
git push
```

## Verification Commands

```bash
# Watch Flux deploy everything
flux get kustomizations -w

# Check Tailscale components
kubectl get helmrepository tailscale -n flux-system
kubectl get helmrelease tailscale-operator -n tailscale  
kubectl get pods -n tailscale

# Deploy example services
kubectl apply -f apps/base/simple-frontend/service-tailscale.yaml
kubectl apply -k apps/base/admin-dashboard/

# Check for Tailscale proxy pods
kubectl get pods -A | grep ts-
```

## Service Configuration

### Public Service (Internet Access)
```yaml
apiVersion: v1
kind: Service
metadata:
  annotations:
    tailscale.com/expose: "true"
    tailscale.com/funnel: "true"    # <- Enables public access
    tailscale.com/hostname: "my-service"
```

### Private Service (Family Only) 
```yaml
apiVersion: v1
kind: Service
metadata:
  annotations:
    tailscale.com/expose: "true"
    # No funnel = private mesh access only
    tailscale.com/hostname: "private-service"
```

## What Happens Next

1. **Flux detects** Git changes
2. **HelmRepository** gets synced
3. **HelmRelease** deploys operator
4. **Tailscale operator** starts managing services
5. **Proxy pods** get created for annotated services
6. **Services become accessible** via Tailscale

## Family Access

Share `FAMILY_ONBOARDING.md` with family members - they just need to:
1. Install Tailscale app
2. Sign in with their email (after you add them)
3. Access services via `service-name.tail[xxx].ts.net`

## Troubleshooting

```bash
# Check Flux status
flux check

# Check HelmRelease status  
flux get helmrelease tailscale-operator

# Check operator logs
kubectl logs -n tailscale deployment/tailscale-operator

# Force reconciliation if needed
flux reconcile kustomization apps
```

## Documentation

- `GITOPS_SETUP.md` - Detailed GitOps guide
- `TAILSCALE_MIGRATION.md` - Complete migration documentation  
- `FAMILY_ONBOARDING.md` - Family member guide
- `HELM_TESTING.md` - Helm-specific testing

---

**You're all set!** Your cluster now has end-to-end encrypted access with true GitOps deployment. No scripts needed - just commit and push! 🚀