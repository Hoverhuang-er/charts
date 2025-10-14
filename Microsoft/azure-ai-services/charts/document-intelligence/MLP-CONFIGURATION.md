# Document Intelligence - MLP Configuration Guide

## Overview

The `values-mlp.yaml` and `all-in-one-mlp.yaml` files provide a **Minimal Resource Mode with Logging and Prometheus** (MLP) configuration for Azure AI Document Intelligence. This setup includes:

- **Minimal Resource Footprint**: Starts with 2 CPU cores and 2GB memory
- **Auto-scaling**: HPA for horizontal scaling, VPA for vertical scaling
- **Log Processing**: Vector sidecar for log analysis and forwarding
- **Metrics**: Error counting and Prometheus remote write
- **Centralized Logging**: ELK/Elasticsearch integration

## Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│  Pod: document-intelligence                                      │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌─────────────────────────┐    ┌─────────────────────────┐   │
│  │  Main Container         │    │  Vector Sidecar         │   │
│  │  document-intelligence  │    │  (Log Processor)        │   │
│  │                         │    │                         │   │
│  │  • Processes documents  │    │  • Reads /logs/*.log    │   │
│  │  • Writes to /logs      │───▶│  • Filters errors       │   │
│  │  • 2C/2Gi → 8C/24Gi    │    │  • Counts by window     │   │
│  └─────────────────────────┘    │  • Forwards to:         │   │
│                                  │    - Prometheus         │   │
│                                  │    - Elasticsearch      │   │
│                                  └─────────────────────────┘   │
│                                                                  │
│  Shared Volume: /logs (PVC)                                     │
└──────────────────────────────────────────────────────────────────┘
           │                              │
           │ HPA (CPU > 80%)              │ VPA (Memory)
           ▼                              ▼
    Scale to 10 pods              Adjust 2Gi-24Gi
```

## Components

### 1. Main Container (Document Intelligence)
- **Image**: `mcr.microsoft.com/azure-cognitive-services/form-recognizer/read-4.0`
- **Resources**: 
  - Request: 2 CPU, 2Gi memory
  - Limit: 8 CPU, 24Gi memory
- **Volumes**: 
  - `/license` (PVC, 1Gi)
  - `/logs` (PVC, 5Gi) - Shared with Vector

### 2. Vector Sidecar
- **Image**: `timberio/vector:0.34.1-alpine`
- **Purpose**: Log processing and metrics generation
- **Resources**:
  - Request: 100m CPU, 128Mi memory
  - Limit: 500m CPU, 512Mi memory
- **Functions**:
  1. Reads logs from `/logs` directory
  2. Parses and filters error messages
  3. Counts errors in time windows
  4. Sends metrics to Prometheus
  5. Forwards all logs to Elasticsearch

### 3. HPA (Horizontal Pod Autoscaler)
- **Enabled**: Yes
- **Range**: 1-10 pods
- **Trigger**: CPU usage > 80%
- **Behavior**: Scales out when CPU is high

### 4. VPA (Vertical Pod Autoscaler)
- **Enabled**: Yes
- **Mode**: Auto (updates memory automatically)
- **Range**: 2Gi - 24Gi memory
- **Control**: Memory only (CPU fixed per pod)

## Configuration

### Vector Settings

#### Error Detection
```yaml
vector:
  errorDetection:
    windowSeconds: 60  # 1-minute window
    errorPatterns:
      - "error"
      - "ERROR"
      - "exception"
      - "failed"
```

#### Prometheus Remote Write
```yaml
vector:
  prometheus:
    enabled: true
    remoteWriteUrl: "http://prometheus-server:9090/api/v1/write"
    # Optional authentication
    basicAuth:
      username: "admin"
      password: "secret"
```

#### Elasticsearch Configuration
```yaml
vector:
  elasticsearch:
    enabled: true
    endpoint: "http://elasticsearch:9200"
    index: "document-intelligence-%Y.%m.%d"
    # Optional authentication
    username: "elastic"
    password: "changeme"
```

## Deployment

### Prerequisites

1. **Install VPA** (for vertical scaling):
   ```bash
   git clone https://github.com/kubernetes/autoscaler.git
   cd autoscaler/vertical-pod-autoscaler
   ./hack/vpa-up.sh
   ```

2. **Install Metrics Server** (for HPA):
   ```bash
   kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
   ```

3. **Prometheus** (for metrics collection):
   - Ensure Prometheus is deployed in your cluster
   - Note the remote write endpoint URL

4. **Elasticsearch/ELK** (for log storage):
   - Deploy Elasticsearch cluster or use managed service
   - Note the endpoint URL and credentials

### Option 1: Deploy with Helm

```bash
# Update values-mlp.yaml with your endpoints
vi values-mlp.yaml

# Deploy with Helm
helm install document-intelligence ./document-intelligence \
  -f values-mlp.yaml \
  --set documentIntelligence.azure.billingEndpoint="https://your-resource.cognitiveservices.azure.com" \
  --set documentIntelligence.azure.apiKey="your-api-key" \
  --set vector.prometheus.remoteWriteUrl="http://prometheus-server:9090/api/v1/write" \
  --set vector.elasticsearch.endpoint="http://elasticsearch:9200"
```

### Option 2: Deploy with kubectl

```bash
# Download the pre-rendered manifest
curl -O https://raw.githubusercontent.com/Hoverhuang-er/charts/main/Microsoft/azure-ai-services/charts/document-intelligence/all-in-one-mlp.yaml

# Edit to configure endpoints
vi all-in-one-mlp.yaml

# Apply to cluster
kubectl apply -f all-in-one-mlp.yaml
```

## Metrics

### Exposed Metrics

Vector generates the following Prometheus metrics:

1. **document_intelligence_errors_total**
   - Type: Counter
   - Description: Total number of errors detected in logs
   - Labels:
     - `service`: "document-intelligence"
     - `pod`: Pod name

2. **Error Rate** (aggregated)
   - Calculated over `windowSeconds` interval
   - Useful for alerting on error spikes

### Prometheus Queries

```promql
# Current error rate (per minute)
rate(document_intelligence_errors_total[1m])

# Total errors in last hour
increase(document_intelligence_errors_total[1h])

# Errors by pod
sum by (pod) (document_intelligence_errors_total)

# Alert on high error rate (>10 errors/min)
rate(document_intelligence_errors_total[5m]) > 10
```

## Log Format in Elasticsearch

Logs are indexed in Elasticsearch with the following structure:

```json
{
  "timestamp": "2025-10-14T10:30:45.123Z",
  "service": "document-intelligence",
  "pod_name": "document-intelligence-5d8f9c7b6-abc12",
  "message": "Error processing document: timeout",
  "raw_message": "2025-10-14 10:30:45 ERROR: timeout...",
  "@timestamp": "2025-10-14T10:30:45.123Z"
}
```

### Kibana Queries

```
# All errors from document-intelligence
service:"document-intelligence" AND (error OR ERROR OR exception)

# Errors in last 15 minutes
service:"document-intelligence" AND @timestamp:[now-15m TO now] AND error

# Specific pod errors
pod_name:"document-intelligence-5d8f9c7b6-abc12" AND error
```

## Monitoring

### Check Vector Status

```bash
# View Vector sidecar logs
kubectl logs -f deployment/document-intelligence -c vector

# Check Vector is processing logs
kubectl exec -it deployment/document-intelligence -c vector -- vector top
```

### Check HPA Scaling

```bash
# View HPA status
kubectl get hpa document-intelligence -w

# Expected output:
# NAME                    REFERENCE                          TARGETS   MINPODS   MAXPODS   REPLICAS
# document-intelligence   Deployment/document-intelligence   45%/80%   1         10        1
```

### Check VPA Recommendations

```bash
# View VPA status
kubectl describe vpa document-intelligence

# Check current vs recommended resources
kubectl top pod -l app.kubernetes.io/name=document-intelligence
```

### Verify Prometheus Metrics

```bash
# Port forward to Prometheus
kubectl port-forward svc/prometheus-server 9090:9090

# Query in browser: http://localhost:9090
# Search for: document_intelligence_errors_total
```

### Verify Elasticsearch Logs

```bash
# Check logs are being indexed
curl -X GET "http://elasticsearch:9200/document-intelligence-*/_count"

