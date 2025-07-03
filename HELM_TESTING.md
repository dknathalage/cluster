# Helm-based Tailscale Testing Guide

This guide provides testing procedures specifically for the Helm-based Tailscale deployment.

## Pre-Deployment Testing

### 1. Verify Flux is Running
```bash
# Check Flux system pods
kubectl get pods -n flux-system

# Check Flux controllers are ready
kubectl get deployments -n flux-system
```

### 2. Test OAuth Credentials
```bash
# Verify environment variables are set
echo "Client ID: ${TAILSCALE_CLIENT_ID:0:10}..."
echo "Client Secret: ${TAILSCALE_CLIENT_SECRET:0:10}..."

# Test OAuth client at Tailscale (optional)
curl -s "https://api.tailscale.com/api/v2/tailnet/-/devices" \
  -H "Authorization: Bearer $(echo -n "$TAILSCALE_CLIENT_ID:$TAILSCALE_CLIENT_SECRET" | base64)"
```

## Helm Deployment Testing

### 1. HelmRepository Testing
```bash
# Check HelmRepository is created
kubectl get helmrepository tailscale -n flux-system

# Check repository status
kubectl describe helmrepository tailscale -n flux-system

# Verify repository URL is accessible
curl -I https://pkgs.tailscale.com/helmcharts/index.yaml
```

### 2. HelmRelease Testing
```bash
# Check HelmRelease status
kubectl get helmrelease tailscale-operator -n tailscale

# Check release conditions
kubectl describe helmrelease tailscale-operator -n tailscale

# Check Helm release in cluster
helm list -n tailscale
```

### 3. Chart Version and Values Testing
```bash
# Check what chart version was deployed
kubectl get helmrelease tailscale-operator -n tailscale -o jsonpath='{.spec.chart.spec.version}'

# Check deployed values
helm get values tailscale-operator -n tailscale

# Check all deployed resources
helm get manifest tailscale-operator -n tailscale
```

## Flux Integration Testing

### 1. GitOps Flow Testing
```bash
# Check Kustomization status
kubectl get kustomization apps -n flux-system

# Force reconciliation
flux reconcile kustomization apps

# Check reconciliation logs
kubectl logs -n flux-system deployment/kustomize-controller -f
```

### 2. Secret Management Testing
```bash
# Verify OAuth secret is created correctly
kubectl get secret operator-oauth -n tailscale -o yaml

# Check secret data (base64 encoded)
kubectl get secret operator-oauth -n tailscale -o jsonpath='{.data.client_id}' | base64 -d
kubectl get secret operator-oauth -n tailscale -o jsonpath='{.data.client_secret}' | base64 -d
```

## Operator Health Testing

### 1. Pod and Deployment Testing
```bash
# Check operator deployment
kubectl get deployment tailscale-operator -n tailscale

# Check operator pods
kubectl get pods -n tailscale -l app=tailscale-operator

# Check pod logs
kubectl logs -n tailscale deployment/tailscale-operator --tail=50

# Check pod resources
kubectl top pods -n tailscale
```

### 2. RBAC and Permissions Testing
```bash
# Check ServiceAccount
kubectl get serviceaccount tailscale-operator -n tailscale

# Check ClusterRole
kubectl get clusterrole | grep tailscale

# Check ClusterRoleBinding
kubectl get clusterrolebinding | grep tailscale

# Test operator permissions (should not error)
kubectl auth can-i get secrets --as=system:serviceaccount:tailscale:tailscale-operator
kubectl auth can-i create services --as=system:serviceaccount:tailscale:tailscale-operator
```

## Service Exposure Testing

### 1. Tailscale Service Annotations
```bash
# Deploy test services
kubectl apply -f apps/base/simple-frontend/service-tailscale.yaml
kubectl apply -k apps/base/admin-dashboard/

# Check services with Tailscale annotations
kubectl get services -A -o jsonpath='{range .items[*]}{.metadata.namespace}{"\t"}{.metadata.name}{"\t"}{.metadata.annotations.tailscale\.com/expose}{"\t"}{.metadata.annotations.tailscale\.com/funnel}{"\n"}{end}' | grep -v "null"
```

