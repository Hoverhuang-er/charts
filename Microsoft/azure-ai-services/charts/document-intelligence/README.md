# Azure AI Document Intelligence Helm Chart

**Language:** [English](README.md) | [简体中文](README.zh-CN.md)

This Helm chart deploys Azure AI Document Intelligence containers in disconnected (offline) environments on Kubernetes.

## Overview

Azure AI Document Intelligence containers allow you to run Document Intelligence APIs locally with the benefits of containerization. Disconnected containers are designed for scenarios where no connectivity with Azure cloud is needed after initial setup.

## Prerequisites

- Kubernetes 1.23+
- Helm 3.8.0+
- Azure AI Document Intelligence resource with disconnected containers commitment tier
- Sufficient cluster resources (minimum 8 cores, 16GB memory per pod)
- Persistent storage provisioner (for license and logs)

## Supported Models

This chart supports the following Document Intelligence models:

| Model | Image Repository | Minimum Memory | Recommended Memory |
|-------|-----------------|----------------|-------------------|
| Layout | `form-recognizer/layout-3.0` | 16GB | 24GB |
| Invoice | `form-recognizer/invoice-3.0` | 16GB | 24GB |
| Receipt | `form-recognizer/receipt-3.0` | 11GB | 24GB |
| Business Card | `form-recognizer/businesscard-3.0` | 16GB | 24GB |
| ID Document | `form-recognizer/idDocument-3.0` | 8GB | 24GB |
| General Document | `form-recognizer/generaldocument-3.0` | 12GB | 24GB |
| Custom Template | `form-recognizer/custom-template-3.0` | 16GB | 24GB |

## Installation

### Step 1: Request Access