# View recent logs
curl -X GET "http://elasticsearch:9200/document-intelligence-*/_search?size=10&sort=@timestamp:desc"
```

## Resource Usage Patterns

### Idle State
- **Pods**: 1
- **Per Pod**: 2 cores, ~2-3Gi memory
- **Total**: 2 cores, 3Gi (including Vector overhead)

### Normal Load
- **Pods**: 2-3
- **Per Pod**: 2 cores, ~4-6Gi memory (VPA adjusted)
- **Total**: 4-6 cores, 12-18Gi

### High Load
- **Pods**: 5-10 (HPA scaled)
- **Per Pod**: 2 cores, ~8-12Gi memory (VPA adjusted)
- **Total**: 10-20 cores, 40-120Gi

### Peak Load
- **Pods**: 10 (max)
- **Per Pod**: 2 cores, 24Gi (max limit)
- **Total**: 20 cores, 240Gi

## Cost Optimization

### Savings vs Traditional Deployment

**Traditional Fixed Allocation** (8 cores, 16Gi):
- Cost: $X/hour × 24 hours = $24X/day

**MLP Configuration** (average 3 cores, 6Gi):
- Idle: $0.375X/hour (85% savings)
- Average: $0.5X/hour (75% savings)
- Peak: $2.5X/hour (only during high load)
- **Average Daily Cost**: ~$12X/day (50% savings)

### Additional Savings from Auto-scaling
- HPA scales down to 1 pod during off-peak hours
- VPA reduces memory when not needed
- Vector uses minimal resources (0.1 CPU, 128Mi)

## Troubleshooting

### Vector Not Forwarding Metrics

**Check**: Vector configuration
```bash
kubectl get configmap document-intelligence-vector-config -o yaml
```

**Check**: Prometheus endpoint is reachable
```bash
kubectl exec -it deployment/document-intelligence -c vector -- \
  wget -O- http://prometheus-server:9090/-/healthy
