# Tailscale Migration Guide: From Cloudflare to End-to-End Encryption

## Overview and Motivation

This document guides you through migrating from Cloudflare Tunnel to Tailscale for your Kubernetes homelab. 

### Why This Migration?

**Problem with Cloudflare Tunnel:**
- **Not End-to-End Encrypted**: Cloudflare can decrypt and inspect all traffic
- **Man-in-the-Middle by Design**: Traffic flow is `Client → Cloudflare → Your Cluster`
- **No Granular Access Control**: All or nothing public access
- **Vendor Lock-in**: Dependent on Cloudflare's infrastructure

**Benefits of Tailscale:**
- **True E2E Encryption**: Direct encrypted connections to your cluster
- **Unified Solution**: Single system for both public and private access
- **Family-Friendly**: Easy mobile/desktop apps for all family members
- **Free for Personal Use**: Up to 20 devices at no cost
- **Zero Configuration**: Auto-discovery and mesh networking

### Architecture Comparison

**Before (Cloudflare):**
```
Internet → Cloudflare Proxy → Cloudflare Tunnel → Kubernetes
         ↑                  ↑
   Traffic Inspection   Decryption Point
```

**After (Tailscale):**
```
Public Internet → Tailscale Funnel → Kubernetes
Family Devices → Tailscale Mesh → Kubernetes
              ↑
        True E2E Encryption
```

## Prerequisites

- Domain name (dknathalage.dev) 
- Kubernetes cluster with kubectl access
- Tailscale account (free at tailscale.com)
- DNS management access for your domain

## Migration Steps

### Phase 1: Setup and Preparation
1. Analyze current Cloudflare setup
2. Create Tailscale account and auth keys
3. Deploy Tailscale operator to Kubernetes

### Phase 2: Service Migration
4. Configure public services with Tailscale Funnel
5. Set up private services with Tailscale mesh
6. Update DNS configuration

### Phase 3: Testing and Cleanup
7. Test all services (public and private)
8. Create family onboarding guide
9. Remove Cloudflare tunnel (optional)

## Current State Analysis

### Existing Cloudflare Setup
- **Deployment**: 2 replicas of cloudflared running in cloudflared namespace
- **Configuration**: Routes `dknathalage.dev` to `simple-frontend-service.default.svc.cluster.local:80`
- **Security**: Uses token-based authentication with Cloudflare
- **Services**: Currently only exposing simple frontend publicly

### Services to Migrate
1. **simple-frontend-service** (currently public via Cloudflare)
   - Location: `default` namespace
   - Port: 80
   - **Migration Plan**: This will become our test case for Tailscale Funnel

### Migration Strategy
- **Parallel Deployment**: Run Tailscale alongside Cloudflare initially
- **Gradual Cutover**: Test Tailscale first, then switch DNS
- **Rollback Plan**: Keep Cloudflare config for quick rollback if needed

## Implementation Timeline

- **Day 1**: Setup Tailscale and migrate simple services
- **Day 2**: Configure access control and test family access
- **Day 3**: Full migration and documentation

---

## Step-by-Step Implementation

### Step 1: Tailscale Account Setup

**Thought Process**: We need a Tailscale account and OAuth credentials before we can deploy anything to Kubernetes. The Tailscale Kubernetes operator uses OAuth instead of auth keys for better security and management.

**Action Items**:

1. **Create Tailscale Account**:
   - Go to https://tailscale.com and create an account
   - This will be your control plane for managing all devices and access

2. **Generate OAuth Credentials**:
   - Navigate to https://login.tailscale.com/admin/settings/oauth
   - Click "Generate client"
   - Set the following scopes:
     - `devices` (to manage Tailscale devices)
     - `all` (for full operator functionality)
   - Save the Client ID and Client Secret - you'll need these for Kubernetes

3. **Prepare Kubernetes Secrets**:
   ```bash
   # Replace with your actual OAuth credentials
   kubectl create secret generic operator-oauth \
     --from-literal=client_id=YOUR_CLIENT_ID \
     --from-literal=client_secret=YOUR_CLIENT_SECRET \
     --namespace=tailscale-system
   ```

**Why OAuth over Auth Keys**: OAuth provides better security, automatic token refresh, and granular permissions. Perfect for production homelab use.

