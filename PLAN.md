# Echo Loop 项目规划

> 最后更新：2026-08-18（F1 dev flavor 真机基线完成）
> 当前焦点：M6 二开基线——F2 自建发布链路（release.yml 精简 + keystore + tag `v1.0.29`）

## 产品目标

本仓库已 fork 自 `echo-loop/Echo-Loop`，转为**家庭自用版**：单个孩子（准初中生，英语中等水平，
目标全面培养）自用，不分发、不上架。二开总纲与决策记录见 [docs/fork-plan.md](./docs/fork-plan.md)，
核心策略是**做减法，不重写**：

- 保留音频驱动听说的核心资产：音频/媒体引擎、学习流程（盲听/精听/跟读/复述 + 间隔复习）、
  词典 + 选区子系统、收藏体系、FSRS、离线 ASR/TTS、Drift。
- 摘除商业层（订阅/支付/配额；可选第二刀摘埋点/渠道），AI 改端内直连（OpenAI 兼容端点
  自填 key），不做任何云后端。
- 功能扩展挂在句子与词汇库上做附加练习（写作/听写/题型/词汇），不做以考试为中心的重心迁移。

## 当前状态

已稳定的能力（继承自上游）：

- 音频导入、字幕管理、字幕编辑、自由播放器；本地文件导入（Android SAF 通道）与播客 RSS 订阅。
- 首次学习主流程：全文盲听、逐句精听、难句跟读、段落复述。
- 收藏体系：句子、单词、意群、收藏复习。
- 词典体系：本地词典、AI 词典、网页词典、多源切换、非 modal 面板。
- AI 能力：翻译、句子解析、单词深度解析、转录、AI 助教聊天（当前经自家后端，M8 改端内直连）。
- PDF 导出：学习材料导出为可打印 PDF。
- 订阅体系（上游遗留，M7 整体摘除）：平台/渠道识别、native RevenueCat、direct Paddle
  后端结账、AI 配额后端裁决。

当前主要风险：

- Android 离线 ASR 在部分机型结束录音后触发 native 崩溃，仍未定位 root cause（上游遗留 P0）。
- 模型/词典托管在 `cdn.echo-loop.top`，原作者 CDN 失效即不可再下载，需尽快全量备份（F3）。
- 长期分叉后与上游差异只会变大：cherry-pick 上游修复时注意 CLAUDE.md §7.29 的
  l10n/codegen 冲突教训（codegen 全量文件冲突必须逐 key 核对）。

## 当前里程碑

### ✅ Milestone 1：基础播放器

已完成。覆盖音频导入、全文/单句/收藏三种播放模式、字幕同步、收藏与基础播放控制。

### 🚧 Milestone 2：学习流程引擎

主体已完成，剩余收尾集中在录音识别稳定性：

- 已完成：首次学习流程、阶段状态流转、断点续学、难度驱动的训练编排。
- 已完成：难句补练、收藏复习、盲听与复述共享骨架。
- 未完成：Android 离线 ASR 闪退根因定位与修复；段落复述继续复用统一录音识别模块。

### ✅ Milestone 3：收藏与标注体系

已完成。覆盖 Favorites、句子/单词/意群收藏、收藏复习、词典联动与标注内容展示。

### 🟡 Milestone 4：体验优化与生产就绪（fork 截止）

上游持续推进中的杂项里程碑，二开不再单独推进，相关优化随二开任务顺带做。其中通用
chatbot 组件（多轮对话、NDJSON 流式、sheet + 全屏双载体，规格见
[docs/chatbot-implementation-plan.md](./docs/chatbot-implementation-plan.md)）是 M8 AI 直连
与 M9 写作批改的复用基础。

### ⏸ Milestone 5：支付订阅（Echo Loop Premium）

上游主体已完成（RevenueCat / Paddle / 配额裁决 / 权益单一来源 P0，详见
[docs/subscription-single-source-plan.md](./docs/subscription-single-source-plan.md)）。
二开方向是**整体摘除**（M7 执行），上游遗留的生产验证等待事项随摘除一并终结，不再投入。

### 🚧 Milestone 6：二开基线与自建发布

- ✅ dev flavor APK 真机跑通（2026-08-18，F1）：环境全 D 盘搭建（Flutter 3.41.5 /
  JDK 17 / Android SDK），`app-dev-debug.apk` 装入 Redmi K90，四 Tab 导航无崩溃，
  good 基线确立。