### 2. Proxy Pod Creation Testing
```bash
# Wait for proxy pods to be created
kubectl get pods -A | grep ts-

# Check proxy pod logs
kubectl logs -n default ts-simple-frontend-tailscale-xxxxx

# Check proxy pod status
kubectl describe pod -n default ts-simple-frontend-tailscale-xxxxx
```

## Helm-Specific Troubleshooting

### Issue: HelmRepository Not Ready
```bash
# Check repository status
kubectl describe helmrepository tailscale -n flux-system

# Check source-controller logs
kubectl logs -n flux-system deployment/source-controller

# Force repository update
flux reconcile source helm tailscale
```

### Issue: HelmRelease Failed
```bash
# Check release status
kubectl describe helmrelease tailscale-operator -n tailscale

# Check helm-controller logs
kubectl logs -n flux-system deployment/helm-controller

# Check Helm release directly
helm status tailscale-operator -n tailscale
```

### Issue: Values Not Applied
```bash
# Check deployed values
helm get values tailscale-operator -n tailscale

# Compare with expected values
diff <(helm get values tailscale-operator -n tailscale) <(kubectl get helmrelease tailscale-operator -n tailscale -o jsonpath='{.spec.values}')

# Force HelmRelease reconciliation
flux reconcile helmrelease tailscale-operator -n tailscale
```

## Chart Update Testing

### 1. Test Chart Version Updates
```bash
# Check available chart versions
helm search repo tailscale/tailscale-operator --versions

# Update HelmRelease to new version
kubectl patch helmrelease tailscale-operator -n tailscale --type='merge' -p='{"spec":{"chart":{"spec":{"version":"1.75.0"}}}}'

# Watch upgrade progress
kubectl get helmrelease tailscale-operator -n tailscale -w
```

### 2. Test Values Updates
```bash
# Update operator configuration
kubectl patch helmrelease tailscale-operator -n tailscale --type='merge' -p='{"spec":{"values":{"operatorConfig":{"logging":"debug"}}}}'

# Verify changes are applied
helm get values tailscale-operator -n tailscale
```

## Rollback Testing

### 1. Helm Rollback
```bash
# Check release history
helm history tailscale-operator -n tailscale

# Rollback to previous version
helm rollback tailscale-operator 1 -n tailscale

# Verify rollback
helm status tailscale-operator -n tailscale
```

### 2. GitOps Rollback
```bash
# Revert changes in Git (simulate)
git revert HEAD

# Force reconciliation
flux reconcile kustomization apps
```

## Performance Testing

### 1. Resource Usage Testing
```bash
# Check operator resource usage
kubectl top pods -n tailscale

# Check proxy pod resource usage
kubectl top pods -A | grep ts-

# Check memory and CPU limits
kubectl describe pod -n tailscale -l app=tailscale-operator
```

### 2. Scalability Testing
```bash
# Test multiple service exposures
for i in {1..5}; do
  kubectl create service clusterip test-service-$i --tcp=80:80
  kubectl annotate service test-service-$i tailscale.com/expose="true"
done

# Check proxy pod creation
kubectl get pods -A | grep ts-test-service
```

## Success Criteria for Helm Deployment

The Helm-based deployment is successful when:
- ✅ HelmRepository is Ready and accessible
- ✅ HelmRelease is Ready and deployed
- ✅ Operator pod is Running and healthy
- ✅ OAuth authentication is working
- ✅ Services with annotations create proxy pods
- ✅ Flux can manage chart updates
- ✅ Rollback procedures work correctly
- ✅ Resource usage is within limits
- ✅ RBAC permissions are correct

## Monitoring Helm Operations

### Continuous Monitoring
```bash
# Watch HelmRelease status
kubectl get helmrelease -A -w

# Monitor Flux logs
kubectl logs -n flux-system deployment/helm-controller -f

# Monitor operator logs
kubectl logs -n tailscale deployment/tailscale-operator -f
```

### Alerts and Notifications
Consider setting up alerts for:
- HelmRelease failures
- Chart update failures
- Operator pod crashes
- OAuth authentication failures

---

*This guide ensures reliable Helm-based Tailscale deployments with proper GitOps integration.*