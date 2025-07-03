# Service Templates for DNS Strategy

## Public Service Template

Use this template for services that should be accessible from the internet.

```yaml
# Public service - accessible via *.dknathalage.dev
apiVersion: v1
kind: Service
metadata:
  name: [SERVICE-NAME]-public
  annotations:
    # Enable Tailscale exposure
    tailscale.com/expose: "true"
    # Enable Funnel for public internet access
    tailscale.com/funnel: "true"
    # Custom hostname (creates [hostname].tail2af8c3.ts.net)
    tailscale.com/hostname: "[SERVICE-NAME]"
    # Tags for access control
    tailscale.com/tags: "tag:k8s,tag:public"
  labels:
    app: [SERVICE-NAME]
    tier: public
    dns-strategy: public
spec:
  selector:
    app: [SERVICE-NAME]
  ports:
  - port: 80
    targetPort: 80
    name: http
  type: ClusterIP
```

**DNS Setup Required**:
- Cloudflare: `[SERVICE-NAME].dknathalage.dev` → `[SERVICE-NAME].tail2af8c3.ts.net` (Proxied: YES)

**Access URLs**:
- Public: `https://[SERVICE-NAME].dknathalage.dev`
- Direct: `https://[SERVICE-NAME].tail2af8c3.ts.net`

## Private Service Template

Use this template for family-only services.

```yaml
# Private service - accessible via *.pvt.dknathalage.dev (Tailscale required)
apiVersion: v1
kind: Service
metadata:
  name: [SERVICE-NAME]-private
  annotations:
    # Enable Tailscale exposure
    tailscale.com/expose: "true"
    # NO funnel = private only
    # Custom hostname (creates [hostname].tail2af8c3.ts.net)
    tailscale.com/hostname: "[SERVICE-NAME]"
    # Tags for access control - family only
    tailscale.com/tags: "tag:k8s,tag:private,tag:family"
  labels:
    app: [SERVICE-NAME]
    tier: private
    access: family-only
    dns-strategy: private
spec:
  selector:
    app: [SERVICE-NAME]
  ports:
  - port: 80
    targetPort: 80
    name: http
  type: ClusterIP
```

**DNS Setup Required**:
- Cloudflare: `[SERVICE-NAME].pvt.dknathalage.dev` → `[SERVICE-NAME].tail2af8c3.ts.net` (Proxied: NO)

**Access URLs**:
- Private: `https://[SERVICE-NAME].pvt.dknathalage.dev` (Tailscale required)
- Direct: `https://[SERVICE-NAME].tail2af8c3.ts.net` (Tailscale required)

## Example Services

### Blog Service (Public)
```yaml
apiVersion: v1
kind: Service
metadata:
  name: blog-public
  annotations:
    tailscale.com/expose: "true"
    tailscale.com/funnel: "true"
    tailscale.com/hostname: "blog"
    tailscale.com/tags: "tag:k8s,tag:public"
  labels:
    app: blog
    tier: public
    dns-strategy: public
spec:
  selector:
    app: blog
  ports:
  - port: 80
    targetPort: 80
    name: http
  type: ClusterIP
```
**Access**: `https://blog.dknathalage.dev`

### Home Assistant (Private)
```yaml
apiVersion: v1
kind: Service
metadata:
  name: home-assistant-private
  annotations:
    tailscale.com/expose: "true"
    tailscale.com/hostname: "home"
    tailscale.com/tags: "tag:k8s,tag:private,tag:family"
  labels:
    app: home-assistant
    tier: private
    access: family-only
    dns-strategy: private
spec:
  selector:
    app: home-assistant
  ports:
  - port: 8123
    targetPort: 8123
    name: http
  type: ClusterIP
```
**Access**: `https://home.pvt.dknathalage.dev` (Tailscale required)

## DNS Record Summary

After setting up services, create these Cloudflare DNS records:

### Wildcard Records (Recommended)
```
# Public services
Type: CNAME, Name: *.dknathalage.dev, Target: frontend.tail2af8c3.ts.net, Proxied: YES

# Private services  
Type: CNAME, Name: *.pvt.dknathalage.dev, Target: admin.tail2af8c3.ts.net, Proxied: NO
```

### Specific Records (Alternative)
```
# Public services
Type: CNAME, Name: frontend.dknathalage.dev, Target: frontend.tail2af8c3.ts.net, Proxied: YES
Type: CNAME, Name: blog.dknathalage.dev, Target: blog.tail2af8c3.ts.net, Proxied: YES

# Private services
Type: CNAME, Name: admin.pvt.dknathalage.dev, Target: admin.tail2af8c3.ts.net, Proxied: NO
Type: CNAME, Name: home.pvt.dknathalage.dev, Target: home.tail2af8c3.ts.net, Proxied: NO
```

## Access Patterns

### Public Services
- **Internet users**: `service.dknathalage.dev` → Cloudflare CDN → Tailscale Funnel → Service
- **Family members**: Same URL, but can also use direct Tailscale URLs

### Private Services  
- **Family members only**: `service.pvt.dknathalage.dev` → Cloudflare DNS → Tailscale MagicDNS → Service
- **Requires**: Tailscale client installed and authenticated

## Security Benefits

### Public Services
- ✅ Cloudflare DDoS protection
- ✅ Web Application Firewall (WAF)
- ✅ Rate limiting
- ✅ SSL/TLS termination
- ✅ CDN performance

### Private Services
- ✅ No public internet exposure
- ✅ End-to-end encryption (no Cloudflare proxy)
- ✅ Family-only access control
- ✅ Device-level authentication
- ✅ Tailscale ACL enforcement