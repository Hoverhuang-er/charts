# Online vs Offline Mode Configuration

This chart supports two deployment modes: **Online Mode** (with Azure connection) and **Offline Mode** (disconnected).

## Mode Comparison

| Feature | Online Mode | Offline Mode |
|---------|-------------|--------------|
| **Azure Connection** | Required | Not required |
| **downloadLicense** | `true` | `false` |
| **Environment Variables** | `eula`, `billing`, `apikey`, `DownloadLicense`, `Mounts.*` | `eula`, `Mounts.*` only |
| **License Source** | Downloaded from Azure | Pre-downloaded or from PVC |
| **Use Case** | Initial setup, license refresh | Production, air-gapped environments |
| **Internet Access** | Required during license download | Not required |

## Online Mode (downloadLicense: true)

### When to Use
- **Initial Setup**: First-time deployment when you need to download the license
- **License Refresh**: When the license expires and needs renewal
- **Testing**: Quick setup for development/testing environments

### Configuration

**Using values.yaml:**
```yaml
documentIntelligence:
  azure:
    billingEndpoint: "https://your-resource.cognitiveservices.azure.com"
    apiKey: "your-api-key"
    downloadLicense: true  # ONLINE MODE
```

**Deployment Command:**
```bash
helm install document-intelligence ./document-intelligence \
  --set documentIntelligence.azure.billingEndpoint="https://your-resource.cognitiveservices.azure.com" \
  --set documentIntelligence.azure.apiKey="your-api-key" \
  --set documentIntelligence.azure.downloadLicense=true
```

### Environment Variables Set

```yaml
env:
  - name: eula
    value: "accept"
  - name: billing                    # ← Online mode only
    value: "https://..."
  - name: apikey                     # ← Online mode only
    valueFrom:
      secretKeyRef:
        name: document-intelligence-azure
        key: apiKey
  - name: DownloadLicense            # ← Online mode only
    value: "True"
  - name: Mounts.License
    value: "/license"
  - name: Mounts.Output
    value: "/logs"
  - name: Logging.Console.LogLevel.Default
    value: "Information"
```

### What Happens
1. Pod starts with Azure credentials
2. Container connects to Azure billing endpoint
3. License file is downloaded to `/license` PVC
4. Container validates license and starts processing
5. Usage logs are sent to Azure (optional)

### After License Download

Once the license is downloaded, switch to offline mode:

```bash
# Stop the online mode deployment
helm upgrade document-intelligence ./document-intelligence \
  --set documentIntelligence.azure.downloadLicense=false

# Or delete Azure credentials from values
helm upgrade document-intelligence ./document-intelligence -f values-offline.yaml
```

## Offline Mode (downloadLicense: false)

### When to Use
- **Production Environments**: No Azure connection required
- **Air-Gapped Deployments**: No internet access
- **Security Requirements**: Minimize external connections
- **Cost Optimization**: No egress charges to Azure

### Configuration Methods

#### Method 1: Using Pre-downloaded License File

```yaml
documentIntelligence:
  azure:
    downloadLicense: false  # OFFLINE MODE
  license:
    licenseData: "LS0tLS1CRUdJTi..."  # Base64 encoded license.dat
```

```bash
# Deploy with pre-downloaded license
LICENSE_DATA=$(base64 < license.dat)
helm install document-intelligence ./document-intelligence \
  --set documentIntelligence.azure.downloadLicense=false \
  --set documentIntelligence.license.licenseData="$LICENSE_DATA"
```

#### Method 2: Using Existing PVC

```yaml
documentIntelligence:
  azure:
    downloadLicense: false  # OFFLINE MODE
  license:
    existingClaim: "my-license-pvc"  # PVC with license.dat already present
```

```bash
# Deploy with existing PVC
helm install document-intelligence ./document-intelligence \
  --set documentIntelligence.azure.downloadLicense=false \
  --set documentIntelligence.license.existingClaim="my-license-pvc"
```

