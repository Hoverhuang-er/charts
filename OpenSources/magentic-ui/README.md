# Magentic-UI Helm Chart

[Magentic-UI](https://github.com/microsoft/magentic-ui) is a research prototype of a human-centered multi-agent system that can browse and perform actions on the web, generate and execute code, and generate and analyze files.

## 🌟 Features

- **Co-Planning**: Collaborate with AI to create and approve step-by-step plans
- **Co-Tasking**: Interrupt and guide task execution through chat or browser
- **Action Guards**: Sensitive actions require explicit user approval
- **Plan Learning**: Learn from previous runs and save plans for future automation
- **Parallel Tasks**: Run multiple tasks simultaneously with status indicators

## ⚠️ Important Notes

### Docker-in-Docker Requirement

Magentic-UI requires **Docker-in-Docker (DinD)** to run browser automation and code execution containers. This has special requirements in Kubernetes:

1. **Privileged Mode**: Pods must run with `privileged: true`
2. **Security Implications**: Only deploy in trusted environments
3. **Resource Requirements**: Requires significant CPU and memory resources

### Production Considerations

- **Not Production-Ready**: This is a research prototype
- **Security**: Privileged containers pose security risks
- **Scaling**: Limited horizontal scaling due to Docker-in-Docker architecture
- **Alternatives**: Consider running magentic-ui outside Kubernetes for production use

## 📋 Prerequisites

- Kubernetes 1.23+
- Helm 3.8.0+
- OpenAI API Key (or compatible API endpoint)
- Cluster with support for:
  - Privileged containers
  - Persistent volumes (if workspace persistence is enabled)
  - Adequate resources (minimum 2 CPU, 4Gi RAM per pod)

## 🚀 Installation

### 1. Add Helm Repository

```bash
helm repo add hoverhuang-er https://hoverhuang-er.github.io/charts/
helm repo update
```

### 2. Create Values File

Create a `my-values.yaml` file with your configuration:

```yaml
magneticUI:
  openai:
    apiKey: "sk-your-openai-api-key-here"
    model: "gpt-4o-2024-08-06"

ingress:
  enabled: true
  className: "nginx"
  hosts:
    - host: magentic-ui.example.com
      paths:
        - path: /
          pathType: Prefix

resources:
  limits:
    cpu: 4000m
    memory: 8Gi
  requests:
    cpu: 2000m
    memory: 4Gi
```

### 3. Install the Chart

```bash
# Install with custom values
helm install magentic-ui hoverhuang-er/magentic-ui \
  --namespace magentic-ui \
  --create-namespace \
  -f my-values.yaml

# Or install with inline values
helm install magentic-ui hoverhuang-er/magentic-ui \
  --namespace magentic-ui \
  --create-namespace \
  --set magneticUI.openai.apiKey="your-api-key"
```

## 🔧 Configuration

### OpenAI API Configuration

```yaml
magneticUI:
  openai:
    # Option 1: Direct API key (not recommended for production)
    apiKey: "sk-..."
    
    # Option 2: Use existing Kubernetes secret
    existingSecret: "openai-secret"
    existingSecretKey: "apikey"
    
    # OpenAI model
    model: "gpt-4o-2024-08-06"
    
    # Custom endpoint (for Azure OpenAI or other providers)
    baseUrl: "https://your-azure-endpoint.openai.azure.com"
```

### Azure OpenAI Configuration

For Azure OpenAI, set the base URL:

```yaml
magneticUI:
  openai:
    apiKey: "your-azure-api-key"
    baseUrl: "https://your-resource.openai.azure.com"
    model: "gpt-4o"
```

### Workspace Persistence

Enable persistent storage for user data and sessions:

```yaml
magneticUI:
  workspace:
    enabled: true
    storageClass: "fast-ssd"
    size: 20Gi
    accessMode: ReadWriteOnce
```

### Resource Configuration

Adjust based on your workload:

```yaml
resources:
  # For light usage
  limits:
    cpu: 2000m
    memory: 4Gi
  requests:
    cpu: 1000m
    memory: 2Gi

  # For heavy usage (recommended)
  limits:
    cpu: 8000m
    memory: 16Gi
  requests:
    cpu: 4000m
    memory: 8Gi
```

### Database Configuration

By default, SQLite is used. For production, use PostgreSQL:

```yaml
database:
  type: postgresql
  postgresql:
    host: "postgresql.default.svc.cluster.local"
    port: 5432
    database: "magneticui"
    username: "magneticui"
    existingSecret: "postgresql-secret"
    existingSecretKey: "password"
```

### Ingress Configuration

```yaml
ingress:
  enabled: true
  className: "nginx"
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    nginx.ingress.kubernetes.io/proxy-body-size: "100m"
  hosts:
    - host: magentic-ui.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: magentic-ui-tls
      hosts:
        - magentic-ui.example.com
```

## 📊 Monitoring

### Health Checks

The chart includes liveness and readiness probes:

```yaml
livenessProbe:
  httpGet:
    path: /api/health
    port: 8081
  initialDelaySeconds: 30
  periodSeconds: 10

readinessProbe:
  httpGet:
    path: /api/health
    port: 8081
  initialDelaySeconds: 15
  periodSeconds: 5
```

### Logs

View application logs:

```bash
# Follow logs
kubectl logs -f deployment/magentic-ui -n magentic-ui

# View last 100 lines
kubectl logs --tail=100 deployment/magentic-ui -n magentic-ui
```

## 🔒 Security Considerations

### Privileged Containers

Magentic-UI requires privileged mode for Docker-in-Docker:

```yaml
securityContext:
  privileged: true
  capabilities:
    add:
      - SYS_ADMIN
```

**Security Implications:**
- Pods can access host resources
- Pods can modify kernel settings
- **Recommendation**: Deploy in isolated namespaces with network policies

### API Key Management

**Never commit API keys to version control!**

Create a Kubernetes secret:

```bash
kubectl create secret generic openai-secret \
  --from-literal=apikey='sk-your-api-key-here' \
  -n magentic-ui
```

Then reference it:

```yaml
magneticUI:
  openai:
    existingSecret: "openai-secret"
    existingSecretKey: "apikey"
```

### Network Policies

Restrict pod network access:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: magentic-ui-netpol
  namespace: magentic-ui
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: magentic-ui
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: ingress-nginx
    ports:
    - protocol: TCP
      port: 8081
  egress:
  - to:
    - namespaceSelector: {}
    ports:
    - protocol: TCP
      port: 443  # HTTPS for OpenAI API
```

## 🧪 Testing

### Access the UI

After installation:

```bash
# Port forward (for testing)
kubectl port-forward svc/magentic-ui 8081:8081 -n magentic-ui

# Open browser
open http://localhost:8081
```

### Verify Installation

```bash
# Check pod status
kubectl get pods -n magentic-ui

# Check logs
kubectl logs -f deployment/magentic-ui -n magentic-ui

# Test health endpoint
kubectl run -it --rm curl --image=curlimages/curl --restart=Never -- \
  curl http://magentic-ui:8081/api/health
```

## 🔧 Troubleshooting

### Pod Fails to Start

**Symptoms**: Pod stuck in `CrashLoopBackOff`

**Solutions**:
1. Check if privileged mode is allowed in your cluster
2. Verify API key is correct
3. Check resource availability

```bash
kubectl describe pod -l app.kubernetes.io/name=magentic-ui -n magentic-ui
kubectl logs -l app.kubernetes.io/name=magentic-ui -n magentic-ui
```

### Docker-in-Docker Issues

**Symptoms**: Browser automation or code execution fails

**Solutions**:
1. Ensure pod has `privileged: true`
2. Check if Docker socket is available
3. Verify sufficient disk space

### Out of Memory

**Symptoms**: Pod killed with OOMKilled

**Solutions**:
1. Increase memory limits
2. Reduce concurrent tasks
3. Monitor resource usage

```bash
kubectl top pod -n magentic-ui
```

## 📚 Values Reference

| Parameter | Description | Default |
|-----------|-------------|---------|
| `replicaCount` | Number of replicas | `1` |
| `image.repository` | Magentic-UI image repository | `ghcr.io/microsoft/magentic-ui` |
| `image.tag` | Image tag | `chart appVersion` |
| `magneticUI.openai.apiKey` | OpenAI API key | `""` |
| `magneticUI.openai.model` | OpenAI model | `"gpt-4o-2024-08-06"` |
| `magneticUI.config.port` | Web UI port | `8081` |
| `magneticUI.workspace.enabled` | Enable persistent workspace | `true` |
| `magneticUI.workspace.size` | Workspace PVC size | `10Gi` |
| `service.type` | Service type | `ClusterIP` |
| `service.port` | Main service port | `8081` |
| `ingress.enabled` | Enable ingress | `false` |
| `resources.limits.cpu` | CPU limit | `4000m` |
| `resources.limits.memory` | Memory limit | `8Gi` |
| `resources.requests.cpu` | CPU request | `2000m` |
| `resources.requests.memory` | Memory request | `4Gi` |
| `database.type` | Database type | `sqlite` |

For complete values reference, see [values.yaml](values.yaml).

## 🆕 Upgrading

```bash
# Update repository
helm repo update

# Upgrade release
helm upgrade magentic-ui hoverhuang-er/magentic-ui \
  --namespace magentic-ui \
  -f my-values.yaml

# Upgrade and wait for completion
helm upgrade magentic-ui hoverhuang-er/magentic-ui \
  --namespace magentic-ui \
  -f my-values.yaml \
  --wait --timeout 10m
```

## 🗑️ Uninstallation

```bash
# Delete release
helm uninstall magentic-ui -n magentic-ui

# Delete namespace (including PVCs)
kubectl delete namespace magentic-ui
```

## 🤝 Contributing

Contributions are welcome! Please see the [main repository](https://github.com/microsoft/magentic-ui) for contribution guidelines.

## 📄 License

This chart is released under the MIT License. See the main [Magentic-UI repository](https://github.com/microsoft/magentic-ui) for application license details.

## 🔗 Links

- [Magentic-UI GitHub](https://github.com/microsoft/magentic-ui)
- [Technical Report](https://www.microsoft.com/en-us/research/wp-content/uploads/2025/07/magentic-ui-report.pdf)
- [Blog Post](https://www.microsoft.com/en-us/research/blog/magentic-ui-an-experimental-human-centered-web-agent/)
- [Helm Charts Repository](https://github.com/Hoverhuang-er/charts)
