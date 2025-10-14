# Minimal Resource Mode with HPA and VPA

This configuration file (`values-mlp.yaml`) is optimized for minimal resource usage with automatic scaling capabilities.

## Overview

- **Initial Resources**: 2 CPU cores, 2GB memory (minimal footprint)
- **Maximum Resources**: 8 CPU cores, 24GB memory (upper limits)
- **Vertical Scaling**: VPA handles memory scaling automatically
- **Horizontal Scaling**: HPA handles pod replication based on CPU usage

## Architecture

### Vertical Pod Autoscaler (VPA)
- **Purpose**: Automatically adjusts memory requests based on actual usage
- **Mode**: Auto (updates pods automatically)
- **Range**: 2Gi - 24Gi memory
- **Controlled Resource**: Memory only (CPU remains fixed per pod)

### Horizontal Pod Autoscaler (HPA)
- **Purpose**: Scales the number of pods based on CPU utilization
- **Trigger**: When CPU usage exceeds 80%
- **Range**: 1-10 replicas
- **Result**: More compute capacity through additional pods

## Resource Strategy

```
┌─────────────────────────────────────────────────────┐
│  Single Pod Resource Allocation                     │
├─────────────────────────────────────────────────────┤
│  CPU Request:    2 cores  (fixed)                   │
│  CPU Limit:      8 cores  (max per pod)             │
│  Memory Request: 2Gi      (VPA adjusts 2-24Gi)      │
│  Memory Limit:   24Gi     (max per pod)             │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│  Scaling Behavior                                   │
├─────────────────────────────────────────────────────┤
│  Memory needs increase → VPA increases memory       │
│  CPU usage > 80%       → HPA adds more pods         │
│  Total capacity        → Up to 10 pods × 8 cores    │
│                          = 80 cores, 240Gi memory   │
└─────────────────────────────────────────────────────┘
```

## Prerequisites

### 1. Install VPA in your cluster

```bash
# Clone the Kubernetes autoscaler repository
git clone https://github.com/kubernetes/autoscaler.git
cd autoscaler/vertical-pod-autoscaler

# Install VPA
./hack/vpa-up.sh

# Verify installation
kubectl get pods -n kube-system | grep vpa
```

Expected output:
```
vpa-admission-controller-xxxxx   1/1     Running
vpa-recommender-xxxxx            1/1     Running
vpa-updater-xxxxx                1/1     Running
```

### 2. Ensure Metrics Server is installed

HPA requires metrics-server for CPU/Memory metrics:

```bash
# Check if metrics-server is installed
kubectl get deployment metrics-server -n kube-system

# If not installed, install it
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

## Installation

Deploy with the minimal resource configuration:

```bash
helm install document-intelligence ./document-intelligence \
  -f values-mlp.yaml \
  --set documentIntelligence.azure.billingEndpoint="https://your-resource.cognitiveservices.azure.com" \
  --set documentIntelligence.azure.apiKey="your-api-key" \
  --set documentIntelligence.azure.downloadLicense=true
```

## Monitoring

### Check HPA Status

```bash
# View HPA metrics
kubectl get hpa document-intelligence

# Watch HPA in real-time
kubectl get hpa document-intelligence -w

# Detailed HPA information
kubectl describe hpa document-intelligence
```

Example output:
```
NAME                    REFERENCE                          TARGETS   MINPODS   MAXPODS   REPLICAS
document-intelligence   Deployment/document-intelligence   45%/80%   1         10        1
```

### Check VPA Status

```bash
# View VPA configuration
kubectl get vpa document-intelligence

# View VPA recommendations
kubectl describe vpa document-intelligence

# Check current resource usage
kubectl top pod -l app.kubernetes.io/name=document-intelligence
```

Example VPA recommendations:
```
  Recommendation:
    Container Recommendations:
      Container Name:  document-intelligence
      Lower Bound:
        Cpu:     2
        Memory:  2Gi
      Target:
        Cpu:     2
        Memory:  4Gi
      Upper Bound:
        Cpu:     8
        Memory:  24Gi
