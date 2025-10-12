# 🚀 ArtifactHub 集成指南

## 当前状态

✅ **已完成：**
- Charts 已发布到 GHCR: `oci://ghcr.io/hoverhuang-er/charts`
- GitHub Release 已创建: https://github.com/Hoverhuang-er/charts/releases/tag/v0.1.0
- GitHub Pages 已部署: https://hoverhuang-er.github.io/charts/
- `index.yaml` 和 `artifacthub-repo.yml` 已正确配置

## 📋 在 ArtifactHub 上注册仓库

### 方法 1: 网页手动注册（推荐）

1. **登录 ArtifactHub**
   - 访问: https://artifacthub.io/
   - 点击右上角登录（使用 GitHub 账号）

2. **添加仓库**
   - 进入 Control Panel: https://artifacthub.io/control-panel/repositories
   - 点击 **"ADD REPOSITORY"** 或 **"+"** 按钮

3. **填写仓库信息**
   ```
   Name: hoverhuang-er-charts
   Display name: Helm Charts Collection
   URL: https://hoverhuang-er.github.io/charts/
   Kind: Helm charts
   ```

4. **等待索引**
   - 提交后，ArtifactHub 会自动爬取你的 `index.yaml`
   - 通常需要 5-30 分钟完成索引
   - 你可以在仓库设置中点击 "Refresh" 强制更新

### 方法 2: 使用 API（如果有权限问题）

如果网页添加失败，可以使用 API：

```bash
# 设置环境变量
export ARTIFACTHUB_API_KEY="your-api-key-id"
export ARTIFACTHUB_API_SEC="your-api-key-secret"

# 运行注册脚本
chmod +x register-artifacthub.sh
./register-artifacthub.sh
```

## 🔍 验证部署

### 检查 GitHub Pages
```bash
# 检查 index.yaml
curl https://hoverhuang-er.github.io/charts/index.yaml

# 检查 artifacthub-repo.yml
curl https://hoverhuang-er.github.io/charts/artifacthub-repo.yml

# 检查 chart 包
curl -I https://hoverhuang-er.github.io/charts/document-intelligence-0.1.0.tgz
```

### 测试 Helm 安装
```bash
# 添加仓库
helm repo add hoverhuang-er https://hoverhuang-er.github.io/charts/
helm repo update

# 搜索 charts
helm search repo hoverhuang-er

# 从 GHCR 拉取
helm pull oci://ghcr.io/hoverhuang-er/charts/document-intelligence --version 0.1.0
```

## 📝 `artifacthub-repo.yml` 说明

你的仓库根目录（GitHub Pages）已包含此文件：

```yaml
repositoryID: hoverhuang-er-charts
owners:
  - name: Hoverhuang-er
    email: hoverhuang-er@users.noreply.github.com
```

这个文件告诉 ArtifactHub：
- 仓库的唯一 ID
- 仓库的所有者信息
- 用于验证所有权和显示 "Verified Publisher" 标签

## 🔧 故障排查

### 仓库不显示在 ArtifactHub
1. **等待时间**: 首次添加需要 5-30 分钟
2. **强制刷新**: 在 ArtifactHub 仓库设置中点击 "Refresh"
3. **检查 URL**: 确认 `https://hoverhuang-er.github.io/charts/` 可访问
4. **验证 index.yaml**: 确认包含有效的 chart 条目

### API 调用失败
- 确认 API Key 和 Secret 正确
- 检查 API Key 的权限范围
- 查看 ArtifactHub API 文档: https://artifacthub.io/docs/api/

### Charts 不更新
每次推送新 tag 时，workflow 会自动：
1. 打包所有 charts
2. 推送到 GHCR
3. 创建 GitHub Release
4. 更新 GitHub Pages
5. 通知 ArtifactHub

如果 ArtifactHub 没有更新，手动点击 "Refresh" 按钮。

## 🌐 访问你的 Charts

发布后，用户可以通过以下方式访问：

**ArtifactHub:**
- 搜索: https://artifacthub.io/packages/search?repo=hoverhuang-er-charts
- 你的仓库: https://artifacthub.io/packages/search?user=Hoverhuang-er

**GitHub:**
- Release: https://github.com/Hoverhuang-er/charts/releases
- Packages: https://github.com/Hoverhuang-er?tab=packages

**Helm 命令:**
```bash
# 传统 Helm repo
helm repo add hoverhuang-er https://hoverhuang-er.github.io/charts/

# OCI registry (GHCR)
helm pull oci://ghcr.io/hoverhuang-er/charts/document-intelligence
```

## 🎯 下一步

1. ✅ 登录 ArtifactHub 并手动添加仓库
2. ✅ 等待自动索引完成（5-30分钟）
3. ✅ 在 ArtifactHub 上验证 charts 显示
4. ✅ 测试从 ArtifactHub 安装 charts
5. ✅ （可选）添加 README 徽章显示 ArtifactHub 链接