### Step 2: Deploy Tailscale Operator

**Thought Process**: The Tailscale Kubernetes operator will manage Tailscale connections for our services. It creates proxy pods automatically and handles the networking complexity.

**Created Files**:
- `apps/base/tailscale/app/namespace.yaml` - Dedicated namespace with privileged security
- `apps/base/tailscale/app/crds.yaml` - Custom resource definitions for Tailscale
- `apps/base/tailscale/app/operator.yaml` - Main operator deployment
- `apps/base/tailscale/kustomization.yaml` - Kustomize configuration

**Deploy Commands**:
```bash
# Deploy CRDs first
kubectl apply -f apps/base/tailscale/app/crds.yaml

# Create namespace
kubectl apply -f apps/base/tailscale/app/namespace.yaml

# Create OAuth secret (replace with your credentials)
kubectl create secret generic operator-oauth \
  --from-literal=client_id=YOUR_CLIENT_ID \
  --from-literal=client_secret=YOUR_CLIENT_SECRET \
  --namespace=tailscale-system

# Deploy the operator
kubectl apply -f apps/base/tailscale/app/operator.yaml
```

**Verification**:
```bash
# Check operator is running
kubectl get pods -n tailscale-system

# Check operator logs
kubectl logs -n tailscale-system deployment/tailscale-operator
```

### Step 3: Configure Services for Tailscale

**Thought Process**: We need to differentiate between public and private services. Public services get the `tailscale.com/funnel: "true"` annotation, while private services only get `tailscale.com/expose: "true"`.

**Service Types Created**:

1. **Public Service** (`simple-frontend-tailscale.yaml`):
   ```yaml
   annotations:
     tailscale.com/expose: "true"
     tailscale.com/funnel: "true"    # <- Enables public access
     tailscale.com/hostname: "simple-frontend"
     tailscale.com/tags: "tag:k8s,tag:public"
   ```

2. **Private Service** (`admin-dashboard/service.yaml`):
   ```yaml
   annotations:
     tailscale.com/expose: "true"
     # NO funnel annotation = private only
     tailscale.com/hostname: "admin-dashboard"
     tailscale.com/tags: "tag:k8s,tag:private,tag:family"
   ```

**Key Differences**:
- **Public**: Accessible from internet via Tailscale Funnel
- **Private**: Only accessible via Tailscale mesh network (family only)

### Step 4: Deploy Example Services

**Deploy Public Service**:
```bash
# Deploy the Tailscale-enabled frontend
kubectl apply -f apps/base/simple-frontend/service-tailscale.yaml
```

**Deploy Private Service** (Example):
```bash
# Deploy the private admin dashboard
kubectl apply -k apps/base/admin-dashboard/
```

**Verification**:
```bash
# Check Tailscale services
kubectl get services -A -o wide | grep tailscale

# Check Tailscale operator created proxy pods
kubectl get pods -A | grep ts-
```

### Step 5: Access Control Configuration

**Thought Process**: Tailscale ACLs (Access Control Lists) define who can access what services. We want family members to access private services, while public services are open to everyone.

**Example ACL Configuration**:
```json
{
  "tagOwners": {
    "tag:k8s": ["your-email@example.com"],
    "tag:public": ["your-email@example.com"],
    "tag:private": ["your-email@example.com"],
    "tag:family": ["your-email@example.com"]
  },
  "groups": {
    "group:family": [
      "your-email@example.com",
      "spouse@example.com",
      "kid1@example.com",
      "kid2@example.com"
    ]
  },
  "acls": [
    {
      "action": "accept",
      "src": ["*"],
      "dst": ["tag:public:*"]
    },
    {
      "action": "accept",
      "src": ["group:family"],
      "dst": ["tag:private:*", "tag:family:*"]
    }
  ]
}
```

**Apply ACL**:
1. Go to https://login.tailscale.com/admin/acls
2. Paste the configuration above
3. Replace email addresses with your family's emails
4. Save and apply

### Step 6: DNS Configuration

**Thought Process**: For public services, we want to use our custom domain. For private services, we'll use Tailscale's MagicDNS.