```

## Scaling Behavior Examples

### Scenario 1: Memory-Intensive Workload

```
Time 0:  Pod starts with 2Gi memory
Time 5m: VPA detects memory pressure, recommends 4Gi
Time 6m: VPA updates pod with 4Gi memory request
Time 10m: Usage increases, VPA recommends 8Gi
Time 11m: VPA updates pod with 8Gi memory request
```

### Scenario 2: CPU-Intensive Workload

```
Time 0:  1 pod running (2 cores, 2Gi)
Time 5m: CPU usage hits 85% (above 80% threshold)
Time 6m: HPA scales to 2 pods
Time 10m: CPU still high, HPA scales to 3 pods
Time 15m: Load decreases, CPU usage drops to 50%
Time 20m: HPA scales back to 2 pods
Time 25m: CPU normalizes, HPA scales back to 1 pod
```

### Scenario 3: Combined Load

```
Time 0:  1 pod (2 cores, 2Gi)
Time 5m: Memory increases → VPA: 2Gi → 6Gi
Time 10m: CPU high → HPA: 1 → 2 pods (each with 6Gi from VPA)
Time 15m: Both pods under load → VPA increases both to 12Gi
Time 20m: CPU spikes → HPA: 2 → 4 pods (each with 12Gi)
Result:  4 pods × 12Gi = 48Gi total memory capacity
```

## Configuration Options

### Disable VPA (Keep HPA Only)

```yaml
vpa:
  enabled: false

autoscaling:
  enabled: true
```

### Disable HPA (Keep VPA Only)

```yaml
vpa:
  enabled: true

autoscaling:
  enabled: false
```

### Adjust VPA Update Mode

```yaml
vpa:
  enabled: true
  # "Auto" - Updates pods automatically (may cause restarts)
  # "Initial" - Only sets resources at pod creation
  # "Off" - Only provides recommendations, no updates
  updateMode: "Initial"
```

### Adjust HPA Thresholds

```yaml
autoscaling:
  enabled: true
  minReplicas: 2        # Start with 2 pods minimum
  maxReplicas: 20       # Allow up to 20 pods
  targetCPUUtilizationPercentage: 70  # Scale at 70% instead of 80%
```

### Change Resource Boundaries

```yaml
resources:
  requests:
    cpu: "1"      # Start even smaller
    memory: 1Gi
  limits:
    cpu: "16"     # Allow more CPU per pod
    memory: 48Gi  # Allow more memory per pod

vpa:
  minAllowed:
    cpu: "1"
    memory: "1Gi"
  maxAllowed:
    cpu: "16"
    memory: "48Gi"
```

## Cost Optimization

This configuration optimizes costs by:

1. **Starting Small**: 2 cores, 2Gi per pod (minimal cloud costs)
2. **Growing on Demand**: VPA adds memory only when needed
3. **Horizontal Elasticity**: HPA adds pods only during high load
4. **Automatic Scale Down**: Both HPA and VPA scale down during low usage

### Cost Comparison

**Traditional Fixed Allocation** (8 cores, 16Gi):
- Always running: 8 cores × $X/hour + 16Gi × $Y/hour
- Cost: 24/7 regardless of usage

**Minimal Resource Mode** (this configuration):
- Idle: 2 cores × $X/hour + 2Gi × $Y/hour (75% savings)
- Peak: Scales up to meet demand
- Average: Typically 3-5 cores, 6-10Gi (40-60% savings)

## Troubleshooting

### Pods Keep Restarting (VPA Issue)

VPA in "Auto" mode may restart pods to apply new resource requests.

**Solution**: Use "Initial" mode for production:
```yaml
vpa:
  updateMode: "Initial"
```

### HPA Not Scaling

**Check**: Metrics server is running
```bash
kubectl get apiservice v1beta1.metrics.k8s.io -o yaml
```

**Check**: Pod has resource requests defined
```bash
kubectl get pod -l app.kubernetes.io/name=document-intelligence -o yaml | grep -A 5 resources
```

### VPA Not Updating Memory

**Check**: VPA is installed and running
```bash
kubectl get pods -n kube-system | grep vpa
```

**Check**: VPA recommendations
```bash
kubectl describe vpa document-intelligence
```

### Memory OOMKilled Despite VPA

VPA takes time to adjust. If immediate crashes occur:

**Temporary Fix**: Increase initial request
```yaml
resources:
  requests:
    memory: 4Gi  # Start higher
```

## Best Practices

1. **Monitor First**: Run with VPA in "Off" mode for 1-2 weeks to collect recommendations
2. **Gradual Rollout**: Start with "Initial" mode, then move to "Auto" after validation
3. **Set Realistic Limits**: Based on actual workload, not theoretical maximum
4. **Test Scaling**: Simulate load to verify HPA behavior
5. **Alert on Limits**: Set up monitoring alerts when pods reach 80% of limits

## Additional Resources

- [Kubernetes HPA Documentation](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)
- [VPA GitHub Repository](https://github.com/kubernetes/autoscaler/tree/master/vertical-pod-autoscaler)
- [Azure AKS Autoscaling](https://learn.microsoft.com/en-us/azure/aks/concepts-scale)
