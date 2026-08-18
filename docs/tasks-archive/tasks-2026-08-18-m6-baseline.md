# M6 二开基线与自建发布 — 完成归档（2026-08-18）

> 从 TASKS.md 归档；F4 摘除留痕见 [fork-removal-log.md](../fork-removal-log.md)。

## F1 本地基线：dev flavor APK 真机跑通

**完成时间**: 2026-08-18

- **环境**（从零搭建，全 D 盘）：Flutter 3.41.5 / JDK 17 / Android SDK+NDK / pub 缓存 → `D:\apps\dev\`，用户级环境变量已持久化；Windows 开发者模式已开。构建坑：pub 缓存必须与项目同盘（Kotlin 增量编译 different roots）、引擎镜像 POM 损坏走官方源、media_kit jar 走 Clash 7897 代理预下载到项目 build 目录。
- **APK**：`build/app/outputs/flutter-apk/app-dev-debug.apk`（187M，arm64，versionName 1.0.29）。
- **真机验证**（Redmi K90，Android 13，MIUI 需开「USB 安装」）：adb 安装 ✓、启动 ✓、四 Tab 导航 ✓ 无崩溃；词典版本检查/官方合集刷新连接错误属预期（匿名离线模式）。
- **未验证项**：音频导入/播放、录音 ASR（留待日常使用确认；ASR native 崩溃为上游已知 P0）。

## F2 自建发布链路

**完成时间**: 2026-08-18

- **release.yml**：516 → 231 行（删 iOS/R2/AAB/Play 四腿，单 job 去 matrix，draft 改直发），commit `0e9f172b`。
- **keystore**：PKCS12 单密码（坑：store/key 不同密码在 PKCS12 下解不开私钥，gradle 报 `final block not properly padded`）。正本+密码档案在 `D:\apps\dev\keystores\`（仓库外），工作副本 `android/app/upload-keystore.jks` + `android/key.properties`（gitignore 排除）。
- **本地验证**：prod release 构建成功（109.9MB，arm64）。
- **CI**：tag `v1.0.29` 推送后 workflow 未自动触发（**fork 仓库 push 事件工作流默认休眠，需一次 workflow_dispatch 手动激活**）；手动触发 run 32100597017 全绿，GitHub Release `v1.0.29` 正式发布 `Echo-Loop-1.0.29-arm64.apk`（111MB，versionCode 1377）。下载产物验签与本地 keystore 指纹一致（`09:B1:7E:...`）。下个 tag 验证自动触发。
- **真机包名接管**（`.elbak` 备份迁移）：留待日常切换时执行。

## F3 数据自持：CDN 全量备份

**完成时间**: 2026-08-18

- **备份**: `D:\apps\backup\echo-loop-cdn\`（1.6GB / 23 文件：Whisper×3 档 + VAD、Kokoro×2、Piper×9、词典×2，全部 sha256 校验通过；含 `SHA256SUMS.txt`、README 恢复指引、可重跑 `download_all.sh`）。
- **范围决策**: 全量（用户选定）；ASR/TTS 将转云端 API（2026-08-18 方向决策），本备份为过渡期保险+存档，词典保留本地。
- **坑**: manifest hash 手抄错两位致 2 文件误删重下——hash 一律程序化从 manifest 提取。

## 环境备注（Windows 开发机）

- 全量 `flutter test` 在本机有 **44 个预存环境失败**（media_playback 31 = 临时目录文件锁 errno 32；转录/清理/TTS 缓存/音频导入 8 = 路径分隔符与时序；备份/网盘/媒体引擎 5 = 文件 IO 特征），已在 F4 收尾时以改动前基线对照逐数确认，CI（Ubuntu）不受影响。本机判断回归以「失败集合与基线一致」为准。
- MIUI adb 安装被「是否允许 Shell 安装应用」授权框拦截（`INSTALL_FAILED_USER_RESTRICTED`），且最后需机主密码确认——推 APK 到 Download 由用户点装最快。