- release.yml 精简（删 iOS / R2 / AAB / Google Play 腿，保留 tag 版本解析 + APK 构建 +
  GitHub Release）；自建 keystore + 4 个 secrets；包名接管策略（`.elbak` 备份迁移，
  不改包名）；首个 tag `v1.0.29`。
- 数据自持：趁 CDN 存活全量下载备份模型与词典（ASR / VAD / Kokoro / Piper / 词典数据）。

### ⬜ Milestone 7：摘除商业层

- 第一刀（必做）：摘订阅/配额层——paywall、RevenueCat、Paddle、entitlements、散布在各
  AI 功能的 402 配额门禁，系统性清理而非硬关开关；跑全量测试确认回归。
- 第二刀（可选）：PostHog 埋点、中国区判定、渠道分发逻辑。

### ⬜ Milestone 8：AI 端内直连

- 设置页新增「AI 服务」配置（Base URL + API Key + 模型名，存 `flutter_secure_storage`）；
  各 API client 从「发自家后端」改为「直连 OpenAI 兼容端点 + App 内置 prompt 模板」。
- 从翻译 / AI 助教聊天起步（纯文本流式），再做结构化功能（句子解析 / 词汇解析 / 意群 /
  AI 词典）；复述评估复用本地 ASR 转录文本 + 原文发 LLM，不上传音频。
- 服务商面向国内 OpenAI 兼容接口（DeepSeek / Kimi / 智谱 GLM / 通义），自填 key 保留换厂商自由。

### ⬜ Milestone 9：学习功能扩展

按序推进，新增模块固定动作：`lib/features/xxx/` 分层 → 嵌套子路由（CLAUDE.md §7.17）→
l10n 中英双语 → 需要持久化则 Drift 加表：

1. 写作：句子仿写 → 段落 → 作文；批改复用 chatbot 的 NDJSON 流式协议与双载体组件。
2. 听写/拼写：复用本地 TTS + 离线 ASR。
3. 考试题型：新 Drift 表 + 选择/填空练习页，挂在句子与词汇库上。
4. 词汇：FSRS 基础设施已落地（`lib/features/memory_scheduler/`），扩展初中考试词表。

## 近阶段工作重点

1. ~~F1 dev flavor APK 真机跑通~~ ✅ 2026-08-18。
2. F2 自建发布链路（release.yml 精简 + keystore + tag `v1.0.29`）。
3. F3 模型/词典全量下载备份。
4. F4 摘除订阅/配额层（第一刀）。
5. F5 AI 端内直连改造（翻译/聊天起步）。

## 架构约束（精简版）

- 单向数据流：UI 触发动作，provider / controller 改状态，UI 被动渲染。
- 页面负责组装，组件负责展示，复杂流程下沉到可测试的纯 Dart 编排层。
- 副作用通过 service / repository 注入，不把网络、文件、平台调用散落到 UI。
- 异步流程必须带 session / token / generation guard，防止旧回调污染新状态。
- 新增能力优先补状态流转测试与关键回归测试。

## 关键 ADR 索引

- 媒体引擎与前台引擎分离：避免锁屏媒体会话与前台试听互相污染。
- 统一 TTS 架构：合成 → 文件 → 缓存 → 播放，支持平台 TTS 与 Kokoro 本地 TTS。
- 离线转录与本地模型：复用统一音频处理与模型下载能力。
- 平台 + 渠道统一识别：`platform + distribution` 决定支付实现和后端配额策略（随 M7 摘除）。
- 通用记忆调度基础设施：以独立调度快照与只追加复习事件建模；上层依赖应用自有接口，
  FSRS 仅限 adapter 内部，按逐项固定 Profile 保障可迁移与可审计性（见
  [memory-scheduler-infrastructure-plan.md](./docs/memory-scheduler-infrastructure-plan.md)）。
- 二开做减法不重写：项目价值在 29 条踩坑记录的平台工程知识与约 4900 条测试回归网；
  商业层摘除、AI 端内直连不做云后端、功能扩展不做考试重心迁移（见
  [fork-plan.md](./docs/fork-plan.md)）。

详细历史与旧版长文档已归档：

- [2026-07-12 全量规划快照](./docs/plan-archive/plan-2026-07-12-full.md)

日常执行请结合：

- [TASKS.md](./TASKS.md)
- [AGENTS.md](./AGENTS.md)
