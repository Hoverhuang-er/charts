# 快速入门指南 - Azure AI 文档智能

**语言：** [English](QUICKSTART.md) | [简体中文](QUICKSTART.zh-CN.md) ｜ [国内版本](https://kcntz7ffdm6b.feishu.cn/wiki/U0KNwlUPyiLTCFkkP3QcFitlngg)

## 🚀 快速安装

### 步骤 1：下载许可证（仅首次）
```bash
helm install document-intelligence ./document-intelligence \
  --set documentIntelligence.azure.billingEndpoint="https://YOUR-RESOURCE.cognitiveservices.azure.com" \
  --set documentIntelligence.azure.apiKey="YOUR-API-KEY" \
  --set documentIntelligence.azure.downloadLicense=true
```

等待许可证下载（查看日志）：
```bash
kubectl logs -f deployment/document-intelligence
```

### 步骤 2：切换到离线模式
```bash
helm upgrade document-intelligence ./document-intelligence \
  --set documentIntelligence.azure.downloadLicense=false
```

### 步骤 3：访问 API
```bash
kubectl port-forward svc/document-intelligence 5000:5000
```

测试：
```bash
curl http://localhost:5000/status
```

## 📋 常用命令

### 检查部署状态
```bash
kubectl get pods -l app.kubernetes.io/name=document-intelligence
kubectl describe deployment document-intelligence
```

### 查看日志
```bash
kubectl logs deployment/document-intelligence
```

### 访问使用记录
```bash
# 所有记录
curl http://localhost:5000/records/usage-logs/

# 特定月份（例如，2025年12月）
curl http://localhost:5000/records/usage-logs/12/2025
```

### 检查 PVC
```bash
kubectl get pvc
kubectl describe pvc document-intelligence-license
kubectl describe pvc document-intelligence-output
```

## 🔧 配置示例

### 部署发票模型
```bash
helm install invoice ./document-intelligence \
  --set image.repository="mcr.microsoft.com/azure-cognitive-services/form-recognizer/invoice-3.0" \
  --set documentIntelligence.modelType=invoice
```

### 配置 Ingress 控制器

#### Azure 负载均衡器（默认）
```bash
helm install document-intelligence ./document-intelligence \
  --set ingress.controllerType=azure-loadbalancer
```

#### 应用程序网关
```bash
helm install document-intelligence ./document-intelligence \
  --set ingress.controllerType=application-gateway
```

#### NGINX Ingress
```bash
helm install document-intelligence ./document-intelligence \
  --set ingress.controllerType=nginx
```

### 设置 Kubernetes 版本
```bash
# Kubernetes 1.24
helm install document-intelligence ./document-intelligence \
  --set kubernetesVersion="1.24"

# 1.24 之前的版本（禁用 securityContext）
helm install document-intelligence ./document-intelligence \
  --set kubernetesVersion="pre-1.24"
```

### 使用 LoadBalancer 服务
```bash
helm upgrade document-intelligence ./document-intelligence \
  --set service.type=LoadBalancer
```

### 增加资源
```bash
helm upgrade document-intelligence ./document-intelligence \
  --set resources.requests.memory=20Gi \
  --set resources.limits.memory=32Gi
```

## 🐛 故障排除

### Pod 无法启动
```bash
# 检查事件
kubectl describe pod <pod-name>

# 检查资源可用性
kubectl top nodes

# 验证 PVC 已绑定
kubectl get pvc
```

### 许可证丢失
```bash
# 重新下载许可证
helm upgrade document-intelligence ./document-intelligence \
  --set documentIntelligence.azure.downloadLicense=true \
  --set documentIntelligence.azure.billingEndpoint="..." \
  --set documentIntelligence.azure.apiKey="..."
```

### 检查许可证文件
```bash
kubectl exec deployment/document-intelligence -- ls -la /license
```

## 📊 支持的模型

| 模型 | 仓库路径 |
|------|---------|
| 布局 (Layout) | `form-recognizer/layout-3.0` |
| 发票 (Invoice) | `form-recognizer/invoice-3.0` |
| 收据 (Receipt) | `form-recognizer/receipt-3.0` |
| 名片 (Business Card) | `form-recognizer/businesscard-3.0` |
| 身份证件 (ID Document) | `form-recognizer/idDocument-3.0` |
| 通用文档 (General Document) | `form-recognizer/generaldocument-3.0` |
| 自定义模板 (Custom Template) | `form-recognizer/custom-template-3.0` |

所有仓库前缀：`mcr.microsoft.com/azure-cognitive-services/`

## 🔐 安全最佳实践

1. **永远不要提交 API 密钥**：使用 `--set` 参数或外部密钥管理器
2. **使用 Sealed Secrets** 或 **External Secrets Operator** 用于生产环境
3. **使用 RBAC 策略限制 PVC 访问**
4. **启用网络策略**以限制 API 访问
5. **定期轮换** API 密钥

## 📖 更多信息

- 完整文档：`README.zh-CN.md`
- 实现细节：`IMPLEMENTATION.md`
- 示例配置：`examples.yaml`
- 微软文档：https://learn.microsoft.com/zh-cn/azure/ai-services/document-intelligence/containers/disconnected
