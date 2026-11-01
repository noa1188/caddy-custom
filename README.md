# Caddy Custom Build

一个自动构建**自定义 Caddy Docker 镜像**的项目。镜像基于官方 `caddy:builder` 使用 [`xcaddy`](https://github.com/caddybuild/xcaddy) 编译，预置常用插件；并通过 GitHub Actions 自动检测 Caddy 官方新版本、更新 `Dockerfile`、构建多架构镜像并发布到 Docker Hub / GitHub Container Registry。

## 特性

- 🧩 内置常用插件（CloudDNS、Desec、Cloudflare IP、Combine IP Ranges、WebDAV）
- 🔄 自动检测 Caddy 官方最新 release，版本号变化时自动更新 `Dockerfile`
- 🚀 版本变化时自动构建 `linux/amd64` + `linux/arm64` 多架构镜像并推送
- 📦 自动在版本号变化时创建 GitHub Release
- ⏭️ 版本号未更新时**不触发任何构建**，避免资源浪费
- 🛠️ 支持手动覆盖版本号

## 插件清单

| 插件 | 仓库 |
|------|------|
| Cloudflare DNS | `github.com/caddy-dns/cloudflare` |
| Desec DNS | `github.com/caddy-dns/desec` |
| Cloudflare IP（隐藏源站 IP） | `github.com/WeidiDeng/caddy-cloudflare-ip` |
| Combine IP Ranges | `github.com/fvbommel/caddy-combine-ip-ranges` |
| WebDAV | `github.com/mholt/caddy-webdav` |

插件版本在 `Dockerfile` 中以 `ARG PLUGIN_*` 声明，需要升级时手动改对应行后提交即可。

---

## 本地构建

```bash
# 使用 Dockerfile 中默认的版本
docker build -t caddy-custom .

# 覆盖 Caddy 版本号（例如升级到 2.10.x）
docker build --build-arg CADDY_VERSION=2.10.2 -t caddy-custom .
```

构建产物为可直接运行的镜像，入口点为 `caddy`：

```bash
docker run -p 80:80 -p 443:443 --rm -v "$PWD/Caddyfile:/etc/caddy/Caddyfile" caddy-custom
```

---

## GitHub Actions 自动化

项目包含两个 Workflow，分别在 `.github/workflows/` 下：

### 1. `check-version.yml` —— 检测上游版本

- **触发**：每 3 天定时（cron `5 1 */3 * *`）或手动 `workflow_dispatch`。
- **逻辑**：
  1. 读取 `Dockerfile` 中当前的 `CADDY_VERSION`；
  2. 查询 GitHub 上 `caddyserver/caddy` 的 `releases/latest`；
  3. **仅当两者不一致时**，用 `sed` 更新 `Dockerfile`、提交并 push。

版本号未变化时该流程**不做任何改动**。

### 2. `build.yml` —— 构建并发布镜像

- **触发**：
  - `push` 到 `main` 分支（由 check 流程版本变更触发）；
  - 手动 `workflow_dispatch`，可输入 `caddy_version` 覆盖版本号。
- **逻辑**：
  1. 从 `Dockerfile`（或手动输入）取版本号；
  2. 登录 Docker Hub 与 GHCR；
  3. `docker buildx` 构建 `linux/amd64,linux/arm64` 多架构镜像，推送以下标签：
     - `$DOCKERHUB_USERNAME/caddy-custom:$VERSION` 与 `:latest`
     - `ghcr.io/<owner>/caddy-custom:$VERSION` 与 `:latest`
  4. **仅当由 `push` 触发（即版本号真正变化）时**创建 GitHub Release。

### 触发与 Release 逻辑一览

| 场景 | 是否构建 | 是否发 Release |
|------|---------|----------------|
| check 检测到新版本 → 写 Dockerfile + push | ✅ 是 | ✅ 是 |
| check 未检测到更新（无改动） | ❌ 否 | ❌ 否 |
| 手动 `workflow_dispatch`（带/不带版本号） | ✅ 是 | ❌ 否 |

> 说明：`main` 上的 push **只**由 check 流程产生，而它只在版本号真正变化时才 commit+push。因此「`push` 触发」等价于「版本号真正变了」，Release 锁定该条件即可同时满足「自动发版」与「重复构建不报错」。

---

## Secrets 配置

在仓库 **Settings → Secrets and variables → Actions** 中添加：

| Secret | 用途 |
|--------|------|
| `DOCKERHUB_USERNAME` | Docker Hub 用户名（推送镜像） |
| `DOCKERHUB_TOKEN` | Docker Hub 访问令牌（推送镜像） |

> `GITHUB_TOKEN` 由 GitHub 自动提供，无需手动添加，用于 GHCR 登录与 Release 创建。

---

## 日常维护

- **升级 Caddy 主体版本**：check 流程会自动完成；或手动在 `Dockerfile` 改 `CADDY_VERSION` 后提交触发构建。
- **升级某个插件**：编辑 `Dockerfile` 中对应 `ARG PLUGIN_*`，提交后构建会使用该新版本。
- **手动强制构建**：Actions 面板运行 `Build and Push`，输入想要的版本号即可。

---

## 本地调试 Workflow（可选）

使用 [`act`](https://github.com/nektos/act) 在本地模拟 GitHub Actions：

```bash
# 安装 act 后
act -l            # 列出所有 workflow 与触发
act check-version -l   # 查看 check-version 具体 steps
act check-version -W .github/workflows/check-version.yml
```

---

## 参考

- [Caddy 官方文档](https://caddy.dev/docs)
- [xcaddy 文档](https://github.com/caddybuild/xcaddy)
- [caddy-dns/cloudflare](https://github.com/caddy-dns/cloudflare)
