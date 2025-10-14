# Using Pre-downloaded License File

If you have already downloaded the license.dat file from Azure, you can provide it directly to the Helm chart instead of downloading it again.

## Option 1: Using licenseData in values.yaml

### Step 1: Encode your license file

```bash
# Convert license.dat to base64
base64 -i license.dat -o license.dat.b64

# Or get the base64 string directly
base64 < license.dat
```

### Step 2: Create custom values file

Create `my-values.yaml`:

```yaml
documentIntelligence:
  modelType: read
  
  # Disable license download since we already have it
  azure:
    downloadLicense: false
  
  license:
    # Provide the base64-encoded license content
    # This will create a Secret with license.dat
    licenseData: |
      LS0tLS1CRUdJTiBMSUNFTlNFLS0tLS0KVGhpcyBpcyBhbiBleGFtcGxlIGxpY2Vuc2UgZmlsZQpS
      RUFMIExJQ0VOU0UgREFUQSBHT0VTIEhFUkUKLS0tLS1FTkQgTElDRU5TRS0tLS0tCg==
```

### Step 3: Deploy with Helm

```bash
helm install document-intelligence ./document-intelligence -f my-values.yaml
```

## Option 2: Using kubectl to create Secret first

### Step 1: Create the Secret manually

```bash
kubectl create secret generic document-intelligence-license \
  --from-file=license.dat=./license.dat
```

### Step 2: Deploy with Helm (no licenseData needed)

The chart will automatically use the license from the Secret instead of PVC.

```bash
helm install document-intelligence ./document-intelligence \
  --set documentIntelligence.azure.downloadLicense=false
```

## Option 3: Using --set-file with Helm

```bash
# Encode license file
LICENSE_DATA=$(base64 < license.dat)

# Install with inline license data
helm install document-intelligence ./document-intelligence \
  --set documentIntelligence.azure.downloadLicense=false \
  --set documentIntelligence.license.licenseData="$LICENSE_DATA"
```

## Option 4: Using Sealed Secrets (Recommended for Production)

For better security, use Sealed Secrets:

### Step 1: Install Sealed Secrets Controller

```bash
kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.24.0/controller.yaml
```

### Step 2: Create a regular Secret file

Create `license-secret.yaml`:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: document-intelligence-license
  namespace: default
type: Opaque
data:
  license.dat: <base64-encoded-content>
```

### Step 3: Seal the Secret

```bash
kubeseal < license-secret.yaml > sealed-license-secret.yaml

# Apply the sealed secret
kubectl apply -f sealed-license-secret.yaml
```

### Step 4: Deploy Helm chart

```bash
helm install document-intelligence ./document-intelligence \
  --set documentIntelligence.azure.downloadLicense=false
```

## How It Works

When `licenseData` is provided:

1. **Secret Creation**: A Secret named `{release-name}-license` is created with `license.dat`
2. **Volume Mount**: The Deployment mounts the Secret as a volume at `/license`
3. **No PVC**: License PVC is NOT created (saves storage costs)
4. **Read-Only**: License is mounted read-only from Secret

When `licenseData` is NOT provided:

1. **PVC Creation**: A PersistentVolumeClaim is created for `/license`
2. **License Download**: If `downloadLicense: true`, container downloads license to PVC
3. **Persistent**: License persists across pod restarts

## Advantages of Using licenseData

✅ **No Download Step**: Skip the initial license download phase  
✅ **Faster Deployment**: Pod starts immediately with license  
✅ **No PVC Cost**: Saves 1Gi of persistent storage  
✅ **Immutable**: License in Secret cannot be accidentally modified  
✅ **GitOps Friendly**: Can commit sealed secret to Git  

## Limitations

⚠️ **License Size**: Secrets have a 1MB size limit (license.dat is typically <100KB)  
⚠️ **Updates**: To update license, must redeploy or update Secret manually  
⚠️ **Backup**: Ensure you backup the original license.dat file  

## Verifying the License

After deployment, verify the license is mounted correctly:

```bash
# Check if Secret exists
kubectl get secret document-intelligence-license

# View Secret data (base64 encoded)
kubectl get secret document-intelligence-license -o jsonpath='{.data.license\.dat}' | base64 -d

# Check pod has license mounted
kubectl exec -it deployment/document-intelligence -- ls -la /license/

