# Cloudflare Tunnel Setup Guide

This guide will help you configure Cloudflare Tunnel to route traffic from `dknathalage.dev` to your simple frontend.

## Prerequisites

1. Domain `dknathalage.dev` managed by Cloudflare
2. Cloudflare account with access to Zero Trust
3. `cloudflared` CLI installed locally
4. Kubernetes cluster with `kubectl` access

## Step 1: Install Cloudflared CLI (if not already installed)

```bash
# macOS
brew install cloudflare/cloudflare/cloudflared

# Linux
wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
sudo dpkg -i cloudflared-linux-amd64.deb
```

## Step 2: Authenticate with Cloudflare

```bash
cloudflared tunnel login
```

This will open a browser window for authentication.

## Step 3: Create a Tunnel

```bash
cloudflared tunnel create dknathalage-dev-tunnel
```

This will create a tunnel and generate a credentials file. Note the **Tunnel ID** from the output.

## Step 4: Update Configuration

1. Find your tunnel credentials file (usually in `~/.cloudflared/`)
2. Update the ConfigMap in `apps/base/cloudflared/app/configmap.yaml`:
   - Replace `YOUR_TUNNEL_ID` with your actual tunnel ID

## Step 5: Create Kubernetes Secret

Create the secret with your tunnel credentials:

```bash
# Replace with your actual credentials file path
kubectl create secret generic cloudflared-secret \
  --from-file=credentials.json=/path/to/your/tunnel-credentials.json \
  --namespace=cloudflared
```

## Step 6: Configure DNS Records

Set up DNS records in your Cloudflare dashboard:

1. Go to your domain's DNS settings in Cloudflare
2. Add the following CNAME records:

```
Type: CNAME
Name: dknathalage.dev (or @)
Target: YOUR_TUNNEL_ID.cfargotunnel.com
Proxied: Yes

Type: CNAME  
Name: www
Target: YOUR_TUNNEL_ID.cfargotunnel.com
Proxied: Yes
```

Replace `YOUR_TUNNEL_ID` with your actual tunnel ID.

## Step 7: Deploy the Changes

```bash
# Commit and push your changes
git add .
git commit -m "Add simple frontend and configure Cloudflare Tunnel"
git push

# If using local cluster, you can also apply directly
kubectl apply -k apps/overlays/local/
```

## Step 8: Verify the Setup

1. Check if pods are running:
```bash
kubectl get pods -n cloudflared
kubectl get pods -n default | grep simple-frontend
```

2. Check tunnel status:
```bash
kubectl logs -n cloudflared deployment/cloudflared
```

3. Test the website:
```bash
curl -H "Host: dknathalage.dev" http://localhost
# or visit https://dknathalage.dev in your browser
```

## Troubleshooting

### Common Issues

1. **Tunnel credentials not found**
   - Ensure the secret is created in the correct namespace
   - Verify the credentials file path

2. **DNS not resolving**
   - Check DNS propagation: `dig dknathalage.dev`
   - Ensure CNAME records are correctly configured

3. **Service not reachable**
   - Verify frontend service is running: `kubectl get svc simple-frontend-service`
   - Check service endpoints: `kubectl get endpoints simple-frontend-service`

### Debug Commands

```bash
# Check Cloudflared logs
kubectl logs -n cloudflared deployment/cloudflared -f

# Check frontend logs
kubectl logs deployment/simple-frontend -f

# Test internal connectivity
kubectl run test-pod --image=curlimages/curl --rm -it --restart=Never -- sh
# Then inside the pod:
curl http://simple-frontend-service.default.svc.cluster.local
```

## Configuration Files Updated

The following files have been created/updated:

- `apps/base/simple-frontend/` - Simple frontend application
- `apps/base/cloudflared/app/configmap.yaml` - Tunnel configuration
- `apps/base/cloudflared/app/deployment.yaml` - Updated deployment
- `apps/overlays/local/simple-frontend/` - Local overlay for frontend
- `apps/overlays/local/kustomization.yaml` - Added frontend to local deployment

## Next Steps

Once everything is working:

1. Consider setting up SSL certificates (Cloudflare handles this automatically)
2. Add monitoring and logging
3. Set up additional routes if needed
4. Configure custom error pages

Your simple frontend should now be accessible at `https://dknathalage.dev`! 