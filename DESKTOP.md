# OpenMausBot 桌面版 · linux arm64 (UOS 20)

这是从官方 v0.1.170 源码移植打包的 **Electron 桌面应用**，可在 UOS 20 (aarch64) 上双击安装运行。

## 与 server 版的区别

| | 桌面版（本包） | server 版（另一个 Release） |
|---|---|---|
| 形态 | 独立桌面窗口，双击打开 | 浏览器访问 web UI |
| 安装 | `sudo dpkg -i` 一次装好 | 解压 + install.sh + 启动服务 |
| 依赖 | 系统 GTK3/NSS/AppArmor | 需自备 Node 24 + 离线 store |
| 适合 | 日常直接使用 | 无桌面 / 服务器部署 |

## 已知限制（重要）

- **"bot 控制本机屏幕/鼠标键盘"功能不可用**：上游 CUA 运行时只有 x86_64 二进制，arm64 无官方版本，打包时已移除。代码为 fail-closed 设计，缺失时功能优雅降级、App 不崩溃。
- 聊天、bots 对话、工具调用、云端电脑（Boat/Local VM）、web 搜索等**全部正常**。

## 安装

```sh
# 下载 OpenMausBot-0.1.170-arm64.deb 后
sudo dpkg -i OpenMausBot-0.1.170-arm64.deb
# 若提示缺依赖
sudo apt --fix-broken install
```

从应用菜单启动 OpenMausBot。

## 配置内网模型

首次启动后，编辑 `~/.openmausbot/config.json`，加入 OpenAI 兼容端点：

```json
{
  "instances": {
    "intranet-llm": {
      "driver": "openai-compat",
      "displayName": "内网模型",
      "environment": { "OMB_KEY": "key，无key填 dummy" },
      "config": {
        "url": "http://内网模型地址/v1",
        "apiKeyEnv": "OMB_KEY",
        "model": "模型ID"
      }
    }
  }
}
```

模型不支持工具调用时，在 `config` 中加 `"tools": false`。改完重启 App。

## 移植说明（供后续维护）

基于官方源码做了 4 处改动以适配 arm64：
1. `electron-builder.yml`：linux target 改 `arm64`，extraResources 去掉 `cua-linux-x64`，其余资源路径 x64→arm64，移除 AppImage toolset。
2. `scripts/after-pack.mjs`：cloudflared 架构白名单加 `linux-arm64`；CUA 校验改为目录不存在则跳过。
3. `build/linux-after-install.sh`：CUA 权限修复改为目录存在才执行。
4. 打包时用 `ELECTRON_MIRROR=https://npmmirror.com/mirrors/electron/` 规避 GitHub 下载超时。

原生资源（cloudflared/browser/duckdb）均为 linux-arm64 官方版本。
