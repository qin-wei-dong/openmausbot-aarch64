# OpenMausBot aarch64 离线包

## 这是什么

为 **UOS 20 / aarch64 / 内网（无外网）** 环境准备的 OpenMausBot 离线部署包。
对应版本：源码 `v0.1.170`（main 分支快照），Node `24.22.3` (linux-arm64)，pnpm `10.33.0`。

所有依赖已在 **linux/arm64 容器** 内通过 `pnpm install` 真实产出，原生模块为 ARM aarch64 版本，
已验证 `pnpm install --offline --frozen-lockfile` 可仅凭本包的 store 完整重建依赖，且 `pnpm omb serve --lan` 可正常启动。

## 目录结构

```
omb-offline/
├── install.sh                    # 一键部署脚本
├── config.json.template          # 内网模型接入配置模板
├── node-v24.22.3-linux-arm64.tar.xz   # Node 运行时
├── pnpm-10.33.0.tgz              # pnpm 包管理器
├── pnpm-store/                   # pnpm 内容寻址依赖缓存（2.3G，已分卷）
└── source/                       # 源码（含构建好的 dist/ 前端，不含 node_modules）
```

## 部署步骤（内网机）

### 0. 上传到内网机

把本包上传到你私有仓库的 Release，在内网机下载后合并分卷并解压：

```sh
cat pnpm-store.tar.gz.part-* > pnpm-store.tar.gz
tar xzf pnpm-store.tar.gz        # 得到 pnpm-store/ 目录
```

### 1. 修改模型配置

编辑 `config.json.template`，把 `url` / `model` / `OMB_KEY` 改成你的内网 OpenAI 兼容模型信息，
或直接改好后放到 `~/.openmausbot/config.json`。

> 驱动为 `openai-compat`，要求端点是 OpenAI 兼容格式（有 `/v1/chat/completions`）。
> 若模型不支持工具调用，在 `config` 中加 `"tools": false`。

### 2. 一键部署

```sh
chmod +x install.sh
./install.sh
```

脚本会：解压 Node 24 → 启用 pnpm 10.33 → 配置 store → 离线重建依赖 → 生成配置模板。

### 3. 启动

```sh
cd source
export PATH="$(pwd)/../node-v24.22.3-linux-arm64/bin:$PATH"
pnpm omb serve --lan
```

浏览器打开终端打印的 pairing link（形如 `http://<内网IP>:8799/pair#code=…`）即可使用。
`dist/` 前端已预先构建，浏览器能正常显示页面。

## 二次开发

改动集中在 `source/server/drivers/`：SPI 很小，改一个文件 + 一行注册即可接入新引擎。
改完重启 server 生效，无需重新打包 `.deb`。

## 合规

- 主项目 Apache-2.0；`source/enterprise/` 目录为 source-available 单独许可，**商用分发前请删除该目录**（删除后即纯开源版）。
- 本包未包含任何密钥；`config.json` 以 0600 明文存储，注意内网机账号隔离。
