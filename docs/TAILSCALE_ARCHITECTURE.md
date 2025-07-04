# Tailscale VPN Architecture for Public and Private Endpoints

## Overview

This document describes the architecture of Tailscale VPN implementation for handling both public and private endpoints in a Kubernetes environment. The system provides secure, scalable networking with two distinct access patterns: public internet access via Tailscale Funnel and private mesh network access for family/internal services.

## Architecture Components

### 1. Core Infrastructure

```
┌─────────────────────────────────────────────────────────────┐
│                    Kubernetes Cluster                       │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐│
│  │   Tailscale     │  │   Admin         │  │   Simple        ││
│  │   Operator      │  │   Dashboard     │  │   Frontend      ││
│  │   (v1.74.1)     │  │   (Private)     │  │   (Public)      ││
│  └─────────────────┘  └─────────────────┘  └─────────────────┘│
│           │                     │                     │       │
│           └─────────────────────┼─────────────────────┘       │
│                                 │                             │
└─────────────────────────────────┼─────────────────────────────┘
                                  │
                    ┌─────────────┼─────────────┐
                    │      Tailscale Mesh       │
                    │   (tail2af8c3.ts.net)    │
                    └─────────────┼─────────────┘
                                  │
        ┌─────────────────────────┼─────────────────────────┐
        │                         │                         │
        ▼                         ▼                         ▼
┌─────────────┐         ┌─────────────────┐         ┌─────────────┐
│   Family    │         │   Public        │         │  External   │
│   Members   │         │   Internet      │         │    DNS      │
│  (Private)  │         │   (Funnel)      │         │ (Cloudflare)│
└─────────────┘         └─────────────────┘         └─────────────┘
```

### 2. Tailscale Operator

**Location**: `apps/base/tailscale/`

The Tailscale Operator serves as the core component that manages Tailscale networking within the Kubernetes cluster.

**Key Features**:
- **Version**: Pinned to v1.74.1 for stability
- **OAuth Authentication**: Uses OAuth tokens from Tailscale admin console
- **Security Context**: Non-root execution with read-only filesystem
- **Resource Management**: CPU (100m-500m), Memory (128Mi-512Mi)
- **RBAC**: Dedicated service account with minimal required permissions

**Configuration**:
```yaml
apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: tailscale-operator
spec:
  chart:
    spec:
      chart: tailscale-operator
      sourceRef:
        kind: HelmRepository
        name: tailscale
      version: "1.74.1"
```

### 3. Service Access Patterns

#### 3.1 Public Service Pattern (Funnel-Enabled)

**Example**: Simple Frontend Service
**Location**: `apps/base/simple-frontend/service-tailscale.yaml`

```yaml
apiVersion: v1
kind: Service
metadata:
  name: simple-frontend-tailscale
  annotations:
    tailscale.com/expose: "true"
    tailscale.com/funnel: "true"        # Enables public internet access
    tailscale.com/hostname: "frontend"
    tailscale.com/tags: "tag:k8s,tag:public"
    external-dns.alpha.kubernetes.io/hostname: "frontend.dknathalage.dev"
    external-dns.alpha.kubernetes.io/cloudflare-proxied: "true"
```

**Access Flow**:
```
Internet → Cloudflare → frontend.dknathalage.dev → frontend.tail2af8c3.ts.net → Kubernetes Service
```

**Characteristics**:
- Publicly accessible from any internet connection
- Protected by Cloudflare proxy
- Custom domain mapping
- Tagged for public access control

#### 3.2 Private Service Pattern (Mesh-Only)

**Example**: Admin Dashboard Service
**Location**: `apps/base/admin-dashboard/service.yaml`

```yaml
apiVersion: v1
kind: Service
metadata:
  name: admin-dashboard-tailscale
  annotations:
    tailscale.com/expose: "true"
    # No funnel annotation - private access only
    tailscale.com/hostname: "admin"
    tailscale.com/tags: "tag:k8s,tag:private,tag:family"
```

**Access Flow**:
```
Family Device → Tailscale Mesh → admin.tail2af8c3.ts.net → Kubernetes Service
```

