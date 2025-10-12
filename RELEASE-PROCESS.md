# 🚀 完整发布流程总结

## 📦 发布目标

每次推送 Git tag 时，自动发布 Helm charts 到：
1. **GitHub Container Registry (GHCR)** - OCI 格式
2. **GitHub Releases** - 下载 .tgz 包
3. **GitHub Pages** - 传统 Helm repository
4. **ArtifactHub** - 公开发现和搜索

---

## ✅ 当前配置

### 1. ArtifactHub 仓库信息
- **Repository ID**: `3f23160a-c6e3-4a58-b5e4-a04c3fd1dac8`
- **Name**: Azure AI Service
- **URL**: https://hoverhuang-er.github.io/charts/
- **Type**: Helm charts

### 2. GitHub Secrets 配置
需要在 GitHub 仓库设置中配置以下 secrets：

- `GHTOKEN` - GitHub Personal Access Token (用于推送和发布)
  - 权限: `repo`, `packages:write`, `contents:write`
  
- `ARTIFACTHUB_API_KEY` - ArtifactHub API Key ID
  - 从 ArtifactHub Control Panel 获取
  
- `ARTIFACTHUB_API_SEC` - ArtifactHub API Key Secret
  - 从 ArtifactHub Control Panel 获取

### 3. 仓库结构
```
charts/
├── .github/
│   └── workflows/
│       └── publish.yml          # 自动发布 workflow
├── Microsoft/
│   ├── azure-ai-services/
│   │   └── charts/
│   │       ├── document-intelligence/
│   │       │   ├── Chart.yaml
│   │       │   ├── values.yaml
│   │       │   └── templates/
│   │       └── content-safety/
│   │           └── Chart.yaml
│   └── opensources/
│       └── magentic-ui/
│           └── Chart.yaml
├── artifacthub-repo.yml         # ArtifactHub 元数据
├── publishv2.sh                 # 打包和推送脚本
├── index.yaml                   # Helm repository 索引
└── README.md
```

---

## 🔄 自动发布流程

### 触发条件
```bash
# 推送 tag 时触发
git tag -a v0.1.0 -m "Release v0.1.0"
git push origin v0.1.0

# 或推送带前缀的 tag
git tag -a document-intelligence-v0.1.0 -m "Release document-intelligence v0.1.0"
git push origin document-intelligence-v0.1.0
```

### Workflow 步骤

1. **检出代码** (`actions/checkout@v4`)
   - 获取完整的 Git 历史 (`fetch-depth: 0`)

2. **设置 Helm** (`azure/setup-helm@v4`)
   - 安装 Helm 3.8.0+
   - 启用 OCI 支持

3. **检测 Tag 信息**
   - 判断是否为 tag 触发
   - 提取 tag 名称

4. **登录 GHCR**
   - 使用 `GHTOKEN` 认证
   - 登录到 `ghcr.io`

5. **打包和推送 Charts**
   - 递归查找所有 `Chart.yaml`
   - 更新依赖 (`helm dependency update`)
   - 打包 charts (`helm package`)
   - 推送到 GHCR (`helm push`)
   - 保留 .tgz 文件（仅在 tag 构建时）

6. **创建 GitHub Release**
   - 使用 `softprops/action-gh-release@v1`
   - 上传所有 .tgz 文件
   - 自动生成 Release Notes

7. **更新 Helm Repository Index**
   - 复制 .tgz 文件到 `helm-repo/`
   - 生成 `index.yaml`
   - 添加 `artifacthub-repo.yml`

8. **部署到 GitHub Pages**
   - 使用 `peaceiris/actions-gh-pages@v3`
   - 推送到 `gh-pages` 分支
   - 发布到 https://hoverhuang-er.github.io/charts/

9. **触发 ArtifactHub 扫描**
   - 调用 ArtifactHub Scan API
   - 使用仓库 UUID: `3f23160a-c6e3-4a58-b5e4-a04c3fd1dac8`
   - 触发立即更新

---

## 📥 用户使用方式

### 方式 1: 从 GHCR 拉取（推荐）
```bash
# 安装
helm install my-doc-intel oci://ghcr.io/hoverhuang-er/charts/document-intelligence --version 0.1.0

# 拉取到本地
helm pull oci://ghcr.io/hoverhuang-er/charts/document-intelligence --version 0.1.0
```

### 方式 2: 从 Helm Repository 安装
```bash
# 添加仓库
helm repo add hoverhuang-er https://hoverhuang-er.github.io/charts/

# 更新
helm repo update

# 搜索
helm search repo hoverhuang-er

# 安装
helm install my-doc-intel hoverhuang-er/document-intelligence
```

### 方式 3: 从 GitHub Release 下载
1. 访问: https://github.com/Hoverhuang-er/charts/releases
2. 选择版本（如 v0.1.0）
3. 下载 .tgz 文件
4. 本地安装: `helm install my-doc-intel ./document-intelligence-0.1.0.tgz`

