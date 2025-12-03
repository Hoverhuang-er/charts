# Azure AI Document Intelligence Helm Chart

**Language:** [English](README.md) | [简体中文](README.zh-CN.md) | [国内访问](https://kcntz7ffdm6b.feishu.cn/wiki/U0KNwlUPyiLTCFkkP3QcFitlngg)


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
| Read | `form-recognizer/read-4.0` | 8GB | 16GB |
| Layout | `form-recognizer/layout-3.0` | 16GB | 24GB |
| Invoice | `form-recognizer/invoice-3.0` | 16GB | 24GB |
| Receipt | `form-recognizer/receipt-3.0` | 11GB | 24GB |
| Business Card | `form-recognizer/businesscard-3.0` | 16GB | 24GB |
| ID Document | `form-recognizer/idDocument-3.0` | 8GB | 24GB |
| General Document | `form-recognizer/generaldocument-3.0` | 12GB | 24GB |
| Custom Template | `form-recognizer/custom-template-3.0` | 16GB | 24GB |

## Installation

### Quick Start with all-in-one.yaml

For quick deployment without Helm, you can use the pre-rendered `all-in-one.yaml` manifest:

```bash
# Deploy directly with kubectl
kubectl apply -f https://raw.githubusercontent.com/Hoverhuang-er/charts/main/Microsoft/azure-ai-services/charts/document-intelligence/all-in-one.yaml
```

**Note:** The all-in-one.yaml uses default configurations. For production deployments or custom configurations, use Helm installation methods below.

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

### Alternative: Use Pre-downloaded License

If you already have a downloaded `license.dat` file, you can provide it directly:

```bash
# Encode the license file
LICENSE_DATA=$(base64 < license.dat)

# Deploy with the license data (no download needed)
helm install document-intelligence ./document-intelligence \
  --set documentIntelligence.license.licenseData="$LICENSE_DATA"
```

This creates a Kubernetes Secret with the license file, eliminating the need for:
- Initial license download step
- License PVC (saves storage costs)
- Azure credentials in production

See [LICENSE-FILE-USAGE.md](LICENSE-FILE-USAGE.md) for detailed instructions and additional methods.

## Configuration

### Key Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `kubernetesVersion` | Kubernetes version (1.32, 1.28, 1.26, 1.24, pre-1.24) | `1.32` |
| `image.repository` | Container image repository | `mcr.microsoft.com/azure-cognitive-services/form-recognizer/read-4.0` |
| `image.tag` | Container image tag | `latest` |
| `documentIntelligence.modelType` | Model type (read, layout, invoice, etc.) | `read` |
| `documentIntelligence.envSeparator` | Separator for mount env vars (__, _, ., -) | `__` |
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

### Advanced Configuration Parameters

| Parameter | Description | Default | Range |
|-----------|-------------|---------|-------|
| `documentIntelligence.advanced.storageTimeToLiveInMinutes` | TTL for intermediate/final files | `2880` (2 days) | 5-10080 min |
| `documentIntelligence.advanced.taskMaxRunningTimeSpanInMinutes` | Request timeout threshold | `60` | 1+ min |
| `documentIntelligence.advanced.healthCheckMemoryUpperboundInMB` | Memory health check threshold | auto | MB |
| `documentIntelligence.advanced.queueAzureConnectionString` | Azure Queue connection (custom template) | `""` | - |
| `documentIntelligence.advanced.storageObjectStoreAzureBlobConnectionString` | Azure Blob connection (custom template) | `""` | - |
| `documentIntelligence.advanced.httpProxyBypassUrls` | Proxy bypass URLs | `""` | CSV |
| `documentIntelligence.advanced.performance.oneOcrConcurrency` | OneOCR parallel operations | `""` (auto) | 4-16 |
| `documentIntelligence.advanced.performance.ocrWorkerThreadPoolSize` | OCR worker threads | `""` (auto) | 2-8 |
| `documentIntelligence.advanced.performance.queuePriorityExtraConcurrentWorkerCount` | Priority queue workers | `""` (auto) | 0-4 |
| `documentIntelligence.advanced.logging.consoleLogLevel` | Console log level | `Information` | See below |

**Log Levels**: `Trace`, `Debug`, `Information`, `Warning`, `Error`, `Critical`, `None`

**Performance Tuning**: The performance parameters (`oneOcrConcurrency`, `ocrWorkerThreadPoolSize`, `queuePriorityExtraConcurrentWorkerCount`) are disabled by default for optimal resource usage. Enable them for high-volume scenarios. See `values-advanced-example.yaml` for recommended settings.

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

### Environment Variable Separator Configuration

The chart allows you to customize the separator character used in mount-related environment variables (`Mounts__License`, `Mounts__Output`, `Mounts__Shared`). This is useful for compatibility with different Azure AI Services container versions.

**Default**: double underscore (`__`) - **Recommended for Kubernetes compatibility**
- Generates: `Mounts__License`, `Mounts__Output`, `Mounts__Shared`

**Available options**: `__` (double underscore, default), `_` (single underscore), `.` (dot), `-` (hyphen)

⚠️ **Important Notes**:
- **Colon (`:`) is NOT supported** for user-configurable separators due to Kubernetes restrictions
- Some Azure container environment variables use colons (e.g., `Task:MaxRunningTimeSpanInMinutes`) - these are hardcoded in the deployment template with proper quoting
- Dot (`.`) may cause issues in older Kubernetes versions
- Double underscore (`__`) is the safest and recommended option

#### Using Single Underscore

```bash
helm install document-intelligence ./document-intelligence \
  --set documentIntelligence.envSeparator="_"
# Generates: Mounts_License, Mounts_Output, Mounts_Shared
# Note: May cause Helm rendering issues in some versions
```

#### Using Hyphen

```bash
helm install document-intelligence ./document-intelligence \
  --set documentIntelligence.envSeparator="-"
# Generates: Mounts-License, Mounts-Output, Mounts-Shared
```

#### Using Dot

```bash
helm install document-intelligence ./document-intelligence \
  --set documentIntelligence.envSeparator="."
# Generates: Mounts.License, Mounts.Output, Mounts.Shared
```

#### In values.yaml

```yaml
documentIntelligence:
  envSeparator: "__"  # Default: double underscore (recommended)
  # Other options: "_", ".", "-"
  # Note: Colon ":" is NOT supported
```

### Using Existing PVCs

If you have existing PersistentVolumeClaims for license or logs:

```bash
helm install document-intelligence ./document-intelligence \
  --set documentIntelligence.license.existingClaim="my-license-pvc" \
  --set documentIntelligence.output.existingClaim="my-output-pvc"
```

### Advanced Configuration Examples

#### Configure Storage TTL and Task Timeout

```bash
helm install document-intelligence ./document-intelligence \
  --set documentIntelligence.advanced.storageTimeToLiveInMinutes=1440 \
  --set documentIntelligence.advanced.taskMaxRunningTimeSpanInMinutes=120 \
  --set documentIntelligence.advanced.logging.consoleLogLevel="Debug"
```

#### Configure Performance Tuning for High-Volume Scenarios

```bash
helm install document-intelligence ./document-intelligence \
  --set documentIntelligence.advanced.performance.oneOcrConcurrency=8 \
  --set documentIntelligence.advanced.performance.ocrWorkerThreadPoolSize=3 \
  --set documentIntelligence.advanced.performance.queuePriorityExtraConcurrentWorkerCount=1
```

**Note**: Performance tuning increases resource usage. Ensure sufficient CPU and memory are allocated.

#### Configure with Azure Queue and Blob Storage (Custom Template)

```bash
helm install document-intelligence ./document-intelligence \
  --set documentIntelligence.modelType=customTemplate \
  --set documentIntelligence.advanced.queueAzureConnectionString="DefaultEndpointsProtocol=https;..." \
  --set documentIntelligence.advanced.storageObjectStoreAzureBlobConnectionString="DefaultEndpointsProtocol=https;..."
```

#### Use Advanced Configuration File

See `values-advanced-example.yaml` for a complete example with all advanced parameters.

```bash
helm install document-intelligence ./document-intelligence -f values-advanced-example.yaml
```

### Custom values.yaml

Create a `my-values.yaml` file:

```yaml
image:
  repository: mcr.microsoft.com/azure-cognitive-services/form-recognizer/read-4.0
  tag: latest

documentIntelligence:
  modelType: read
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
  
  # Advanced configuration
  advanced:
    storageTimeToLiveInMinutes: 1440  # 1 day
    taskMaxRunningTimeSpanInMinutes: 90
    logging:
      consoleLogLevel: "Warning"

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

## Using all-in-one.yaml for kubectl Deployment

The `all-in-one.yaml` file is a pre-rendered Kubernetes manifest that contains all resources needed to deploy Document Intelligence. This is useful when:
- You don't have Helm installed
- You need a simple, direct deployment
- You want to inspect all resources before deployment
- You're using GitOps tools like ArgoCD or Flux

### What's Included

The all-in-one.yaml contains the following resources:
- **ServiceAccount**: For pod identity
- **PersistentVolumeClaim (license)**: 1Gi storage for license files
- **PersistentVolumeClaim (output)**: 5Gi storage for usage logs
- **Service**: ClusterIP service on port 5000
- **Deployment**: Document Intelligence container with:
  - Image: `mcr.microsoft.com/azure-cognitive-services/form-recognizer/read-4.0:latest`
  - Resources: 8 CPU cores, 16-24Gi memory
  - Health probes: liveness and readiness checks
  - Environment variables: Proper dot notation (Mounts.License, Mounts.Output, Logging.Console.LogLevel.Default)
- **Ingress**: Azure Load Balancer configuration with example hostname
- **Test Pod**: For helm test compatibility

### Deployment Steps

1. **Deploy directly from URL**:
   ```bash
   kubectl apply -f https://raw.githubusercontent.com/Hoverhuang-er/charts/main/Microsoft/azure-ai-services/charts/document-intelligence/all-in-one.yaml
   ```

2. **Verify deployment**:
   ```bash
   kubectl get all -l app.kubernetes.io/name=document-intelligence
   kubectl get pvc -l app.kubernetes.io/name=document-intelligence
   ```

3. **Check pod logs**:
   ```bash
   kubectl logs -f deployment/document-intelligence
   ```

**Optional: If you need to customize before deploying:**
```bash
# Download the manifest first
curl -O https://raw.githubusercontent.com/Hoverhuang-er/charts/main/Microsoft/azure-ai-services/charts/document-intelligence/all-in-one.yaml

# Edit as needed
vi all-in-one.yaml

# Deploy the customized version
kubectl apply -f all-in-one.yaml
```

### Important Notes

- **Default Configuration**: The all-in-one.yaml uses default values from `values.yaml`
- **License Download**: You'll need to enable license download by adding environment variables manually or use Helm for initial setup
- **Storage Classes**: Uses default storage class; modify if you need specific storage classes
- **Ingress**: Default ingress hostname is `document-intelligence.example.com` - update this for your domain
- **No Azure Credentials**: The default manifest doesn't include Azure billing endpoint and API key for security reasons

### Customizing all-in-one.yaml

To add Azure credentials for license download, edit the Deployment section:

```yaml
env:
  - name: eula
    value: "accept"
  - name: billing
    value: "https://your-resource.cognitiveservices.azure.com"
  - name: apikey
    value: "your-api-key"
  - name: DownloadLicense
    value: "True"
  - name: Mounts.License
    value: "/license"
  # ... rest of the env vars
```

### Regenerating all-in-one.yaml

If you need to regenerate the manifest with custom values:

```bash
# Clone the repository
git clone https://github.com/Hoverhuang-er/charts.git
cd charts/Microsoft/azure-ai-services/charts/document-intelligence

# Render with custom values
helm template document-intelligence . \
  --set image.repository="mcr.microsoft.com/azure-cognitive-services/form-recognizer/invoice-3.0" \
  --set documentIntelligence.license.storageSize="2Gi" \
  > my-custom-all-in-one.yaml

# Deploy
kubectl apply -f my-custom-all-in-one.yaml
```

### Uninstalling

To remove all resources:

```bash
kubectl delete -f all-in-one.yaml
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
