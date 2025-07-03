# Testing and Validation Guide

This guide provides comprehensive testing procedures for your Tailscale migration.

## Pre-Deployment Testing

### 1. Verify Kubernetes Cluster
```bash
# Check cluster status
kubectl cluster-info

# Check node status
kubectl get nodes

# Check available resources
kubectl top nodes
```

### 2. Test OAuth Credentials
```bash
# Verify secret creation
kubectl get secret operator-oauth -n tailscale-system -o yaml

# Check secret has correct keys
kubectl get secret operator-oauth -n tailscale-system -o jsonpath='{.data}' | jq
```

## Deployment Testing

### 1. Operator Deployment
```bash
# Check operator pod status
kubectl get pods -n tailscale-system

# Check operator logs for errors
kubectl logs -n tailscale-system deployment/tailscale-operator --tail=50

# Verify CRDs are installed
kubectl get crd | grep tailscale
```

### 2. Service Deployment
```bash
# Check services with Tailscale annotations
kubectl get services -A -o jsonpath='{range .items[*]}{.metadata.namespace}{"\t"}{.metadata.name}{"\t"}{.metadata.annotations.tailscale\.com/expose}{"\n"}{end}' | grep -v "null"

# Look for Tailscale proxy pods
kubectl get pods -A | grep ts-

# Check proxy pod logs
kubectl logs -n default ts-simple-frontend-tailscale-xxxxx
```

## Functional Testing

### 1. Public Service Testing (Tailscale Funnel)

**Test from outside the network:**
```bash
# Get the funnel URL from Tailscale admin console
# Test public access (should work without Tailscale client)
curl -I https://simple-frontend.tail[xxx].ts.net

# Test with custom domain (after DNS update)
curl -I https://dknathalage.dev
```

**Expected Results:**
- ✅ HTTP 200 response
- ✅ Accessible from any device/network
- ✅ No Tailscale client required

### 2. Private Service Testing (Tailscale Mesh)

**Test from Tailscale-connected device:**
```bash
# Test private service access
curl -I https://admin-dashboard.tail[xxx].ts.net

# Test without Tailscale (should fail)
# Turn off Tailscale client and try again
curl -I https://admin-dashboard.tail[xxx].ts.net
```

**Expected Results:**
- ✅ HTTP 200 when Tailscale is connected
- ❌ Connection refused/timeout when Tailscale is off
- ✅ Service only accessible to family members

## Security Testing

### 1. Access Control Testing
```bash
# Test from unauthorized device (should fail)
# Test from family member device (should work)
# Test from admin device (should work)
```

### 2. Network Isolation Testing
```bash
# Test that private services are not accessible via public internet
nmap -p 80,443 your-public-ip

# Should not show ports for private services
```

## Performance Testing

### 1. Latency Testing
```bash
# Test response times
time curl -s https://simple-frontend.tail[xxx].ts.net > /dev/null
time curl -s https://admin-dashboard.tail[xxx].ts.net > /dev/null
```

### 2. Bandwidth Testing
```bash
# Test large file download if applicable
curl -w "%{time_total}" -o /dev/null https://your-service.tail[xxx].ts.net/large-file
```

## Integration Testing

### 1. DNS Resolution Testing
```bash
# Test MagicDNS resolution
nslookup simple-frontend.tail[xxx].ts.net
nslookup admin-dashboard.tail[xxx].ts.net

# Test custom domain resolution
nslookup dknathalage.dev
```

### 2. Cross-Platform Testing
- Test on iOS device
- Test on Android device  
- Test on Windows computer
- Test on Mac computer
- Test on Linux device

## Monitoring and Logging

### 1. Tailscale Admin Console
Visit https://login.tailscale.com/admin/machines
- ✅ All devices show as connected
- ✅ Services show as online
- ✅ No connection errors

### 2. Kubernetes Monitoring
```bash
# Monitor resource usage
kubectl top pods -n tailscale-system

# Check for any pod restarts
kubectl get pods -A | grep -E "(Restart|Error|CrashLoop)"

# Monitor operator logs
kubectl logs -n tailscale-system deployment/tailscale-operator -f
```

## Rollback Testing

### 1. Prepare Rollback
```bash
# Keep Cloudflare deployment ready
kubectl get deployment cloudflared -n cloudflared -o yaml > cloudflared-backup.yaml

# Test rollback procedure
kubectl apply -f cloudflared-backup.yaml
```

### 2. Validate Rollback
```bash
# Test that Cloudflare tunnel still works
curl -I https://dknathalage.dev

# Verify services are accessible
kubectl get pods -n cloudflared
```

## Test Scenarios

### Scenario 1: Family Member Access
1. Family member installs Tailscale app
2. Signs in with approved email
3. Accesses private services successfully
4. Cannot access admin-only services

### Scenario 2: Public Access
1. Random internet user visits dknathalage.dev
2. Site loads without Tailscale
3. Private services remain inaccessible
4. No sensitive information exposed

### Scenario 3: Device Compromise
1. Family member's device is compromised
2. Admin removes device from Tailscale
3. Device loses access to private services
4. Other family members retain access

### Scenario 4: Network Failure
1. Internet connection is lost
2. Local services remain accessible via Tailscale
3. Public services become unavailable
4. Family services work on local network

## Common Issues and Solutions

### Issue: Operator Pod Not Starting
**Symptoms:** Operator pod in CrashLoopBackOff
**Solutions:**
```bash
# Check OAuth secret
kubectl get secret operator-oauth -n tailscale-system

# Verify CRDs are installed
kubectl get crd | grep tailscale

# Check operator logs
kubectl logs -n tailscale-system deployment/tailscale-operator
```

### Issue: Proxy Pods Not Created
**Symptoms:** No ts-* pods appearing
**Solutions:**
```bash
# Check service annotations
kubectl get service simple-frontend-tailscale -o yaml

# Verify operator is running
kubectl get pods -n tailscale-system

# Check operator logs for errors
kubectl logs -n tailscale-system deployment/tailscale-operator
```

### Issue: Services Not Accessible
**Symptoms:** Connection refused or timeout
**Solutions:**
```bash
# Verify Tailscale client is connected
tailscale status

# Check DNS resolution
nslookup service-name.tail[xxx].ts.net

# Test from inside cluster
kubectl run debug --image=curlimages/curl --rm -it --restart=Never -- curl service-name
```

## Success Criteria

The migration is successful when:
- ✅ All public services accessible via Tailscale Funnel
- ✅ All private services accessible only to family members
- ✅ No unauthorized access to private services
- ✅ Family members can easily access services
- ✅ Performance is acceptable (<2s response time)
- ✅ No sensitive data exposed publicly
- ✅ Rollback procedure works if needed

## Post-Migration Checklist

- [ ] Update DNS records for custom domains
- [ ] Configure Tailscale ACLs for family access
- [ ] Test all services from multiple devices
- [ ] Onboard family members
- [ ] Document any custom configurations
- [ ] Set up monitoring alerts
- [ ] Schedule regular security reviews
- [ ] Plan for certificate management
- [ ] Document troubleshooting procedures
- [ ] Create backup/recovery procedures

---

*This testing guide ensures a secure and reliable migration to Tailscale.*