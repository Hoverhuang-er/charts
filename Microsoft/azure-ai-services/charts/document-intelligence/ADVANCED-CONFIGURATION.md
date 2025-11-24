# Advanced Configuration Guide

This guide provides detailed information about all advanced configuration parameters for Azure AI Document Intelligence containers.

## Overview

The `documentIntelligence.advanced` section in `values.yaml` provides fine-grained control over container behavior, including storage lifecycle, task timeouts, health checks, and Azure service integrations.

## Configuration Parameters

### Storage Time to Live (TTL)

**Parameter**: `storageTimeToLiveInMinutes`

Controls how long intermediate and final processing files are retained before automatic deletion.

- **Default**: `2880` (2 days)
- **Range**: `5` to `10080` minutes (5 minutes to 7 days)
- **Use Cases**:
  - **Short TTL (5-60 minutes)**: Development/testing environments with limited storage
  - **Medium TTL (1440 minutes / 1 day)**: Production with regular cleanup
  - **Long TTL (10080 minutes / 7 days)**: Compliance requirements, audit trails

```yaml
documentIntelligence:
  advanced:
    storageTimeToLiveInMinutes: 1440  # 1 day
```

**Command Line**:
```bash
helm install document-intelligence . \
  --set documentIntelligence.advanced.storageTimeToLiveInMinutes=1440
```

---

### Task Maximum Running Time

**Parameter**: `taskMaxRunningTimeSpanInMinutes`

Maximum time a request can run before being treated as timed out.

- **Default**: `60` minutes
- **Range**: `1` minute and above
- **Use Cases**:
  - **Short timeout (30-60 minutes)**: Standard documents, quick processing
  - **Long timeout (120-180 minutes)**: Large documents, complex analysis

```yaml
documentIntelligence:
  advanced:
    taskMaxRunningTimeSpanInMinutes: 120  # 2 hours
```

**Command Line**:
```bash
helm install document-intelligence . \
  --set documentIntelligence.advanced.taskMaxRunningTimeSpanInMinutes=120
```

---

### Health Check Memory Threshold

**Parameter**: `healthCheckMemoryUpperboundInMB`

Memory limit (in MB) for health check reporting. Container reports unhealthy when memory usage exceeds this threshold.