```

### Logs Not Appearing in Elasticsearch

**Check**: Elasticsearch endpoint
```bash
kubectl exec -it deployment/document-intelligence -c vector -- \
  wget -O- http://elasticsearch:9200/_cluster/health
```

**Check**: Vector error logs
```bash
kubectl logs deployment/document-intelligence -c vector | grep -i error
```

### High Memory Usage Despite VPA

**Issue**: VPA takes time to react

**Solution 1**: Increase initial request
```yaml
resources:
  requests:
    memory: 4Gi
```

**Solution 2**: Adjust VPA to be more aggressive
```yaml
vpa:
  updateMode: "Auto"
  minAllowed:
    memory: "4Gi"  # Start higher
```

### Pods Restarting Frequently (VPA)

**Issue**: VPA in "Auto" mode restarts pods to update resources

**Solution**: Use "Initial" mode
```yaml
vpa:
  updateMode: "Initial"  # Only set at pod creation
```

## Advanced Configuration

### Custom Error Patterns

Add custom error patterns for your application:

```yaml
vector:
  errorDetection:
    errorPatterns:
      - "error"
      - "ERROR"
      - "FATAL"
      - "timeout"
      - "connection refused"
      - "out of memory"
      - "422"  # HTTP status codes
      - "500"
      - "503"
```

### Multiple Time Windows

To track errors at different intervals, modify Vector config:

```toml
[transforms.error_metrics_1m]
  type = "aggregate"
  interval_ms = 60000  # 1 minute

[transforms.error_metrics_5m]
  type = "aggregate"
  interval_ms = 300000  # 5 minutes
```

### Resource Tuning

Adjust based on your workload:

```yaml
# For CPU-intensive workloads
resources:
  requests:
    cpu: "4"  # Start with more CPU
    memory: 2Gi

autoscaling:
  targetCPUUtilizationPercentage: 70  # Scale earlier

# For memory-intensive workloads
resources:
  requests:
    cpu: "2"
    memory: 4Gi  # Start with more memory

vpa:
  minAllowed:
    memory: "4Gi"
  maxAllowed:
    memory: "48Gi"  # Allow more memory
```

## Security Considerations

1. **Secrets Management**: Store credentials in Kubernetes Secrets
   ```bash
   kubectl create secret generic prometheus-creds \
     --from-literal=username=admin \
     --from-literal=password=secret
   ```

2. **Network Policies**: Restrict Vector egress
   ```yaml
   apiVersion: networking.k8s.io/v1
   kind: NetworkPolicy
   metadata:
     name: vector-egress
   spec:
     podSelector:
       matchLabels:
         app: document-intelligence
     policyTypes:
     - Egress
     egress:
     - to:
       - podSelector:
           matchLabels:
             app: prometheus
       ports:
       - protocol: TCP
         port: 9090
     - to:
       - podSelector:
           matchLabels:
             app: elasticsearch
       ports:
       - protocol: TCP
         port: 9200
   ```

3. **RBAC**: Limit Vector permissions

## References

- [Vector Documentation](https://vector.dev/docs/)
- [Prometheus Remote Write](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#remote_write)
- [Elasticsearch API](https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-index_.html)
- [Kubernetes HPA](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)
- [Kubernetes VPA](https://github.com/kubernetes/autoscaler/tree/master/vertical-pod-autoscaler)
