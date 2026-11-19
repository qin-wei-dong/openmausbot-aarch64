# OpenMausBot · aarch64 离线二次开发源码

本仓库只做一件事：提供一份**可在内网 UOS aarch64 电脑上离线构建、二次开发的 OpenMausBot 源码**。

## 获取源码

唯一交付物在 Releases：

**[v0.1.170-arm64-dev-source → openmausbot-dev-source-arm64.tar.gz](https://github.com/qin-wei-dong/openmausbot-aarch64/releases/tag/v0.1.170-arm64-dev-source)**（约 1.1 GB）

本仓库是**公开仓库**，内网无需 GitHub 账号或令牌，直接下载：

```sh
curl -fL -o openmausbot-dev-source-arm64.tar.gz \
  https://github.com/qin-wei-dong/openmausbot-aarch64/releases/download/v0.1.170-arm64-dev-source/openmausbot-dev-source-arm64.tar.gz
```

一个包内含全部内容，**下载这一个即可，无需另下任何东西**：

- arm64 移植版完整源码：桌面端 UI（`src/`）+ Electron 壳（`electron/`）+ harness 与全部 agent 驱动（`server/`）
- pnpm 离线依赖缓存 `pnpm-store/`（duckdb/resvg/electron 等 arm64 原生模块已就位）
- Node 24 arm64 运行时、pnpm 10.33.0 离线包
- Electron 43.7.9 linux-arm64 二进制与 fpm 打包工具（`vendor/`）——重打 deb/AppImage 全程无需外网
- arm64 原生资源（内置浏览器 / cloudflared / duckdb）
- AppImage 打包工具、`install-offline.sh` / `run-desktop.sh` / `build-desktop.sh`
- 内网模型配置模板与详细说明（包内 `README.md`）

## 为什么是这份源码

OpenMausBot 官方只发 x64 的 Linux 安装包，aarch64 无官方包；且官方不发源码包里的离线依赖。
这份源码在官方 v0.1.170 基础上做了 arm64 适配（构建目标、原生资源路径、CUA 降级等），
并把内网构建所需的**全部依赖离线化**，解压即可改造、构建、运行。

桌面端与 harness 是源码内原生打通的（Electron 主进程内嵌 harness server），
你在 UI 里的指令直接驱动 harness，无需额外接线。

## 内网使用概要

```sh
tar xzf openmausbot-dev-source-arm64.tar.gz
cd <解压目录>
./install-offline.sh        # 全程离线装好 Node24 + pnpm + 依赖 + Electron 二进制
# 改 source/config.json 嵌入内网 OpenAI 兼容模型
./run-desktop.sh            # 开发模式启动桌面端
./build-desktop.sh          # 改完代码，全离线重打 deb / AppImage（无需 Docker、无需外网）
```

改界面动 `source/src/`，改 harness / 模型驱动动 `source/server/`。
完整步骤、离线依赖闭环、arm64 改动清单见包内 `README.md`。

## 说明

- 不含打包好的 `.deb` / `.AppImage`——按需求只提供可二次改造的源码。
- 内网模型适配（嵌模型、改协议等）需在内网完成，故提供源码而非成品。
- CUA「bot 控制本机屏幕/鼠标键盘」在 arm64 上不可用（上游仅 x86_64），功能优雅降级，不影响聊天与工具调用。
