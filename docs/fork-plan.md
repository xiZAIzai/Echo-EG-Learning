# Echo Loop 二开方案（家庭自用版决策记录）

> 记录时间：2026-08-15
> 用途：本仓库 fork 后给家庭成员（准初中生，英语中等水平，目标全面培养）自用的二次开发总纲。
> 本文沉淀 2026-08-14/15 项目全面评估（功能全景 / 架构模块化 / 后端依赖 / 平台支持四路分析）与后续讨论的结论，
> 供任何新会话直接续上下文，不依赖聊天历史。

## 1. 定位与约束

- **用户**：单个孩子自用，不分发（不上架商店、不公开 APK 下载）→ AGPL-3.0 无开源义务。
- **平台**：Android 优先。真机侧载 + GitHub Actions 自建 APK（原 iOS/macOS 能力保留但不管）。
- **上游关系**：fork 自 `echo-loop/Echo-Loop`（上游活跃维护）。本 fork 因摘除商业层会快速分叉，
  不追求持续 rebase 跟随；可按需 cherry-pick 上游修复，注意 CLAUDE.md §7.29 的 l10n/codegen 冲突教训
  （长期分支攒 rebase + codegen 全量文件冲突 = 静默覆盖，必须逐 key 核对）。

## 2. 总体路线：做减法，不重写

**不从零搭建精简框架**，理由：

1. 项目价值在 CLAUDE.md 29 条踩坑记录背后的平台工程知识（锁屏媒体会话隔离、iOS 语音 session、
   TTS 时序、自建三层文本选区子系统、Android SAF 绕行等），重写 = 全部重新踩坑。
2. 学习流程引擎与音频引擎/进度库/收藏体系深度耦合，「核心逻辑」没有干净剥离接缝。
3. 416 个测试文件（约 4900 用例）是二开回归安全网，重写从零开始。

**保留核心**：音频/媒体引擎、学习流程（盲听/精听/跟读/复述 + 间隔复习）、词典 + 选区子系统、
收藏体系、FSRS 记忆调度、离线 ASR（sherpa-onnx）/TTS（Kokoro/Piper + 平台）、Drift 数据库。

**分期摘除**：

- 第一刀（必做）：订阅/支付/配额层 —— paywall、RevenueCat、Paddle、entitlements、
  402 配额门禁（散布在各 AI 功能，需系统性清理而非硬关开关）。
- 第二刀（可选）：PostHog 埋点、中国区判定、渠道分发逻辑。

## 3. AI 方案：端内直连，不做云后端

原后端（`fluency-frontend`，不在本仓库）只做四件事：鉴权、配额裁决、prompt 模板、转发 LLM 并以
NDJSON 流式回传。前两者摘除，后三者搬进 App——**不需要任何服务器（含 NAS/家用服务器）**。

- **形态**：设置页新增「AI 服务」配置（Base URL + API Key + 模型名），存 `flutter_secure_storage`；
  各 API client（`lib/services/sentence_ai_api_client.dart`、`chat_api_client.dart` 等）从「发自家后端」
  改为「直连 OpenAI 兼容端点 + App 内置 prompt 模板」。
- **服务商**：国内 OpenAI 兼容接口（DeepSeek / Kimi / 智谱 GLM / 通义）。
  OpenAI/Anthropic 官方端点大陆手机直连不通；「自填 key」设计保留换厂商自由。
- **prompt 规格**：客户端 Dart 返回模型（`lib/models/sentence_ai_result.dart` 等）就是协议规格书，反推 prompt。
- **逐功能难度**：翻译 / AI 助教聊天（低，纯文本 SSE）；句子解析 / 词汇解析 / 意群 / AI 词典
  （中低，结构化 JSON）；复述评估（中，复用本地 ASR 转录文本 + 原文发 LLM，不上传音频）；
  整段音频转录（中，端内 sherpa-onnx 慢但可行，或接国内 ASR API——唯一体验打折点）。
- **删除项**：remote config / entitlements / 配额 —— 客户端本有本地默认兜底。
- **安全**：key 存手机，家庭自用可接受；申请可设消费上限的 key，后台偶尔核对用量。

## 4. 数据自持

- **模型与词典**（托管在 `cdn.echo-loop.top`，一次性下载后永久离线可用）：
  趁 CDN 存活**尽快全量下载备份**（ASR / VAD / Kokoro / Piper / 词典数据）。
  模型本体均开源（sherpa-onnx 系），CDN 失效可从开源渠道重打包，改三个 manager 的
  `_cdnBase` 常量指向自有存储即可（`asr_model_manager.dart` / `kokoro_model_manager.dart` / `piper_model_manager.dart`）。