**Characteristics**:
- Accessible only via Tailscale mesh network
- Requires family member authentication
- No public internet exposure
- Tagged for private access control

### 4. DNS and Service Discovery

#### 4.1 Tailscale DNS

**Domain**: `*.tail2af8c3.ts.net`

- **Automatic Hostname Assignment**: Services receive predictable hostnames
- **Private Mesh Resolution**: DNS resolution within Tailscale network
- **Service Discovery**: Automatic service registration

#### 4.2 External DNS Integration

**Public Services**:
- **Primary Domain**: `dknathalage.dev`
- **DNS Provider**: Cloudflare
- **Proxy**: Enabled for additional security and performance
- **Automatic Management**: External DNS controller handles record creation

**Private Services**:
- **Access**: Direct via `.ts.net` domains
- **No External DNS**: Mesh-only resolution

### 5. Security Architecture

#### 5.1 Access Control Lists (ACLs)

**Tag-Based Access Control**:
- `tag:k8s` - Kubernetes-deployed services
- `tag:public` - Public internet accessible services
- `tag:private` - Private mesh-only services
- `tag:family` - Family member access

#### 5.2 OAuth Security

**Authentication Flow**:
```
1. Tailscale Admin Console → OAuth Client Creation
2. OAuth Credentials → Kubernetes Secret
3. Tailscale Operator → OAuth Token Usage
4. Service Authentication → Mesh Network Access
```

**Security Features**:
- Scoped OAuth tokens (devices, all)
- Secret management via Kubernetes secrets
- Credential rotation capability
- Admin console oversight

#### 5.3 Network Security

**Isolation Layers**:
1. **Kubernetes Network Policies**: Pod-to-pod communication control
2. **Tailscale ACLs**: Mesh network access control
3. **Service Annotations**: Exposure control
4. **Cloudflare Proxy**: Public service protection

### 6. Traffic Flow Diagrams

#### 6.1 Public Service Access

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   Internet  │───▶│ Cloudflare  │───▶│  Tailscale  │───▶│ Kubernetes  │
│   Client    │    │    Proxy    │    │   Funnel    │    │   Service   │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
        │                   │                   │                   │
        │                   │                   │                   │
        ▼                   ▼                   ▼                   ▼
   HTTP/HTTPS        DDoS Protection    Mesh Network        Pod Traffic
    Request          Load Balancing       Routing          Load Balancing
```

#### 6.2 Private Service Access

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   Family    │───▶│  Tailscale  │───▶│  Tailscale  │───▶│ Kubernetes  │
│   Device    │    │    Client   │    │   Mesh      │    │   Service   │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
        │                   │                   │                   │
        │                   │                   │                   │
        ▼                   ▼                   ▼                   ▼
   Authenticated       Encrypted         Direct Mesh        Pod Traffic
    Family Member      Connection         Routing          Load Balancing
```

### 7. Deployment Architecture

#### 7.1 GitOps Integration

**Flux v2 Workflow**:
```
Git Repository → Flux Controller → Kustomize → Helm → Kubernetes Resources
```

**Repository Structure**:
```
apps/
├── base/
│   ├── tailscale/
│   │   ├── helm-release.yaml
│   │   ├── oauth-secret.yaml
│   │   └── namespace.yaml
│   ├── simple-frontend/
│   │   └── service-tailscale.yaml
│   └── admin-dashboard/
│       └── service.yaml
└── overlays/
    └── local/
        └── kustomization.yaml
```

#### 7.2 Service Template Pattern

**Public Service Template**:
```yaml
apiVersion: v1
kind: Service
metadata:
  annotations:
    tailscale.com/expose: "true"
    tailscale.com/funnel: "true"
    tailscale.com/hostname: "<service-name>"
    tailscale.com/tags: "tag:k8s,tag:public"
    external-dns.alpha.kubernetes.io/hostname: "<service-name>.dknathalage.dev"
    external-dns.alpha.kubernetes.io/cloudflare-proxied: "true"
```

**Private Service Template**:
```yaml
apiVersion: v1
kind: Service
metadata:
  annotations:
    tailscale.com/expose: "true"
    tailscale.com/hostname: "<service-name>"
    tailscale.com/tags: "tag:k8s,tag:private,tag:family"
```

