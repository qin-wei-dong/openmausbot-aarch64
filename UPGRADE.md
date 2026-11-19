# UPGRADE · 跟随上游升级本离线包

> 面向维护者：上游 [milind-soni/OpenMausBot](https://github.com/milind-soni/OpenMausBot) 发新版本时，
> 如何产出新版 `openmausbot-dev-source-arm64.tar.gz`。
>
> 核心认知：**升级 ≠ 重新移植**。移植面只有 5 处源码改动（清单见包内 `source/ARM64-DEV.md`），
> 真正随版本漂移的是离线资产。

## 0. 评估要不要跟

看新版 release notes 三件事：Electron / electron-builder / pnpm 动没动（决定资产重取量）；
`server/` 驱动架构动没动（内网模型适配代码要回归）；上游是否已自带 arm64（若是，移植补丁可删，只剩离线化）。

## 1. 取新源码，重放 5 处改动

推荐 git 基线法（一次 setup，以后都是 merge）：

```sh
git clone https://github.com/milind-soni/OpenMausBot && cd OpenMausBot
git checkout -b uos-arm64 v0.1.170          # 以当前发布版为基线
# 把现包 source/ 里的 5 处改动搬进来，commit
git merge v<新版本>                            # 冲突只会落在这 5 个文件
```

5 处改动：`electron-builder.yml`（arm64 targets / 去 CUA / 资源路径）、`scripts/after-pack.mjs`
（cloudflared 白名单 + CUA 跳过）、`build/linux-after-install.sh`（chrome 路径 find）、
`build/linux-openmausbot-browser.apparmor`（arm64 profile）、包级打包链（见下）。

## 2. 重取会漂移的离线资产

| 资产 | 何时要换 | 依据 |
|---|---|---|
| `pnpm-store/` | lockfile 变了 | 有网机重新 `pnpm install` 导出 store |
| `vendor/electron/` zip | Electron 版本变 | **以 `pnpm-lock.yaml` 解析值为准**（不是 package.json 的 `^` 范围）；SHA256 对照 `node_modules/electron/checksums.json` |
| `vendor/fpm/` | electron-builder 升级 | `node_modules` 内 `app-builder-lib/out/toolsets/linux.js` 的 `fpmChecksums` 表 |
| `appimage-tools/` | electron-builder 升级 | 同文件 `appimageChecksums` + `toolsets.appimage` 版本 |
| `source/dist-native/` | 各原生组件版本变 | 重跑 `scripts/prepare-*.mjs` 取 linux-arm64 资产 |

**坑位（都实测踩过）：**

- `vendor/electron-cache/` 的缓存目录名 = **sha256(去掉文件名的官方下载 URL)**，
  即 `sha256("https://github.com/electron/electron/releases/download/v<版本>")`。
  @electron/get 5.x 按此哈希寻址，按完整 URL 算会缓存 miss，断网机上 postinstall 直接报错
- `source/dist-native/duckdb/linux-arm64/node_modules`（约 80M）**必须存在**——
  afterPack 硬校验，缺了连有网构建都失败（v1 包就漏过它）
- zip 与缓存目录用软链复用同一份文件，不必双份存储
- `install-offline.sh` 里 electron `install.js` 兜底**不要删**：pnpm 10 会静默跳过 electron
  postinstall（不报错、不列入 ignored 清单），兜底是 dist 就位的保证

## 3. 断网验证（不可跳过）

任何下载点漏离线化，只有在无网环境才暴露。在 arm64 机或 Apple Silicon Docker 上：

```sh
docker build -t omb-offline - <<'EOF'
FROM debian:bookworm
RUN apt-get update -qq && apt-get install -y --no-install-recommends xz-utils binutils && rm -rf /var/lib/apt/lists/*
EOF
docker run -d --name omb-offline --platform linux/arm64 --network none -v <新包stage>:/pkg -w /pkg omb-offline sleep infinity
docker exec omb-offline sh -c 'cd /pkg && ./install-offline.sh && ./build-desktop.sh'
```

通过标准：两条命令 EXIT=0；build 日志含 `using custom electronDist directory`、
`resolved APPIMAGE_TOOLS_PATH`、`resolved CUSTOM_FPM_PATH` 且 **0 次 download**；
`dpkg-deb -c` 检查 deb 内 `resources/duckdb/` 文件数 > 0。
（`android-platform-tools` 缺失的 warning 属正常，官方构建同样不带。）

## 4. 发布

```sh
tar -czf openmausbot-dev-source-arm64.tar.gz -C <stage> .
gh release create v<新版本>-arm64-dev-source openmausbot-dev-source-arm64.tar.gz \
  --title "arm64 离线二次开发源码包" --notes "<变更要点 + 新 SHA256 + 断网验证结论>"
```

随后：更新仓库 README 的版本与体积；本地留存新 tarball 与 SHA256 记录。

## 红线

- **不要设置 `ELECTRON_MIRROR` 等镜像变量**——会改变下载 URL 的哈希，预置缓存全部失配
- 资产文件名 `openmausbot-dev-source-arm64.tar.gz` **永不改**（README 的 curl 命令依赖它）
- 上游协议 Apache-2.0：再分发需保留 LICENSE 与改动声明（包内已随 source/ 携带，merge 时留意保留）
