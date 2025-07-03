# GitOps Setup Guide: Tailscale with Flux

This guide shows how to deploy Tailscale using pure GitOps principles with your existing Flux setup.

## Why GitOps for Tailscale?

**GitOps Benefits:**
- ✅ **Declarative**: Everything defined in Git
- ✅ **Automatic**: Flux handles deployments
- ✅ **Auditable**: Git history tracks all changes
- ✅ **Rollback**: Easy to revert via Git
- ✅ **Consistency**: Same deployment everywhere

**No Custom Scripts Needed**: Your existing Flux setup will automatically deploy Tailscale when you commit changes.

## Current Flux Setup Analysis

Your cluster is already configured with:
- **Flux System**: Running in `flux-system` namespace
- **Apps Kustomization**: Points to `./apps/overlays/local`
- **GitOps Source**: Your current Git repository

## Integration with Existing Structure

### File Structure Created
```
apps/
├── base/
│   └── tailscale/
│       ├── helm-repository.yaml      # Tailscale Helm repo
│       ├── namespace.yaml            # tailscale namespace
│       ├── oauth-secret.yaml         # OAuth secret template
│       ├── helm-release.yaml         # HelmRelease for operator
│       └── kustomization.yaml        # Base kustomization
└── overlays/
    └── local/
        └── kustomization.yaml        # Updated to include Tailscale
```

### How It Integrates
1. **Flux watches** your Git repository
2. **Apps Kustomization** processes `./apps/overlays/local`
3. **Local overlay** includes `../../base/tailscale`
4. **Tailscale HelmRepository** and **HelmRelease** get deployed
5. **Helm chart** deploys the Tailscale operator

## Setup Steps (GitOps Way)

### Step 1: Create OAuth Credentials
```bash
# Get OAuth credentials from Tailscale
# Visit: https://login.tailscale.com/admin/settings/oauth
# Required scopes: 'devices' and 'all'

# Create the secret manually (DO NOT commit to Git)
kubectl create secret generic operator-oauth \
  --from-literal=client_id=your_actual_client_id \
  --from-literal=client_secret=your_actual_client_secret \
  --namespace=tailscale
```

**Why Manual Secret?**
- OAuth credentials should never be committed to Git
- Secret exists outside of GitOps for security
- HelmRelease references the secret by name

### Step 2: Commit Tailscale Configuration
```bash
# Add Tailscale files to Git
git add apps/base/tailscale/
git add apps/overlays/local/kustomization.yaml

# Commit the changes
git commit -m "Add Tailscale operator with Helm and Flux

- Add official Tailscale Helm repository
- Configure HelmRelease for operator deployment  
- Integrate with existing GitOps workflow
- Requires manual OAuth secret creation"

# Push to trigger Flux deployment
git push
```

### Step 3: Watch Flux Deploy Everything
```bash
# Watch Flux process the changes
flux get kustomizations

# Watch HelmRepository become ready
kubectl get helmrepository tailscale -n flux-system -w

# Watch HelmRelease deploy operator
kubectl get helmrelease tailscale-operator -n tailscale -w

# Watch operator pod start
kubectl get pods -n tailscale -w
```

## Verification Commands

### Check Flux Status
```bash
# Overall Flux health
flux check

# Apps kustomization status
flux get kustomization apps

# Tailscale HelmRepository status
flux get source helm tailscale

# Tailscale HelmRelease status
flux get helmrelease tailscale-operator
```

### Check Tailscale Deployment
```bash
# Operator deployment
kubectl get deployment tailscale-operator -n tailscale

# Operator pods
kubectl get pods -n tailscale

# Operator logs
kubectl logs -n tailscale deployment/tailscale-operator
```

### Check Service Integration
```bash
# Deploy services with Tailscale annotations
kubectl apply -f apps/base/simple-frontend/service-tailscale.yaml
kubectl apply -k apps/base/admin-dashboard/

# Check for proxy pods
kubectl get pods -A | grep ts-
```

## GitOps Workflows

### Adding New Tailscale Services
1. **Create service** with Tailscale annotations
2. **Commit to Git**
3. **Flux automatically applies** changes
4. **Tailscale operator creates** proxy pods

### Updating Tailscale Operator
1. **Update chart version** in `helm-release.yaml`
2. **Commit to Git**
3. **Flux automatically upgrades** via Helm

### Changing Configuration
1. **Modify values** in `helm-release.yaml`
2. **Commit to Git**
3. **Flux applies changes** automatically

## Troubleshooting GitOps Issues

### HelmRepository Not Ready
```bash
# Check repository status
kubectl describe helmrepository tailscale -n flux-system

# Check Flux source controller
kubectl logs -n flux-system deployment/source-controller

# Force reconciliation
flux reconcile source helm tailscale
```

### HelmRelease Failed
```bash
# Check release status
kubectl describe helmrelease tailscale-operator -n tailscale

# Check Flux helm controller
kubectl logs -n flux-system deployment/helm-controller

# Force reconciliation
flux reconcile helmrelease tailscale-operator
```

### Secret Missing Error
```bash
# Verify OAuth secret exists
kubectl get secret operator-oauth -n tailscale

# If missing, create it manually
kubectl create secret generic operator-oauth \
  --from-literal=client_id=your_client_id \
  --from-literal=client_secret=your_client_secret \
  --namespace=tailscale
```

## Security Best Practices

### OAuth Secret Management
- ✅ **Never commit** OAuth credentials to Git
- ✅ **Create manually** before deployment
- ✅ **Use least privilege** scopes
- ✅ **Rotate regularly** OAuth credentials

### GitOps Security
- ✅ **Review all changes** before committing
- ✅ **Use signed commits** if possible
- ✅ **Monitor Flux logs** for unexpected changes
- ✅ **Keep Git history** clean and auditable

## Advantages Over Custom Scripts

| Aspect | Custom Script | GitOps with Flux |
|--------|---------------|------------------|
| **Deployment** | Manual execution | Automatic on Git push |
| **Updates** | Re-run script | Commit configuration |
| **Rollback** | Manual process | Git revert |
| **Audit Trail** | Script logs | Git history |
| **Consistency** | Environment dependent | Git as single source |
| **Security** | Script access needed | Git access only |
| **Monitoring** | Custom alerts | Flux built-in status |

## Next Steps

1. **Create OAuth secret** (manual step)
2. **Commit Tailscale config** to Git
3. **Watch Flux deploy** everything automatically
4. **Configure services** with Tailscale annotations
5. **Let GitOps manage** all future updates

Your existing Flux setup will handle everything automatically - no scripts needed!

---

*Pure GitOps: Let Git and Flux do the work.*