#### Method 3: Using values-mlp.yaml (Recommended for Production)

```bash
# MLP configuration is pre-configured for offline mode
helm install document-intelligence ./document-intelligence -f values-mlp.yaml
```

### Environment Variables Set

```yaml
env:
  - name: eula
    value: "accept"
  # NO billing endpoint
  # NO apikey
  # NO DownloadLicense
  - name: Mounts.License
    value: "/license"
  - name: Mounts.Output
    value: "/logs"
  - name: Logging.Console.LogLevel.Default
    value: "Information"
```

### What Happens
1. Pod starts WITHOUT Azure credentials
2. Container reads existing license from `/license` (Secret or PVC)
3. Container validates license locally
4. No connection to Azure (fully disconnected)
5. Usage logs stored locally in `/logs` PVC

## Migration Between Modes

### Online → Offline Migration

**Step 1: Download License (Online Mode)**
```bash
helm install document-intelligence ./document-intelligence \
  --set documentIntelligence.azure.billingEndpoint="https://..." \
  --set documentIntelligence.azure.apiKey="..." \
  --set documentIntelligence.azure.downloadLicense=true

# Wait for license download
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=document-intelligence
kubectl logs deployment/document-intelligence | grep -i "license"
```

**Step 2: Copy License (if needed for backup)**
```bash
POD=$(kubectl get pod -l app.kubernetes.io/name=document-intelligence -o jsonpath='{.items[0].metadata.name}')
kubectl cp $POD:/license/license.dat ./license.dat
```

**Step 3: Switch to Offline Mode**
```bash
helm upgrade document-intelligence ./document-intelligence \
  --set documentIntelligence.azure.downloadLicense=false

# Or use values-mlp.yaml
helm upgrade document-intelligence ./document-intelligence -f values-mlp.yaml
```

### Offline → Online Migration

**When License Expires:**
```bash
# Re-enable online mode to refresh license
helm upgrade document-intelligence ./document-intelligence \
  --set documentIntelligence.azure.billingEndpoint="https://..." \
  --set documentIntelligence.azure.apiKey="..." \
  --set documentIntelligence.azure.downloadLicense=true

# Wait for new license download
kubectl rollout restart deployment/document-intelligence
kubectl logs -f deployment/document-intelligence

# Switch back to offline
helm upgrade document-intelligence ./document-intelligence \
  --set documentIntelligence.azure.downloadLicense=false
```

## Verification

### Verify Online Mode is Active

```bash
# Check environment variables include Azure credentials
kubectl get pod -l app.kubernetes.io/name=document-intelligence -o yaml | grep -A 10 "env:"

# Should see: billing, apikey, DownloadLicense
```

### Verify Offline Mode is Active

```bash
# Check environment variables DO NOT include Azure credentials
kubectl get pod -l app.kubernetes.io/name=document-intelligence -o yaml | grep -A 10 "env:"

# Should NOT see: billing, apikey, DownloadLicense
```

### Check License File

```bash
# View license file location
kubectl exec -it deployment/document-intelligence -- ls -la /license/

# Verify license is valid (check expiration)
kubectl exec -it deployment/document-intelligence -- cat /license/license.dat | head -10
```

## Troubleshooting

### Online Mode Issues

**Problem**: "Unable to connect to billing endpoint"
```bash
# Check Azure credentials
kubectl get secret document-intelligence-azure -o yaml

# Verify endpoint URL
kubectl get deployment document-intelligence -o yaml | grep billing

# Test network connectivity
kubectl exec -it deployment/document-intelligence -- wget -O- https://your-resource.cognitiveservices.azure.com
```

**Problem**: "License download failed"
```bash
# Check API key is correct
# Verify commitment tier is "Disconnected Containers DC0"
# Ensure firewall allows outbound HTTPS to *.cognitiveservices.azure.com
```

### Offline Mode Issues

