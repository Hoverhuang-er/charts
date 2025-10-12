# New Features Summary

## 新功能概述 (New Features Overview)

**Date:** October 12, 2025  
**Version:** 0.1.0

---

## 🆕 Added Features

### 1. **Kubernetes Version Compatibility**

Added support for multiple Kubernetes versions with automatic `securityContext` handling:

- **Supported Versions:**
  - 1.32 (default)
  - 1.28
  - 1.26
  - 1.24
  - pre-1.24

- **Behavior:**
  - For Kubernetes versions **before 1.24**, `securityContext` is automatically **disabled**
  - For versions **1.24 and later**, `securityContext` is **enabled**

- **Configuration:**
  ```yaml
  kubernetesVersion: "1.32"  # or "1.28", "1.26", "1.24", "pre-1.24"
  ```

- **Files Modified:**
  - `values.yaml` - Added `kubernetesVersion` parameter
  - `templates/deployment.yaml` - Conditional securityContext rendering
  - `values.schema.json` - Schema validation for version

---

### 2. **Ingress Support with Multiple Controllers**

Ingress is now **enabled by default** with support for three ingress controller types:

#### **Controller Types:**

1. **Azure Load Balancer** (default)
   - Best for: Direct Azure integration
   - Annotations: `service.beta.kubernetes.io/azure-load-balancer-internal`

2. **Application Gateway Ingress Controller (AGIC)**
   - Best for: Azure Application Gateway integration
   - Annotations: `kubernetes.io/ingress.class: azure/application-gateway`
   - Ingress Class: `azure-application-gateway`

3. **NGINX Ingress Controller**
   - Best for: Standard NGINX ingress
   - Annotations: `kubernetes.io/ingress.class: nginx`
   - Ingress Class: `nginx`

#### **Configuration:**

```yaml
ingress:
  enabled: true
  controllerType: azure-loadbalancer  # or application-gateway, nginx
  hosts:
    - host: document-intelligence.example.com
      paths:
        - path: /
          pathType: Prefix
  tls: []
```

#### **Examples:**

**Azure Load Balancer:**
```bash
helm install doc-intel ./document-intelligence \
  --set ingress.controllerType=azure-loadbalancer \
  --set ingress.hosts[0].host=doc-intel.example.com
```

**Application Gateway:**
```bash
helm install doc-intel ./document-intelligence \
  --set ingress.controllerType=application-gateway \
  --set ingress.hosts[0].host=doc-intel.example.com
```

**NGINX:**
```bash
helm install doc-intel ./document-intelligence \
  --set ingress.controllerType=nginx \
  --set ingress.hosts[0].host=doc-intel.example.com
```

- **Files Modified:**
  - `values.yaml` - Added ingress configuration with controllerType
  - `templates/ingress.yaml` - Dynamic annotation and ingressClass based on controllerType
  - `values.schema.json` - Schema validation for ingress

---

### 3. **Service Created by Default**

The Kubernetes Service is now **always created** to work with Ingress:

```yaml
service:
  type: ClusterIP
  port: 5000
  targetPort: 5000
```

- Service type can still be changed to `NodePort` or `LoadBalancer` as needed

---

### 4. **Multi-Language Documentation**

Added complete **Chinese (Simplified)** documentation alongside English:

#### **Documentation Files:**

| English | 简体中文 (Chinese) |
|---------|------------------|
| `README.md` | `README.zh-CN.md` |
| `QUICKSTART.md` | `QUICKSTART.zh-CN.md` |

#### **Language Switcher:**

Both documentation files include a language switcher at the top:

```markdown
**Language:** [English](README.md) | [简体中文](README.zh-CN.md)
```

#### **Content Coverage:**

- Installation instructions
- Configuration parameters
- Usage examples
- Troubleshooting guides
- Security best practices
- All new features (Ingress, Kubernetes versions)

---

## 📝 Updated Files

### Configuration Files
- ✅ `values.yaml` - Added kubernetesVersion and ingress configuration
- ✅ `values.schema.json` - Updated schema with new fields

### Templates
- ✅ `templates/deployment.yaml` - Conditional securityContext
- ✅ `templates/ingress.yaml` - Dynamic controller configuration