- **学习材料自持链路**（不经原作者）：本地文件导入（Android 自研 SAF 通道）、播客 RSS 订阅
  （直连 feed + iTunes Search）。
- **发现页官方合集**：原作者运营内容，拿不到；摘除或留空。
- **开发机无关性**：模型在手机端推理，开发/编译不吃 GPU；换模型 = 改模型清单与 URL，与开发机性能无关。

## 5. 安装与发布链路

- **包名冲突**（`app.echoloop` 与 Google Play 版同包名、不同签名）：
  采用「接管」策略 —— App 内「备份与恢复」导出 `.elbak` → 卸载 Play 版 → 装自建版 → 恢复备份；
  此后一直用自建 keystore 签名升级。不改包名（连带通知渠道等引用多，不值得）。
  dev flavor（`app.echoloop.dev`，debug 签名）可与 Play 版共存，用于快速验证。
- **开发环境**：Flutter 3.41.5（CI 锁定版本）+ JDK 17 + Android SDK；开发机无需显卡；
  VS Code + Flutter 扩展 + 真机 hot reload（录音/ASR 在模拟器上残缺，日常插真机）。
  开发与 Claude Code 会话在 **Windows 侧原生**进行（2026-08-15 探测确认：项目在 NTFS D 盘，
  WSL 跨 `/mnt/d` 构建有 IO 性能陷阱且 adb 连真机需 usbipd 转发；Windows 侧两边都原生直连）。
- **本地构建**：prod flavor release 强制读 `android/key.properties`（无则失败）；
  无 keystore 前用 `flutter build apk --release --flavor=dev` 验证。
- **release.yml 精简**（原 516 行面向 R2 + Google Play + App Store 全链路，直接打 tag 必挂）：
  删 iOS 腿、R2 上传、AAB 构建（含 REVENUECAT 硬校验）、Google Play 上传；
  保留 tag 版本解析（versionCode = commit 数防回退校验）+ APK 构建 + GitHub Release 附件，
  `draft: true` 改为直接发布。
- **一次性准备**：`keytool` 自建 keystore；4 个 secrets（`ANDROID_KEYSTORE_BASE64` /
  `ANDROID_KEYSTORE_PASSWORD` / `ANDROID_KEY_PASSWORD` / `ANDROID_KEY_ALIAS`）。
- **tag 规则**：`vX.Y.Z` 必须与 `pubspec.yaml` version 一致（当前 1.0.29，首个基线 tag 直接 `v1.0.29`，无需改代码）。
- **dart-define vars**（`API_BASE_URL` 等）可先不配：App 以匿名/离线模式跑。
- **ci.yml**：全量约 4900 条测试，保留当回归安全网；嫌 Actions 时长再关。

## 6. 功能路线（按 features 模块插入，仿 chatbot 可插拔先例）

新增模块固定动作：`lib/features/xxx/`（models/providers/screens/widgets/services 分层）→
`app_router.dart` 声明嵌套子路由（遵守 CLAUDE.md §7.17 防返回栈塌陷）→ l10n 中英双语 →
需要持久化则 Drift 加表（迁移链已至 v48，加表成本低）。

规划顺序：

1. **写作**：句子仿写 → 段落 → 作文；批改复用 chatbot 的 NDJSON 流式协议与双载体组件。
2. **听写/拼写**：复用本地 TTS + 离线 ASR。
3. **考试题型**：新 Drift 表 + 选择/填空练习页（现数据模型是句子中心，新题型挂句子与词汇库）。
4. **词汇**：FSRS 基础设施已落地（`lib/features/memory_scheduler/` + `memory_schedules` /
   `memory_review_events` 表），可扩展初中考试词表。

**战略提醒**：本 App 重心是音频驱动听说；写作/考试是「挂在句子与词汇库上的附加练习」，
不做「以考试为中心」的重心迁移（那等于换心脏，回到重写问题）。

## 7. 第一步任务清单

1. 本地基线：dev flavor APK 真机跑通（不改任何代码，确立已知good基线）。
2. 精简 release.yml + 自建 keystore + 首个 tag `v1.0.29` → GitHub Release 出 APK。
3. 模型/词典全量下载备份（数据自持）。
4. 第一刀：摘订阅/配额层（跑全量测试确认回归）。
5. AI 端内直连改造（从翻译/聊天起步，再结构化功能）。
