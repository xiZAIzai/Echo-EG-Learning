# Echo Loop 任务清单

> 最后更新：2026-08-18（F1/F2 完成，焦点转 F3 数据自持）
> 当前焦点：M6 二开基线——F3 模型/词典全量下载备份（趁 CDN 存活）

## 二开任务（总纲见 [docs/fork-plan.md](./docs/fork-plan.md)）

> 按里程碑推进；未启动的里程碑只登记方向，细节到启动时再展开，不预列。

### M6 二开基线与自建发布（当前）

- [x] F1 本地基线：dev flavor APK（`app.echoloop.dev`，debug 签名，可与 Play 版共存）真机跑通，不改任何代码，确立已知 good 基线。
  **完成时间**: 2026-08-18
  **环境**（从零搭建，全 D 盘）：Flutter 3.41.5 / JDK 17 / Android SDK+NDK / pub 缓存 → `D:\apps\dev\`，用户级环境变量已持久化；Windows 开发者模式已开。三个构建坑与解法已记入会话记忆（pub 缓存必须与项目同盘、引擎镜像 POM 损坏走官方源、media_kit jar 走 Clash 7897 代理预下载到项目 build 目录）。
  **APK**：`build/app/outputs/flutter-apk/app-dev-debug.apk`（187M，arm64，versionName 1.0.29）。
  **真机验证**（Redmi K90，Android 13，装 MIUI 需额外开「USB 安装」）：adb 安装 ✓，启动 ✓（PID 存活无重启），资源库/学习计划/复习/我的 四 Tab 导航 ✓ 无崩溃；词典版本检查/官方合集刷新报连接错误属预期（匿名离线模式，dart-define 未配）。
  **未验证项**：音频导入/播放、录音 ASR（需真机导入素材 + 模型下载，留待日常使用确认；ASR native 崩溃为上游已知 P0）。
- [x] F2 自建发布链路：精简 release.yml（删 iOS 腿、R2 上传、AAB 构建、Google Play 上传，保留 tag 版本解析 + APK 构建 + GitHub Release）；`keytool` 自建 keystore + 4 个 secrets（`ANDROID_KEYSTORE_BASE64` / `ANDROID_KEYSTORE_PASSWORD` / `ANDROID_KEY_PASSWORD` / `ANDROID_KEY_ALIAS`）；首个 tag `v1.0.29` 出 APK。真机安装走包名接管：`.elbak` 备份 → 卸载 Play 版 → 装自建版 → 恢复备份。
  **完成时间**: 2026-08-18
  **release.yml**：516 行 → 231 行（单 job 去 matrix，draft 改直接发布，删草稿清理），commit `0e9f172b`。
  **keystore**：PKCS12 单密码（坑：PKCS12 下 store/key 不同密码会解不开私钥，gradle 报 `final block not properly padded`；单密码后 apksigner 秒验通过）。正本与密码档案在 `D:\apps\dev\keystores\`（仓库外），工作副本 `android/app/upload-keystore.jks` + `android/key.properties`（均被 gitignore）。
  **本地验证**：prod release 构建成功（109.9MB，arm64，versionCode=1377 与 CI 一致）。
  **CI 发布**：tag `v1.0.29` 推送后 workflow 未自动触发（**fork 仓库 push 事件工作流默认休眠，需一次手动激活**），用 `workflow_dispatch` 手动触发成功；run 32100597017 全绿，GitHub Release `v1.0.29` 已正式发布，附件 `Echo-Loop-1.0.29-arm64.apk`（111MB）。下个 tag 验证自动触发。
  **真机包名接管**（`.elbak` 备份 → 卸载 Play 版 → 装自建版）：留待日常使用切换时执行，不在本任务收尾。
- [ ] F3 数据自持：趁 CDN 存活全量下载备份模型与词典（ASR / VAD / Kokoro / Piper / 词典数据）。

### M7 摘除商业层

- [ ] F4 第一刀：摘订阅/配额层——paywall、RevenueCat、Paddle、entitlements、散布在各 AI 功能的 402 配额门禁，系统性清理而非硬关开关；跑全量测试确认回归。
- [ ] F4b 第二刀（可选）：摘 PostHog 埋点、中国区判定、渠道分发逻辑。

### M8 AI 端内直连

- [ ] F5 设置页新增「AI 服务」配置（Base URL + API Key + 模型名，存 `flutter_secure_storage`）；各 API client（`sentence_ai_api_client.dart`、`chat_api_client.dart` 等）从「发自家后端」改为「直连 OpenAI 兼容端点 + App 内置 prompt 模板」。从翻译 / AI 助教聊天起步，再做结构化功能（句子解析 / 词汇解析 / 意群 / AI 词典）；复述评估复用本地 ASR 转录文本 + 原文发 LLM，不上传音频。

### M9 学习功能扩展（未展开）

- 写作 → 听写/拼写 → 考试题型 → 词汇，顺序与边界见 fork-plan §6（不做以考试为中心的重心迁移）。

## 上游遗留未完成

> 从 fork 基线归档带入的未完成项；与二开冲突的已标记作废。

- [ ] Android 离线 ASR 结束录音闪退（上游 P0，Silero VAD native 推理；Android 优先策略下直接影响跟读/复述，需真机 `logcat` + `/data/tombstones` 定位）。
- [ ] 意群操作栏收藏⇄取消收藏切换时其余按钮闪烁（按钮宽度已按文案独立计算，闪烁根因待排查）。
- [ ] 段落复述页面复用统一录音识别模块。
- [ ] 查词归一化 unicode 化 + 收藏 key 迁移（`café` 被剥成 `caf`、CJK 不可查，属产品 + 数据决策）。
- [ ] P2 产品项：学习任务预计/实际耗时展示；学习/复习直达学习页跳过计划页；「今日完成任务」折叠区；句子复制（移动端长按 / 桌面右键）；自定义背景/背景音；任务完成音效与动画。
- 作废：启动埋点手动验证（PostHog）、埋点按中国大陆/全球环境拆分——随 F4b 整体摘除。
- 待评估：百度网盘导入任务 1（后端 OAuth 会话）/ 任务 5（跨平台验证与发布准备）——依赖自家后端，M7/M8 摘后端依赖后重新评估。

## 历史归档

- [2026-08-15 fork 基线全量快照](./docs/tasks-archive/tasks-2026-08-15-fork-baseline.md)
- [2026-07-28 全量任务快照](./docs/tasks-archive/tasks-2026-07-28-full.md)
- [2026-07-12 全量任务快照](./docs/tasks-archive/tasks-2026-07-12-full.md)
- [Milestone 2 - 学习流程引擎](./docs/tasks-archive/milestone-2-learning-engine.md)
- [Milestone 3 - 收藏与标注体系 + 体验优化](./docs/tasks-archive/milestone-3-completed.md)
- [Milestone 4 - 功能完善与体验打磨](./docs/tasks-archive/milestone-4-features-and-polish.md)
- [Milestone 5 - 登录认证 / Podcast / 离线 ASR / 字幕编辑器](./docs/tasks-archive/milestone-5-completed.md)

## 维护规则

- 新任务写到「二开任务」对应里程碑下；未启动的里程碑只登记方向，不预列细节。
- 完成记录写在任务条目下（含 **完成时间**），大段过程性记录写入归档文件，不把主文件写成长流水账。
- 里程碑状态变化时同步更新 `PLAN.md`。
