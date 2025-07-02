# 🔧 Fix Cloudflare Tunnel Configuration

## Current Issue
The tunnel is working but using the wrong configuration from the Cloudflare dashboard. It's pointing to `http://dknathalage.dev` instead of our internal service.

## Solution: Update via Cloudflare Dashboard

### Step 1: Access Cloudflare Dashboard
1. Go to [Cloudflare Dashboard](https://dash.cloudflare.com)
2. Select your account
3. Go to **Zero Trust** > **Access** > **Tunnels**
4. Find your tunnel: `dknathalage-dev-tunnel` (ID: `0c6401eb-1e2c-4250-a875-a311e7eabe7c`)

### Step 2: Update Public Hostnames
1. Click on your tunnel
2. Go to **Public Hostnames** tab
3. You should see entries for `dknathalage.dev`

### Step 3: Update the Service URLs
For each hostname entry:

**Domain**: `dknathalage.dev`
- **Service**: Change from `http://dknathalage.dev` 
- **To**: `http://simple-frontend-service.default.svc.cluster.local:80`

**Domain**: `www.dknathalage.dev` (if it exists)
- **Service**: `http://simple-frontend-service.default.svc.cluster.local:80`

### Step 4: Save Changes
Click **Save** to apply the changes.

## Alternative: Test with Port Forwarding

If you want to test immediately without dashboard changes:

```bash
# Forward the simple-frontend service to localhost
kubectl port-forward svc/simple-frontend-service 8080:80 -n default

# In the dashboard, temporarily set the service to:
# http://host.docker.internal:8080
# (This works if your cluster can reach the host machine)
```

## Verification

After updating the dashboard:
1. Wait 1-2 minutes for changes to propagate
2. Check the tunnel logs:
   ```bash
   kubectl logs -f -n cloudflared deployment/cloudflared
   ```
3. Look for "Updated to new configuration" with the correct service URL
4. Test the website: `https://dknathalage.dev`

## Current Status Summary

✅ **Kubernetes Setup**: Perfect  
✅ **Simple Frontend**: Working  
✅ **Cloudflare Tunnel**: Connected  
✅ **DNS**: Should be configured  
⚠️ **Routing**: Needs dashboard update  

Once you update the dashboard configuration, your website should be live at `https://dknathalage.dev`! 