Before using disconnected containers:
1. Submit a [request form](https://aka.ms/csdisconnectedcontainers) for access
2. Purchase a commitment plan in Azure Portal
3. Create an Azure AI Document Intelligence resource with "Commitment tier disconnected containers DC0" pricing tier

### Step 2: Initial Setup (License Download)

First, deploy the chart with license download enabled to obtain the license file:

```bash
helm install document-intelligence ./document-intelligence \
  --set documentIntelligence.azure.billingEndpoint="https://your-resource.cognitiveservices.azure.com" \
  --set documentIntelligence.azure.apiKey="your-api-key" \
  --set documentIntelligence.azure.downloadLicense=true
```

Wait for the pod to complete license download (check logs):

```bash
kubectl logs -f deployment/document-intelligence
```

### Step 3: Switch to Disconnected Mode

After license is downloaded, upgrade to disconnected mode:

```bash
helm upgrade document-intelligence ./document-intelligence \
  --set documentIntelligence.azure.downloadLicense=false
```

## Configuration

### Key Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `kubernetesVersion` | Kubernetes version (1.32, 1.28, 1.26, 1.24, pre-1.24) | `1.32` |
| `image.repository` | Container image repository | `mcr.microsoft.com/azure-cognitive-services/form-recognizer/layout-3.0` |
| `image.tag` | Container image tag | `latest` |
| `documentIntelligence.modelType` | Model type (layout, invoice, etc.) | `layout` |
| `documentIntelligence.azure.billingEndpoint` | Azure billing endpoint (for license download) | `""` |
| `documentIntelligence.azure.apiKey` | Azure API key (for license download) | `""` |
| `documentIntelligence.azure.downloadLicense` | Enable license download mode | `false` |
| `documentIntelligence.license.mountPath` | License storage path | `/license` |
| `documentIntelligence.license.storageSize` | License PVC size | `1Gi` |
| `documentIntelligence.output.mountPath` | Usage logs storage path | `/logs` |
| `documentIntelligence.output.storageSize` | Output PVC size | `5Gi` |
| `ingress.enabled` | Enable ingress | `true` |
| `ingress.controllerType` | Ingress controller (azure-loadbalancer, application-gateway, nginx) | `azure-loadbalancer` |
| `resources.requests.memory` | Memory request | `16Gi` |
| `resources.requests.cpu` | CPU request | `8` |
| `resources.limits.memory` | Memory limit | `24Gi` |
| `resources.limits.cpu` | CPU limit | `8` |
| `service.type` | Kubernetes service type | `ClusterIP` |
| `service.port` | Service port | `5000` |

### Example: Deploy Invoice Model

```bash
helm install invoice-analyzer ./document-intelligence \
  --set image.repository="mcr.microsoft.com/azure-cognitive-services/form-recognizer/invoice-3.0" \
  --set documentIntelligence.modelType=invoice \
  --set documentIntelligence.azure.billingEndpoint="https://your-resource.cognitiveservices.azure.com" \
  --set documentIntelligence.azure.apiKey="your-api-key" \
  --set documentIntelligence.azure.downloadLicense=true
```

### Kubernetes Version Compatibility

This chart supports multiple Kubernetes versions. Set the `kubernetesVersion` parameter:

```bash
# For Kubernetes 1.32 (default)
helm install document-intelligence ./document-intelligence

# For Kubernetes 1.24
helm install document-intelligence ./document-intelligence \
  --set kubernetesVersion="1.24"

# For Kubernetes versions before 1.24 (disables securityContext)
helm install document-intelligence ./document-intelligence \
  --set kubernetesVersion="pre-1.24"
```

**Note:** Kubernetes versions before 1.24 will have `securityContext` disabled for compatibility.

### Ingress Configuration

The chart creates an Ingress resource by default. Choose your ingress controller:

#### Azure Load Balancer (Default)

```bash
helm install document-intelligence ./document-intelligence \
  --set ingress.controllerType="azure-loadbalancer" \
  --set ingress.hosts[0].host="document-intelligence.example.com"
```

#### Azure Application Gateway Ingress Controller (AGIC)

```bash
helm install document-intelligence ./document-intelligence \
  --set ingress.controllerType="application-gateway" \
  --set ingress.hosts[0].host="document-intelligence.example.com"
```

#### NGINX Ingress Controller

```bash
helm install document-intelligence ./document-intelligence \
  --set ingress.controllerType="nginx" \
  --set ingress.hosts[0].host="document-intelligence.example.com"
```

#### Disable Ingress

```bash
helm install document-intelligence ./document-intelligence \
  --set ingress.enabled=false
```

### Using Existing PVCs

If you have existing PersistentVolumeClaims for license or logs:

```bash
helm install document-intelligence ./document-intelligence \
  --set documentIntelligence.license.existingClaim="my-license-pvc" \
  --set documentIntelligence.output.existingClaim="my-output-pvc"
```

### Custom values.yaml

Create a `my-values.yaml` file:

```yaml
image:
  repository: mcr.microsoft.com/azure-cognitive-services/form-recognizer/layout-3.0
  tag: latest

documentIntelligence:
  modelType: layout
  azure:
    billingEndpoint: "https://your-resource.cognitiveservices.azure.com"
    apiKey: "your-api-key"
    downloadLicense: false
  license:
    storageSize: 2Gi
    storageClassName: "fast-ssd"
  output:
    storageSize: 10Gi
    storageClassName: "fast-ssd"

resources:
  requests:
    cpu: "8"
    memory: 20Gi
  limits:
    cpu: "8"
    memory: 24Gi

service:
  type: LoadBalancer
```

Install with custom values:

```bash
helm install document-intelligence ./document-intelligence -f my-values.yaml
```

## Usage

### Access the API

After deployment, access the Document Intelligence API:

```bash
# Port forward to local machine
kubectl port-forward svc/document-intelligence 5000:5000

# Test the endpoint
curl http://localhost:5000/status
```

### Analyze Documents

Use the Document Intelligence API to analyze documents:

```bash
curl -X POST "http://localhost:5000/formrecognizer/v3.0/layout/analyze" \
  -H "Content-Type: application/json" \
  -d @document.json
```

### Monitor Usage

View usage logs:

```bash
# Get all usage records
curl http://localhost:5000/records/usage-logs/

# Get records for specific month (e.g., January 2025)
curl http://localhost:5000/records/usage-logs/01/2025
```

### Access Usage Logs PVC

To inspect usage logs directly:

```bash
kubectl exec -it deployment/document-intelligence -- ls /logs
```

## Multi-Container Setup

For custom models that require multiple containers (e.g., custom-template + layout):

```yaml
documentIntelligence:
  shared:
    enabled: true
    storageSize: 20Gi
```

## Troubleshooting

### Container fails to start

1. Check logs:
   ```bash
   kubectl logs deployment/document-intelligence
   ```

2. Verify resources are sufficient:
   ```bash
   kubectl describe pod <pod-name>
   ```

3. Ensure license file exists in PVC

### License file missing

If running in disconnected mode without license:
1. Switch back to download mode
2. Set `documentIntelligence.azure.downloadLicense=true`
3. Provide valid billing endpoint and API key
4. Wait for download to complete
5. Switch back to disconnected mode

### Usage logs not appearing

Check output PVC is properly mounted:
```bash
kubectl describe pvc document-intelligence-output
```

### Performance issues

Increase resources allocation:
```yaml
resources:
  requests:
    memory: 24Gi
    cpu: "10"
  limits:
    memory: 32Gi
    cpu: "12"
```

## License Expiration

License files have an expiration date. When expired:
1. Re-enable download mode
2. Download a new license file
3. Return to disconnected mode

## Security Considerations

- Store Azure API key securely (use sealed secrets or external secret stores)
- Limit network access to the service
- Use RBAC to restrict access to PVCs containing license files
- Regularly rotate API keys

## References

- [Official Documentation](https://learn.microsoft.com/en-us/azure/ai-services/document-intelligence/containers/disconnected)
- [Container Images](https://mcr.microsoft.com/catalog?search=form-recognizer)
- [API Reference](https://learn.microsoft.com/en-us/azure/ai-services/document-intelligence/overview)
- [Disconnected Containers FAQ](https://learn.microsoft.com/en-us/azure/ai-services/containers/disconnected-container-faq)

## Support

For issues related to:
- Helm chart: Open an issue in this repository
- Azure AI Services: Contact Azure Support
- Container images: Check Microsoft Container Registry status