### 8. Operational Considerations

#### 8.1 Monitoring and Observability

**Tailscale Admin Console**:
- Device connectivity status
- Traffic metrics
- Access logs
- ACL violations

**Kubernetes Metrics**:
- Operator health
- Service connectivity
- Resource utilization
- Event logs

#### 8.2 Scaling and Performance

**Horizontal Scaling**:
- Operator manages multiple service exposures
- Mesh network handles connection load balancing
- Kubernetes services provide pod-level load balancing

**Performance Optimization**:
- Tailscale DERP relay optimization
- Direct peer-to-peer connections when possible
- Regional relay selection

#### 8.3 Backup and Recovery

**Configuration Backup**:
- GitOps repository contains all configuration
- OAuth credentials stored in external secret management
- Tailscale admin console as configuration source of truth

**Recovery Procedures**:
1. Redeploy operator via GitOps
2. Restore OAuth credentials
3. Verify service connectivity
4. Validate DNS resolution

### 9. Best Practices

#### 9.1 Security Best Practices

1. **Principle of Least Privilege**: Use minimal OAuth scopes
2. **Network Segmentation**: Separate public and private services
3. **Regular Auditing**: Monitor access logs and ACL compliance
4. **Credential Rotation**: Rotate OAuth tokens regularly
5. **Tag-Based Access**: Use consistent tagging strategy

#### 9.2 Operational Best Practices

1. **Version Pinning**: Pin operator version for stability
2. **Resource Limits**: Set appropriate resource limits
3. **Monitoring**: Implement comprehensive monitoring
4. **Documentation**: Maintain current documentation
5. **Testing**: Test connectivity after changes

#### 9.3 Development Best Practices

1. **Template Consistency**: Use consistent service templates
2. **Naming Conventions**: Follow predictable hostname patterns
3. **GitOps Workflow**: All changes via Git
4. **Environment Isolation**: Use overlays for different environments
5. **Validation**: Validate configurations before deployment

### 10. Troubleshooting Guide

#### 10.1 Common Issues

**Service Not Accessible**:
1. Check Tailscale operator logs
2. Verify OAuth credentials
3. Confirm service annotations
4. Test DNS resolution

**DNS Resolution Issues**:
1. Verify External DNS controller
2. Check Cloudflare DNS records
3. Test Tailscale mesh connectivity
4. Validate hostname configuration

**Performance Issues**:
1. Check DERP relay connectivity
2. Monitor resource utilization
3. Verify peer-to-peer connections
4. Review network policies

#### 10.2 Diagnostic Commands

```bash
# Check operator status
kubectl get pods -n tailscale

# View operator logs
kubectl logs -n tailscale deployment/tailscale-operator

# Check service annotations
kubectl get service <service-name> -o yaml

# Test DNS resolution
dig admin.tail2af8c3.ts.net
dig frontend.dknathalage.dev
```

### 11. Future Enhancements

#### 11.1 Planned Improvements

1. **Multi-Region Support**: Deploy across multiple regions
2. **Advanced ACLs**: Implement more granular access control
3. **Automated Testing**: Continuous connectivity validation
4. **Metrics Integration**: Enhanced monitoring and alerting
5. **Service Mesh Integration**: Istio/Linkerd integration

#### 11.2 Scalability Considerations

1. **Operator Sharding**: Multiple operators for different service types
2. **Regional Deployment**: Deploy closer to users
3. **Caching**: Implement DNS and service discovery caching
4. **Load Balancing**: Advanced load balancing strategies

## Conclusion

This Tailscale VPN architecture provides a robust, secure, and scalable solution for managing both public and private endpoints in a Kubernetes environment. The dual-pattern approach allows for flexible service exposure while maintaining security through proper access controls and network segmentation.

The architecture leverages GitOps principles for configuration management, ensuring consistent and auditable deployments. The combination of Tailscale's mesh networking, Kubernetes service discovery, and external DNS integration provides a comprehensive networking solution suitable for both family and enterprise use cases.