### Documentation
- ✅ `README.md` - Added new sections for Ingress and K8s versions
- ✅ `QUICKSTART.md` - Added configuration examples
- 🆕 `README.zh-CN.md` - Complete Chinese documentation
- 🆕 `QUICKSTART.zh-CN.md` - Chinese quick start guide

### Examples
- ✅ `examples.yaml` - Added 7 comprehensive examples including:
  - Example 5: Application Gateway Ingress
  - Example 6: Pre-1.24 Kubernetes compatibility
  - Example 7: High-performance with NGINX

---

## 🧪 Testing

All changes have been validated:

```bash
helm lint Microsoft/azure-ai-services/charts/document-intelligence
# Result: 1 chart(s) linted, 0 chart(s) failed ✓
```

---

## 📊 Configuration Matrix

| Feature | Options | Default |
|---------|---------|---------|
| Kubernetes Version | 1.32, 1.28, 1.26, 1.24, pre-1.24 | `1.32` |
| Ingress Enabled | true, false | `true` |
| Ingress Controller | azure-loadbalancer, application-gateway, nginx | `azure-loadbalancer` |
| Service Type | ClusterIP, NodePort, LoadBalancer | `ClusterIP` |
| Service Port | Any integer | `5000` |
| Documentation Language | English, 简体中文 | Both available |

---

## 🚀 Migration Guide

### From Previous Version

If you're upgrading from the previous version:

1. **Ingress is now enabled by default**
   - To disable: `--set ingress.enabled=false`

2. **Set your Kubernetes version**
   ```bash
   helm upgrade document-intelligence ./document-intelligence \
     --set kubernetesVersion="1.28"
   ```

3. **Choose ingress controller**
   ```bash
   helm upgrade document-intelligence ./document-intelligence \
     --set ingress.controllerType="nginx"
   ```

---

## 📖 Usage Examples

### Complete Example with All New Features

```yaml
# values-production.yaml
kubernetesVersion: "1.32"

documentIntelligence:
  modelType: layout
  azure:
    billingEndpoint: "https://my-resource.cognitiveservices.azure.com"
    apiKey: "my-api-key"
    downloadLicense: false

ingress:
  enabled: true
  controllerType: nginx
  hosts:
    - host: document-intelligence.company.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: doc-intel-tls
      hosts:
        - document-intelligence.company.com

service:
  type: ClusterIP
  port: 5000

resources:
  requests:
    cpu: "8"
    memory: 16Gi
  limits:
    cpu: "8"
    memory: 24Gi
```

Deploy:
```bash
helm install document-intelligence ./document-intelligence \
  -f values-production.yaml
```

---

## 🔗 References

- **English Documentation:** [README.md](README.md)
- **中文文档:** [README.zh-CN.md](README.zh-CN.md)
- **Quick Start (EN):** [QUICKSTART.md](QUICKSTART.md)
- **快速入门 (中文):** [QUICKSTART.zh-CN.md](QUICKSTART.zh-CN.md)
- **Examples:** [examples.yaml](examples.yaml)
- **Schema:** [values.schema.json](values.schema.json)

---

## 💡 Best Practices

1. **Always specify Kubernetes version** for predictable behavior
2. **Choose the right ingress controller** for your environment:
   - Azure Load Balancer: Simple Azure deployments
   - Application Gateway: Enterprise Azure with WAF
   - NGINX: Multi-cloud or on-premises
3. **Use ClusterIP with Ingress** for best practices (default)
4. **Read documentation in your preferred language** (EN/中文)
5. **Test with examples** before customizing

---

## ✅ Checklist for Deployment

- [ ] Choose Kubernetes version (`kubernetesVersion`)
- [ ] Select ingress controller type (`ingress.controllerType`)
- [ ] Configure hostname (`ingress.hosts`)
- [ ] Set up TLS certificates if needed (`ingress.tls`)
- [ ] Verify resource requirements (`resources`)
- [ ] Download license file (initial setup only)
- [ ] Switch to disconnected mode
- [ ] Test API endpoint
- [ ] Verify ingress routing

---

**For detailed instructions, see:**
- 🇬🇧 English: [README.md](README.md) | [QUICKSTART.md](QUICKSTART.md)
- 🇨🇳 中文: [README.zh-CN.md](README.zh-CN.md) | [QUICKSTART.zh-CN.md](QUICKSTART.zh-CN.md)
