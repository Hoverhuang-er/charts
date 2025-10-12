# Quick Start Guide - Azure AI Document Intelligence

**Language:** [English](QUICKSTART.md) | [简体中文](QUICKSTART.zh-CN.md)

## 🚀 Quick Installation

### Step 1: Download License (First Time Only)
```bash
helm install document-intelligence ./document-intelligence \
  --set documentIntelligence.azure.billingEndpoint="https://YOUR-RESOURCE.cognitiveservices.azure.com" \
  --set documentIntelligence.azure.apiKey="YOUR-API-KEY" \
  --set documentIntelligence.azure.downloadLicense=true
```

Wait for license download (check logs):
```bash
kubectl logs -f deployment/document-intelligence
```

### Step 2: Switch to Offline Mode
```bash
helm upgrade document-intelligence ./document-intelligence \
  --set documentIntelligence.azure.downloadLicense=false
```

### Step 3: Access the API
```bash
kubectl port-forward svc/document-intelligence 5000:5000
```

Test:
```bash
curl http://localhost:5000/status
```

## 📋 Common Commands

### Check Deployment Status
```bash
kubectl get pods -l app.kubernetes.io/name=document-intelligence
kubectl describe deployment document-intelligence
```

### View Logs
```bash
kubectl logs deployment/document-intelligence
```

### Access Usage Records
```bash
# All records
curl http://localhost:5000/records/usage-logs/

# Specific month (e.g., December 2025)
curl http://localhost:5000/records/usage-logs/12/2025
```

### Check PVCs
```bash
kubectl get pvc
kubectl describe pvc document-intelligence-license
kubectl describe pvc document-intelligence-output
```

## 🔧 Configuration Examples

### Deploy Invoice Model
```bash
helm install invoice ./document-intelligence \
  --set image.repository="mcr.microsoft.com/azure-cognitive-services/form-recognizer/invoice-3.0" \
  --set documentIntelligence.modelType=invoice
```

### Configure Ingress Controller

#### Azure Load Balancer (Default)
```bash
helm install document-intelligence ./document-intelligence \
  --set ingress.controllerType=azure-loadbalancer
```

#### Application Gateway
```bash
helm install document-intelligence ./document-intelligence \
  --set ingress.controllerType=application-gateway
```

#### NGINX Ingress
```bash
helm install document-intelligence ./document-intelligence \
  --set ingress.controllerType=nginx
```

### Set Kubernetes Version
```bash
# For Kubernetes 1.24
helm install document-intelligence ./document-intelligence \
  --set kubernetesVersion="1.24"

# For pre-1.24 (disables securityContext)
helm install document-intelligence ./document-intelligence \
  --set kubernetesVersion="pre-1.24"
```

### Use LoadBalancer Service
```bash
helm upgrade document-intelligence ./document-intelligence \
  --set service.type=LoadBalancer
```

### Increase Resources
```bash
helm upgrade document-intelligence ./document-intelligence \
  --set resources.requests.memory=20Gi \
  --set resources.limits.memory=32Gi
```

## 🐛 Troubleshooting

### Pod Won't Start
```bash
# Check events
kubectl describe pod <pod-name>

# Check resource availability
kubectl top nodes

# Verify PVCs are bound
kubectl get pvc
```

### License Missing
```bash
# Re-download license
helm upgrade document-intelligence ./document-intelligence \
  --set documentIntelligence.azure.downloadLicense=true \
  --set documentIntelligence.azure.billingEndpoint="..." \
  --set documentIntelligence.azure.apiKey="..."
```

### Check License File
```bash
kubectl exec deployment/document-intelligence -- ls -la /license
```

## 📊 Supported Models

| Model | Repository Path |
|-------|----------------|
| Layout | `form-recognizer/layout-3.0` |
| Invoice | `form-recognizer/invoice-3.0` |
| Receipt | `form-recognizer/receipt-3.0` |
| Business Card | `form-recognizer/businesscard-3.0` |
| ID Document | `form-recognizer/idDocument-3.0` |
| General Document | `form-recognizer/generaldocument-3.0` |
| Custom Template | `form-recognizer/custom-template-3.0` |

All repositories are prefixed with: `mcr.microsoft.com/azure-cognitive-services/`

## 🔐 Security Best Practices

1. **Never commit API keys**: Use `--set` flags or external secret managers
2. **Use Sealed Secrets** or **External Secrets Operator** for production
3. **Restrict PVC access** with RBAC policies
4. **Enable network policies** to limit API access
5. **Regularly rotate** API keys

## 📖 More Information

- Full documentation: `README.md`
- Implementation details: `IMPLEMENTATION.md`
- Example configurations: `examples.yaml`
- Microsoft docs: https://learn.microsoft.com/azure/ai-services/document-intelligence/containers/disconnected
