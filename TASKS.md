# Echo Loop 任务清单

> 最后更新：2026-08-18（F4 第一刀完成；M6 收官，M7 主体已随第一刀落地）
> 当前焦点：F4 真机冒烟验证 → F4b 第二刀（可选：PostHog 埋点摘除）

## 二开任务（总纲见 [docs/fork-plan.md](./docs/fork-plan.md)）

> 按里程碑推进；未启动的里程碑只登记方向，细节到启动时再展开，不预列。

### M6 二开基线与自建发布（✅ 2026-08-18 收官，详录见归档）

- [x] F1 本地基线 / F2 自建发布链路 / F3 数据自持备份 —— 全部完成（2026-08-18）。
  完成记录与踩坑详见 [docs/tasks-archive/tasks-2026-08-18-m6-baseline.md](./docs/tasks-archive/tasks-2026-08-18-m6-baseline.md)。

### M7 摘除商业层

- [x] F4 第一刀：摘订阅/配额层——paywall、RevenueCat、Paddle、entitlements、散布在各 AI 功能的 402 配额门禁，系统性清理而非硬关开关；跑全量测试确认回归。
  **完成时间**: 2026-08-18
  **摘除规模**: 132 文件 / -19612 +1595 行。整删 `lib/features/subscription/`（36 文件）+ user_region（连带，证据源断且零消费）+ revenuecat/paddle 配置 + 权益信号拦截器 + premium 主题常量 + 订阅事件名；各 AI 功能门禁直通（401 登录链路保留）；iOS 订阅通道/BILLING 权限/两个支付 SDK 依赖摘除；l10n 删 113 个零消费 key。全程留痕见 [docs/fork-removal-log.md](./docs/fork-removal-log.md)。
  **验证**: analyze 全仓 0 error 0 warning；全量测试 +4593/~13/-44，44 失败经基线对照全部为 Windows 开发机预存环境问题（39 个与基线逐数吻合，5 个零关联同特征），CI（Ubuntu）不受影响。
  **待办**: 真机冒烟（装 dev 包过一遍 AI 功能确认无门禁残留）。
- [ ] F4b 第二刀（可选）：摘 PostHog 埋点、渠道分发逻辑。（中国区判定已随 F4 连带摘除）

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

- [2026-08-18 M6 二开基线与自建发布](./docs/tasks-archive/tasks-2026-08-18-m6-baseline.md)
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