# Verify license content
kubectl exec -it deployment/document-intelligence -- cat /license/license.dat
```

Expected output:
```
total 8
drwxrwxrwt 3 root root  100 Oct 14 10:30 .
drwxr-xr-x 1 root root 4096 Oct 14 10:29 ..
drwxr-xr-x 2 root root   60 Oct 14 10:30 ..2025_10_14_10_30_45.123456789
lrwxrwxrwx 1 root root   32 Oct 14 10:30 ..data -> ..2025_10_14_10_30_45.123456789
lrwxrwxrwx 1 root root   18 Oct 14 10:30 license.dat -> ..data/license.dat
```

## Example: Complete Deployment with Pre-downloaded License

```bash
#!/bin/bash

# 1. Encode your license file
LICENSE_DATA=$(base64 < /path/to/license.dat)

# 2. Create values file
cat > license-values.yaml <<EOF
documentIntelligence:
  modelType: read
  
  azure:
    downloadLicense: false  # We have the license already
  
  license:
    licenseData: "$LICENSE_DATA"

resources:
  requests:
    cpu: "2"
    memory: 2Gi
  limits:
    cpu: "8"
    memory: 24Gi
EOF

# 3. Deploy
helm install document-intelligence ./document-intelligence -f license-values.yaml

# 4. Wait for pod to be ready
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=document-intelligence --timeout=300s

# 5. Test the service
kubectl port-forward svc/document-intelligence 5000:5000 &
curl http://localhost:5000/status

# 6. Clean up
# kubectl delete secret document-intelligence-license  # Removes the license Secret
# helm uninstall document-intelligence
```

## Switching Between Methods

### From PVC to Secret (licenseData)

If you previously used PVC and want to switch to Secret:

```bash
# 1. Copy license from PVC
kubectl cp document-intelligence-xxxxx:/license/license.dat ./license.dat

# 2. Upgrade with licenseData
LICENSE_DATA=$(base64 < license.dat)
helm upgrade document-intelligence ./document-intelligence \
  --set documentIntelligence.license.licenseData="$LICENSE_DATA"

# 3. Optionally delete old PVC
kubectl delete pvc document-intelligence-license
```

### From Secret to PVC

If you want to switch from Secret back to PVC:

```bash
# 1. Upgrade without licenseData
helm upgrade document-intelligence ./document-intelligence \
  --set documentIntelligence.license.licenseData=""

# 2. PVC will be created automatically
# 3. Enable license download to populate PVC
helm upgrade document-intelligence ./document-intelligence \
  --set documentIntelligence.azure.downloadLicense=true \
  --set documentIntelligence.azure.billingEndpoint="https://..." \
  --set documentIntelligence.azure.apiKey="..."
```

## Security Best Practices

1. **Never Commit Plain License**: Don't commit `license.dat` or base64 to Git
2. **Use Sealed Secrets**: For GitOps workflows, always use SealedSecrets
3. **Rotate Regularly**: Update license before expiration
4. **Limit Access**: Use RBAC to restrict Secret access
5. **Enable Encryption**: Ensure etcd encryption is enabled for Secrets

```bash
# Check if Secret encryption is enabled
kubectl get secret document-intelligence-license -o yaml | grep -i encrypted
```

## Troubleshooting

### License Not Found

**Symptom**: Pod logs show "License file not found"

**Solution**: Verify Secret exists and is mounted
```bash
kubectl get secret document-intelligence-license
kubectl describe pod document-intelligence-xxxxx
```

### Invalid License Format

**Symptom**: Container fails with "Invalid license"

**Solution**: Verify base64 encoding is correct
```bash
# Decode and check
kubectl get secret document-intelligence-license \
  -o jsonpath='{.data.license\.dat}' | base64 -d | head -5
```

### License Expired

**Symptom**: Container logs show "License expired"

**Solution**: Update the Secret with new license
```bash
# Get new license.dat from Azure
# Then update Secret
kubectl delete secret document-intelligence-license
kubectl create secret generic document-intelligence-license \
  --from-file=license.dat=./new-license.dat

# Restart pods
kubectl rollout restart deployment/document-intelligence
```

## References

- [Kubernetes Secrets](https://kubernetes.io/docs/concepts/configuration/secret/)
- [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets)
- [Azure AI Document Intelligence Licensing](https://learn.microsoft.com/en-us/azure/ai-services/document-intelligence/containers/disconnected)