**Public Service DNS**:
- Update `dknathalage.dev` DNS to point to your Tailscale Funnel URL
- Tailscale will provide the funnel URL after service deployment

**Private Service Access**:
- Family members access via `admin-dashboard.tail[xxx].ts.net`
- No DNS changes needed - MagicDNS handles this automatically

## DNS Configuration Steps

**For Public Services (Custom Domain)**:
1. After deploying Tailscale services, get the Funnel URL from Tailscale admin console
2. Update your DNS provider (where dknathalage.dev is managed):
   ```
   Type: CNAME
   Name: @ (or dknathalage.dev)
   Value: simple-frontend.tail[xxx].ts.net
   ```
3. Wait for DNS propagation (usually 5-15 minutes)
4. Test: `curl -I https://dknathalage.dev`

**For Private Services**:
- No DNS changes needed
- Access via MagicDNS: `admin-dashboard.tail[xxx].ts.net`
- Family members just need Tailscale client installed

## Created Files Summary

### Tailscale Infrastructure
- `apps/base/tailscale/app/namespace.yaml` - Dedicated namespace with privileged access
- `apps/base/tailscale/app/crds.yaml` - Custom Resource Definitions for Tailscale
- `apps/base/tailscale/app/operator.yaml` - Main Tailscale operator deployment
- `apps/base/tailscale/kustomization.yaml` - Kustomize configuration for Tailscale

### Service Configurations
- `apps/base/simple-frontend/service-tailscale.yaml` - Public service with Funnel enabled
- `apps/base/admin-dashboard/` - Complete private service example
  - `deployment.yaml` - Private admin dashboard deployment
  - `service.yaml` - Private service (mesh-only access)
  - `configmap.yaml` - Dashboard content
  - `kustomization.yaml` - Kustomize configuration

### Automation and Documentation
- `deploy-tailscale.sh` - Automated deployment script
- `FAMILY_ONBOARDING.md` - Family member guide for accessing services
- `TESTING_VALIDATION.md` - Comprehensive testing procedures

## Migration Benefits Achieved

### ✅ Single Solution
- **Before**: Cloudflare Tunnel + separate VPN solution needed
- **After**: Tailscale handles both public and private access

### ✅ True End-to-End Encryption
- **Before**: Cloudflare could decrypt and inspect all traffic
- **After**: Direct encrypted connections to your cluster

### ✅ Free for Personal Use
- **Before**: Potential costs for multiple solutions
- **After**: $0/month for up to 20 devices

### ✅ Family-Friendly
- **Before**: Complex VPN configurations
- **After**: Simple mobile apps for all family members

### ✅ Granular Access Control
- **Before**: All-or-nothing access
- **After**: Per-service, per-user access control

### ✅ Zero Configuration
- **Before**: Manual port forwarding, IP management
- **After**: Automatic service discovery and networking

## Next Steps

1. **Get Tailscale OAuth Credentials**:
   - Visit https://login.tailscale.com/admin/settings/oauth
   - Create OAuth client with `devices` and `all` scopes
   - Save Client ID and Client Secret

2. **Deploy Tailscale**:
   ```bash
   export TAILSCALE_CLIENT_ID=your_client_id
   export TAILSCALE_CLIENT_SECRET=your_client_secret
   ./deploy-tailscale.sh
   ```

3. **Configure ACLs**:
   - Visit https://login.tailscale.com/admin/acls
   - Add family members to appropriate groups
   - Configure service access permissions

4. **Update DNS**:
   - Point dknathalage.dev to your Tailscale Funnel URL
   - Test public access

5. **Onboard Family**:
   - Share `FAMILY_ONBOARDING.md` with family members
   - Help them install Tailscale apps
   - Test access from their devices

6. **Cleanup (Optional)**:
   - Remove Cloudflare tunnel once Tailscale is fully tested
   - Update any references to old URLs

## Support Resources

- **Tailscale Documentation**: https://tailscale.com/kb/
- **Kubernetes Operator Guide**: https://github.com/tailscale/tailscale/tree/main/cmd/k8s-operator
- **Tailscale Community**: https://forum.tailscale.com/
- **This Migration Guide**: All files created in your cluster repository

---

*Migration guide complete! You now have a comprehensive end-to-end encrypted solution for your homelab.*