**Problem**: "License file not found"
```bash
# If using licenseData, check Secret exists
kubectl get secret document-intelligence-license

# If using PVC, check PVC is mounted
kubectl describe pod <pod-name> | grep -A 5 "Mounts:"

# Verify license file is present
kubectl exec -it deployment/document-intelligence -- ls -la /license/license.dat
```

**Problem**: "License expired"
```bash
# Check license expiration date
kubectl exec -it deployment/document-intelligence -- cat /license/license.dat

# Solution: Switch to online mode temporarily to refresh license
helm upgrade document-intelligence ./document-intelligence \
  --set documentIntelligence.azure.downloadLicense=true \
  --set documentIntelligence.azure.billingEndpoint="..." \
  --set documentIntelligence.azure.apiKey="..."
```

## Security Best Practices

### Online Mode Security

1. **Store API Keys in Secrets Manager**
   ```bash
   # Use external secrets operator
   kubectl create secret generic azure-credentials \
     --from-literal=apiKey="..." \
     --from-literal=billingEndpoint="..."
   ```

2. **Limit Online Mode Duration**
   - Use online mode only during license download
   - Switch to offline mode immediately after

3. **Network Policies**
   ```yaml
   # Allow egress only to Azure during online mode
   apiVersion: networking.k8s.io/v1
   kind: NetworkPolicy
   metadata:
     name: document-intelligence-online
   spec:
     podSelector:
       matchLabels:
         app: document-intelligence
     policyTypes:
     - Egress
     egress:
     - to:
       - podSelector: {}
       ports:
       - protocol: TCP
         port: 53  # DNS
     - to:
       - podSelector: {}
       ports:
       - protocol: TCP
         port: 443  # HTTPS to Azure
   ```

### Offline Mode Security

1. **Use Sealed Secrets for License**
   ```bash
   kubeseal < license-secret.yaml > sealed-license-secret.yaml
   ```

2. **Disable Network Egress**
   ```yaml
   # Block all egress in offline mode
   apiVersion: networking.k8s.io/v1
   kind: NetworkPolicy
   metadata:
     name: document-intelligence-offline
   spec:
     podSelector:
       matchLabels:
         app: document-intelligence
     policyTypes:
     - Egress
     egress: []  # No egress allowed
   ```

3. **Audit License Access**
   ```bash
   # Monitor access to license files
   kubectl get events --field-selector involvedObject.name=document-intelligence-license
   ```

## Configuration Files Overview

| File | Mode | Description |
|------|------|-------------|
| `values.yaml` | Offline (default) | Default configuration, downloadLicense=false |
| `values-mlp.yaml` | Offline | Minimal resource mode with VPA/HPA/Vector |
| `values-online.yaml` | Online | Example configuration for online mode |
| `all-in-one.yaml` | Offline | Pre-rendered manifest, no Azure credentials |
| `all-in-one-mlp.yaml` | Offline | Pre-rendered MLP manifest |

## Quick Reference

```bash
# Deploy Online Mode (initial setup)
helm install di ./document-intelligence \
  --set documentIntelligence.azure.downloadLicense=true \
  --set documentIntelligence.azure.billingEndpoint="https://..." \
  --set documentIntelligence.azure.apiKey="..."

# Deploy Offline Mode (with pre-downloaded license)
LICENSE_DATA=$(base64 < license.dat)
helm install di ./document-intelligence \
  --set documentIntelligence.license.licenseData="$LICENSE_DATA"

# Deploy Offline Mode (with MLP configuration)
helm install di ./document-intelligence -f values-mlp.yaml

# Switch Online → Offline
helm upgrade di ./document-intelligence \
  --set documentIntelligence.azure.downloadLicense=false

# Refresh Expired License
helm upgrade di ./document-intelligence \
  --set documentIntelligence.azure.downloadLicense=true \
  --set documentIntelligence.azure.billingEndpoint="https://..." \
  --set documentIntelligence.azure.apiKey="..."
```