### 方式 4: 从 ArtifactHub 发现
1. 访问: https://artifacthub.io/packages/search?org=azure-ai-service
2. 选择 chart
3. 查看安装说明

---

## 🔧 维护和更新

### 发布新版本
```bash
# 1. 更新 Chart.yaml 中的版本号
vim Microsoft/azure-ai-services/charts/document-intelligence/Chart.yaml
# version: 0.2.0

# 2. 提交更改
git add .
git commit -m "chore: bump document-intelligence to v0.2.0"
git push

# 3. 创建并推送 tag
git tag -a v0.2.0 -m "Release v0.2.0: New features"
git push origin v0.2.0

# 4. GitHub Actions 自动处理剩余步骤
```

### 手动触发扫描
如果 ArtifactHub 没有自动更新，可以手动触发：

```bash
# 设置环境变量
export ARTIFACTHUB_API_KEY="your-api-key-id"
export ARTIFACTHUB_API_SEC="your-api-key-secret"

# 触发扫描
curl -X POST \
  "https://artifacthub.io/api/v1/repositories/3f23160a-c6e3-4a58-b5e4-a04c3fd1dac8/scan" \
  -H "X-API-Key-ID: ${ARTIFACTHUB_API_KEY}" \
  -H "X-API-Key-Secret: ${ARTIFACTHUB_API_SEC}"
```

### 更新现有 Chart
```bash
# 1. 修改 chart 文件
vim Microsoft/azure-ai-services/charts/document-intelligence/values.yaml

# 2. 更新版本号（Chart.yaml）
# version: 0.1.1

# 3. 提交并推送
git add .
git commit -m "fix: update default values"
git push

# 4. 创建 patch 版本 tag
git tag -a v0.1.1 -m "Release v0.1.1: Bug fixes"
git push origin v0.1.1
```

---

## 🐛 故障排查

### Charts 没有发布到 GHCR
**检查**:
```bash
# 查看 workflow 日志
gh run list --workflow=publish.yml --limit 5
gh run view <run-id> --log

# 验证 GHTOKEN 权限
# 需要: repo, packages:write, contents:write
```

### GitHub Pages 没有更新
**检查**:
```bash
# 确认 gh-pages 分支存在
git ls-remote --heads origin gh-pages

# 访问 GitHub Pages URL
curl -I https://hoverhuang-er.github.io/charts/index.yaml

# 检查 index.yaml 内容
curl https://hoverhuang-er.github.io/charts/index.yaml
```

### ArtifactHub 没有显示新版本
**解决方案**:
1. 等待 5-30 分钟（自动同步周期）
2. 检查 workflow 日志中的 "Trigger ArtifactHub Repository Scan" 步骤
3. 手动在 ArtifactHub 控制面板点击 "Refresh"
4. 使用上面的 curl 命令手动触发扫描

### .tgz 文件没有上传到 Release
**检查**:
```bash
# 查看 publishv2.sh 的输出
gh run view <run-id> --log | grep "Keeping packaged archives"

# 应该显示: "Keeping packaged archives for GitHub Release"
# 如果显示: "Cleaning packaged archives"，说明 IS_TAG 环境变量没有正确传递
```

---

## 📊 监控和验证

### 验证发布成功
```bash
# 1. 检查 GHCR packages
open https://github.com/Hoverhuang-er?tab=packages

# 2. 检查 GitHub Releases
open https://github.com/Hoverhuang-er/charts/releases

# 3. 检查 GitHub Pages
curl https://hoverhuang-er.github.io/charts/index.yaml

# 4. 检查 ArtifactHub
open https://artifacthub.io/packages/search?org=azure-ai-service

# 5. 测试 Helm 安装
helm pull oci://ghcr.io/hoverhuang-er/charts/document-intelligence --version 0.1.0
```

### 查看发布历史
```bash
# GitHub Actions runs
gh run list --workflow=publish.yml --limit 10

# Git tags
git tag -l -n

# Releases
gh release list
```

---

## 📚 相关文档

- [ArtifactHub API Documentation](https://artifacthub.io/docs/api/)
- [Helm OCI Registry Guide](https://helm.sh/docs/topics/registries/)
- [GitHub Actions Workflows](https://docs.github.com/en/actions/using-workflows)
- [GitHub Container Registry](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)
- [GitHub Pages Deployment](https://docs.github.com/en/pages)

---

## 🎯 下一步优化

- [ ] 添加自动化测试（chart linting, validation）
- [ ] 添加 chart 版本兼容性检查
- [ ] 实现多环境部署（dev, staging, prod）
- [ ] 添加 changelog 自动生成
- [ ] 集成 Slack/Email 通知
- [ ] 添加 chart 依赖自动更新检测