- **Default**: Empty (uses container's recommended memory)
- **Recommended Values**:
  - Read model: `10240` MB (10 GB)
  - Layout model: `16384` MB (16 GB)
  - Custom template: `20480` MB (20 GB)

```yaml
documentIntelligence:
  advanced:
    healthCheckMemoryUpperboundInMB: 16384  # 16 GB
```

**Command Line**:
```bash
helm install document-intelligence . \
  --set documentIntelligence.advanced.healthCheckMemoryUpperboundInMB=16384
```

⚠️ **Important**: Set this value based on your resource limits to prevent OOM kills.

---

### Azure Queue Connection String

**Parameter**: `queueAzureConnectionString`

Azure Storage Queue connection string for distributed processing (custom template containers only).

- **Default**: Empty (uses in-memory queues)
- **Required For**: Custom template containers with distributed processing
- **Format**: Azure Storage connection string

```yaml
documentIntelligence:
  advanced:
    queueAzureConnectionString: "DefaultEndpointsProtocol=https;AccountName=myaccount;AccountKey=mykey;EndpointSuffix=core.windows.net"
```

**Use Cases**:
- Multi-container custom template deployments
- High-volume processing with queue-based distribution
- Decoupled processing architecture

⚠️ **Security**: Store connection strings in Kubernetes Secrets, not in values files.

---

### Azure Blob Storage Connection String

**Parameter**: `storageObjectStoreAzureBlobConnectionString`

Azure Blob Storage connection string for model and data storage (custom template containers only).

- **Default**: Empty (uses local storage)
- **Required For**: Custom template containers with Azure Blob integration
- **Format**: Azure Storage connection string

```yaml
documentIntelligence:
  advanced:
    storageObjectStoreAzureBlobConnectionString: "DefaultEndpointsProtocol=https;AccountName=myaccount;AccountKey=mykey;EndpointSuffix=core.windows.net"
```

**Use Cases**:
- Centralized model storage across multiple containers
- Persistent model storage independent of container lifecycle
- Shared storage for multi-region deployments

⚠️ **Security**: Store connection strings in Kubernetes Secrets, not in values files.

---

### HTTP Proxy Bypass URLs

**Parameter**: `httpProxyBypassUrls`

Comma-separated list of URLs that should bypass HTTP proxy.

- **Default**: Empty
- **Format**: Comma-separated domains/IPs

```yaml
documentIntelligence:
  advanced:
    httpProxyBypassUrls: "localhost,127.0.0.1,.internal.domain,*.mycompany.com"
```

**Command Line**:
```bash
helm install document-intelligence . \
  --set documentIntelligence.advanced.httpProxyBypassUrls="localhost,127.0.0.1"
```

**Use Cases**:
- Internal service communication
- Local development environments
- Private network endpoints

---

### Console Log Level

**Parameter**: `logging.consoleLogLevel`

Controls the verbosity of container console logs.

- **Default**: `Information`
- **Options**: `Trace`, `Debug`, `Information`, `Warning`, `Error`, `Critical`, `None`

```yaml
documentIntelligence:
  advanced:
    logging:
      consoleLogLevel: "Debug"
```

**Log Level Guide**:

| Level | Description | Use Case |
|-------|-------------|----------|
| `Trace` | Most verbose, all events | Deep troubleshooting |
| `Debug` | Debug messages and above | Development, debugging |
| `Information` | Informational messages and above | Production (default) |
| `Warning` | Warnings and above | Production (quiet) |
| `Error` | Errors and above | Production (minimal) |
| `Critical` | Only critical errors | Production (critical only) |
| `None` | No logging | Not recommended |

**Command Line**:
```bash
helm install document-intelligence . \
  --set documentIntelligence.advanced.logging.consoleLogLevel="Debug"
```

---

## Complete Configuration Examples

### Development Environment

Optimized for debugging and fast iteration:

```yaml
documentIntelligence:
  advanced:
    storageTimeToLiveInMinutes: 30  # Short TTL for testing
    taskMaxRunningTimeSpanInMinutes: 30  # Quick timeout
    logging:
      consoleLogLevel: "Debug"  # Verbose logging
```

### Production Environment

Optimized for stability and performance:

```yaml
documentIntelligence:
  advanced:
    storageTimeToLiveInMinutes: 2880  # 2 days (default)
    taskMaxRunningTimeSpanInMinutes: 90  # Extended timeout
    healthCheckMemoryUpperboundInMB: 20480  # 20 GB
    logging:
      consoleLogLevel: "Warning"  # Minimal logging
```

### Custom Template with Azure Integration

For custom template containers using Azure Queue and Blob Storage:

```yaml
documentIntelligence:
  modelType: customTemplate
  advanced:
    storageTimeToLiveInMinutes: 4320  # 3 days
    taskMaxRunningTimeSpanInMinutes: 120  # 2 hours
    queueAzureConnectionString: "{{ .Values.azureQueueSecret }}"
    storageObjectStoreAzureBlobConnectionString: "{{ .Values.azureBlobSecret }}"
    logging:
      consoleLogLevel: "Information"
```

### High-Volume Processing

Optimized for throughput:

```yaml
documentIntelligence:
  advanced:
    storageTimeToLiveInMinutes: 720  # 12 hours
    taskMaxRunningTimeSpanInMinutes: 180  # 3 hours
    healthCheckMemoryUpperboundInMB: 24576  # 24 GB
    logging:
      consoleLogLevel: "Error"  # Minimize logging overhead
```

---

## Using Kubernetes Secrets for Sensitive Data

For production deployments, store connection strings in Kubernetes Secrets:

### Create Secrets

```bash
# Azure Queue connection string
kubectl create secret generic document-intelligence-queue \
  --from-literal=connectionString='DefaultEndpointsProtocol=https;...'

# Azure Blob connection string
kubectl create secret generic document-intelligence-blob \
  --from-literal=connectionString='DefaultEndpointsProtocol=https;...'
```

### Reference Secrets in Deployment

Modify `templates/deployment.yaml` to use secrets:

```yaml
{{- if .Values.documentIntelligence.advanced.queueAzureConnectionString }}
- name: Queue:Azure:ConnectionString
  valueFrom:
    secretKeyRef:
      name: document-intelligence-queue
      key: connectionString
{{- end }}
```

---

## Troubleshooting

### Storage Fills Up Quickly

**Symptom**: PVC runs out of space

**Solution**: Reduce `storageTimeToLiveInMinutes` or increase PVC size

```bash
helm upgrade document-intelligence . \
  --set documentIntelligence.advanced.storageTimeToLiveInMinutes=720 \
  --set documentIntelligence.output.storageSize=20Gi
```

### Requests Timing Out

**Symptom**: Large documents fail with timeout errors

**Solution**: Increase `taskMaxRunningTimeSpanInMinutes`

```bash
helm upgrade document-intelligence . \
  --set documentIntelligence.advanced.taskMaxRunningTimeSpanInMinutes=180
```

### Container Reports Unhealthy

**Symptom**: Kubernetes marks pod as unhealthy due to memory

**Solution**: Adjust `healthCheckMemoryUpperboundInMB` or increase resource limits

```bash
helm upgrade document-intelligence . \
  --set documentIntelligence.advanced.healthCheckMemoryUpperboundInMB=20480 \
  --set resources.limits.memory=24Gi
```

### Too Much Log Output

**Symptom**: Excessive console logs impacting performance

**Solution**: Reduce log level

```bash
helm upgrade document-intelligence . \
  --set documentIntelligence.advanced.logging.consoleLogLevel="Warning"
```

---

## Reference

- [Microsoft Documentation: Install and run containers](https://learn.microsoft.com/en-us/azure/ai-services/document-intelligence/containers/install-run?view=doc-intel-4.0.0&tabs=layout)
- [Container Configuration Settings](https://learn.microsoft.com/en-us/azure/ai-services/document-intelligence/containers/configuration?view=doc-intel-4.0.0)
- [Azure Storage Connection Strings](https://learn.microsoft.com/en-us/azure/storage/common/storage-configure-connection-string)

---

## See Also

- [README.md](./README.md) - Main chart documentation
- [values-advanced-example.yaml](./values-advanced-example.yaml) - Complete configuration example
- [ONLINE-OFFLINE-MODES.md](./ONLINE-OFFLINE-MODES.md) - Online vs Offline mode guide
- [LICENSE-FILE-USAGE.md](./LICENSE-FILE-USAGE.md) - License file management
