# Azure AI Document Intelligent Helm Chart

**语言：** [English](README.md) | [简体中文](README.zh-CN.md) | [国内访问](https://kcntz7ffdm6b.feishu.cn/wiki/U0KNwlUPyiLTCFkkP3QcFitlngg)

此 Helm Chart 用于在 Kubernetes 上以离线（断开连接）模式部署 Azure AI 文档智能容器。

## 概述

Azure AI 文档智能容器允许您在本地运行文档智能 API，享受容器化带来的好处。离线容器专为初始设置后无需与 Azure 云连接的场景而设计。

## 前置条件

- Kubernetes 1.23+
- Helm 3.8.0+
- 具有离线容器承诺层级的 Azure AI 文档智能资源
- 足够的集群资源（每个 Pod 最少 8 核、16GB 内存）
- 持久存储配置器（用于许可证和日志）

## 已知限制

**我们诚挚地为本 Chart 在特殊字符兼容性方面的限制致歉。**

由于 Kubernetes 环境变量命名限制和本 Chart 使用的配置方式，在使用某些特殊字符作为环境变量分隔符时存在以下已知限制：

1. **冒号（`:`）不支持**作为可配置的分隔符 - 这是一个 Kubernetes 强制的限制，在当前的实现中我们无法绕过
2. Chart 默认使用双下划线（`__`）作为分隔符，以实现最大的兼容性
3. 虽然点（`.`）、连字符（`-`）和单下划线（`_`）技术上是支持的，但在某些 Kubernetes 版本或环境中可能会导致问题

我们理解，当从使用冒号分隔符的配置迁移时，此限制可能会给您带来不便。我们正在努力在未来版本中改进这一点，在保持 Kubernetes 兼容性的同时提供更好的灵活性。如果您有需要使用其他分隔符字符的特定用例，请提交 Issue，以便我们更好地了解您的需求。

有关详细配置选项和变通方法，请参阅下方的[环境变量分隔符配置](#环境变量分隔符配置)部分。

## 支持的模型

此 Chart 支持以下文档智能模型：

| 模型 | 镜像仓库 | 最小内存 | 推荐内存 |
|------|---------|---------|---------|
| 布局 (Layout) | `form-recognizer/layout-3.0` | 16GB | 24GB |
| 发票 (Invoice) | `form-recognizer/invoice-3.0` | 16GB | 24GB |
| 收据 (Receipt) | `form-recognizer/receipt-3.0` | 11GB | 24GB |
| 名片 (Business Card) | `form-recognizer/businesscard-3.0` | 16GB | 24GB |
| 身份证件 (ID Document) | `form-recognizer/idDocument-3.0` | 8GB | 24GB |
| 通用文档 (General Document) | `form-recognizer/generaldocument-3.0` | 12GB | 24GB |
| 自定义模板 (Custom Template) | `form-recognizer/custom-template-3.0` | 16GB | 24GB |

## 安装

### 步骤 1：申请访问权限

在使用离线容器之前：
1. 提交[访问申请表单](https://aka.ms/csdisconnectedcontainers)
2. 在 Azure 门户中购买承诺计划
3. 创建具有"承诺层级离线容器 DC0"定价层级的 Azure AI 文档智能资源

### 步骤 2：初始设置（下载许可证）

首先，启用许可证下载来部署 Chart 以获取许可证文件：

```bash
helm install document-intelligence ./document-intelligence \
  --set documentIntelligence.azure.billingEndpoint="https://your-resource.cognitiveservices.azure.com" \
  --set documentIntelligence.azure.apiKey="your-api-key" \
  --set documentIntelligence.azure.downloadLicense=true
```

等待 Pod 完成许可证下载（查看日志）：

```bash
kubectl logs -f deployment/document-intelligence
```

### 步骤 3：切换到离线模式

许可证下载完成后，升级到离线模式：

```bash
helm upgrade document-intelligence ./document-intelligence \
  --set documentIntelligence.azure.downloadLicense=false
```

## 配置

### 主要参数

| 参数 | 描述 | 默认值 |
|------|-----|-------|
| `kubernetesVersion` | Kubernetes 版本 (1.32, 1.28, 1.26, 1.24, pre-1.24) | `1.32` |
| `image.repository` | 容器镜像仓库 | `mcr.microsoft.com/azure-cognitive-services/form-recognizer/layout-3.0` |
| `image.tag` | 容器镜像标签 | `latest` |
| `documentIntelligence.modelType` | 模型类型（layout, invoice 等） | `layout` |
| `documentIntelligence.azure.billingEndpoint` | Azure 计费端点（用于许可证下载） | `""` |
| `documentIntelligence.azure.apiKey` | Azure API 密钥（用于许可证下载） | `""` |
| `documentIntelligence.azure.downloadLicense` | 启用许可证下载模式 | `false` |
| `documentIntelligence.license.mountPath` | 许可证存储路径 | `/license` |
| `documentIntelligence.license.storageSize` | 许可证 PVC 大小 | `1Gi` |
| `documentIntelligence.output.mountPath` | 使用日志存储路径 | `/logs` |
| `documentIntelligence.output.storageSize` | 输出 PVC 大小 | `5Gi` |
| `ingress.enabled` | 启用 Ingress | `true` |
| `ingress.controllerType` | Ingress 控制器（azure-loadbalancer, application-gateway, nginx） | `azure-loadbalancer` |
| `resources.requests.memory` | 内存请求 | `16Gi` |
| `resources.requests.cpu` | CPU 请求 | `8` |
| `resources.limits.memory` | 内存限制 | `24Gi` |
| `resources.limits.cpu` | CPU 限制 | `8` |
| `service.type` | Kubernetes 服务类型 | `ClusterIP` |
| `service.port` | 服务端口 | `5000` |

### 示例：部署发票模型

```bash
helm install invoice-analyzer ./document-intelligence \
  --set image.repository="mcr.microsoft.com/azure-cognitive-services/form-recognizer/invoice-3.0" \
  --set documentIntelligence.modelType=invoice \
  --set documentIntelligence.azure.billingEndpoint="https://your-resource.cognitiveservices.azure.com" \
  --set documentIntelligence.azure.apiKey="your-api-key" \
  --set documentIntelligence.azure.downloadLicense=true
```

### Kubernetes 版本兼容性

此 Chart 支持多个 Kubernetes 版本。设置 `kubernetesVersion` 参数：

```bash
# Kubernetes 1.32（默认）
helm install document-intelligence ./document-intelligence

# Kubernetes 1.24
helm install document-intelligence ./document-intelligence \
  --set kubernetesVersion="1.24"

# Kubernetes 1.24 之前的版本（禁用 securityContext）
helm install document-intelligence ./document-intelligence \
  --set kubernetesVersion="pre-1.24"
```

**注意：** Kubernetes 1.24 之前的版本将禁用 `securityContext` 以确保兼容性。

### Ingress 配置

Chart 默认创建 Ingress 资源。选择您的 Ingress 控制器：

#### Azure 负载均衡器（默认）

```bash
helm install document-intelligence ./document-intelligence \
  --set ingress.controllerType="azure-loadbalancer" \
  --set ingress.hosts[0].host="document-intelligence.example.com"
```

#### Azure 应用程序网关 Ingress 控制器（AGIC）

```bash
helm install document-intelligence ./document-intelligence \
  --set ingress.controllerType="application-gateway" \
  --set ingress.hosts[0].host="document-intelligence.example.com"
```

#### NGINX Ingress 控制器

```bash
helm install document-intelligence ./document-intelligence \
  --set ingress.controllerType="nginx" \
  --set ingress.hosts[0].host="document-intelligence.example.com"
```

#### 禁用 Ingress

```bash
helm install document-intelligence ./document-intelligence \
  --set ingress.enabled=false
```

### 使用现有的 PVC

如果您已有许可证或日志的 PersistentVolumeClaim：

```bash
helm install document-intelligence ./document-intelligence \
  --set documentIntelligence.license.existingClaim="my-license-pvc" \
  --set documentIntelligence.output.existingClaim="my-output-pvc"
```

### 自定义 values.yaml

创建 `my-values.yaml` 文件：

```yaml
kubernetesVersion: "1.32"

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

ingress:
  enabled: true
  controllerType: nginx
  hosts:
    - host: document-intelligence.example.com
      paths:
        - path: /
          pathType: Prefix

resources:
  requests:
    cpu: "8"
    memory: 20Gi
  limits:
    cpu: "8"
    memory: 24Gi

service:
  type: ClusterIP
```

使用自定义值进行安装：

```bash
helm install document-intelligence ./document-intelligence -f my-values.yaml
```

## 使用

### 访问 API

部署后，访问文档智能 API：

```bash
# 端口转发到本地机器
kubectl port-forward svc/document-intelligence 5000:5000

# 测试端点
curl http://localhost:5000/status
```

### 分析文档

使用文档智能 API 分析文档：

```bash
curl -X POST "http://localhost:5000/formrecognizer/v3.0/layout/analyze" \
  -H "Content-Type: application/json" \
  -d @document.json
```

### 监控使用情况

查看使用日志：

```bash
# 获取所有使用记录
curl http://localhost:5000/records/usage-logs/

# 获取特定月份的记录（例如，2025 年 1 月）
curl http://localhost:5000/records/usage-logs/01/2025
```

### 访问使用日志 PVC

直接检查使用日志：

```bash
kubectl exec -it deployment/document-intelligence -- ls /logs
```

## 多容器设置

对于需要多个容器的自定义模型（例如，custom-template + layout）：

```yaml
documentIntelligence:
  shared:
    enabled: true
    storageSize: 20Gi
```

## 故障排除

### 容器无法启动

1. 检查日志：
   ```bash
   kubectl logs deployment/document-intelligence
   ```

2. 验证资源是否足够：
   ```bash
   kubectl describe pod <pod-name>
   ```

3. 确保 PVC 中存在许可证文件

### 许可证文件丢失

如果在离线模式下运行但没有许可证：
1. 切换回下载模式
2. 设置 `documentIntelligence.azure.downloadLicense=true`
3. 提供有效的计费端点和 API 密钥
4. 等待下载完成
5. 切换回离线模式

### 使用日志未显示

检查输出 PVC 是否正确挂载：
```bash
kubectl describe pvc document-intelligence-output
```

### 性能问题

增加资源分配：
```yaml
resources:
  requests:
    memory: 24Gi
    cpu: "10"
  limits:
    memory: 32Gi
    cpu: "12"
```

## 许可证过期

许可证文件有过期日期。过期时：
1. 重新启用下载模式
2. 下载新的许可证文件
3. 返回离线模式

## 安全注意事项

- 安全存储 Azure API 密钥（使用 Sealed Secrets 或外部密钥存储）
- 限制对服务的网络访问
- 使用 RBAC 限制对包含许可证文件的 PVC 的访问
- 定期轮换 API 密钥

## 参考资料

- [官方文档](https://learn.microsoft.com/zh-cn/azure/ai-services/document-intelligence/containers/disconnected)
- [容器镜像](https://mcr.microsoft.com/catalog?search=form-recognizer)
- [API 参考](https://learn.microsoft.com/zh-cn/azure/ai-services/document-intelligence/overview)
- [离线容器常见问题](https://learn.microsoft.com/zh-cn/azure/ai-services/containers/disconnected-container-faq)

## 支持

相关问题：
- Helm Chart：在此仓库中提交 Issue
- Azure AI 服务：联系 Azure 支持
- 容器镜像：检查 Microsoft 容器注册表状态
