# Echo Loop 二开摘除留痕文档

> 建档时间：2026-08-18（F4 第一刀启动前）
> 用途：记录商业层（及后续二开决策）摘除的**过程留痕**——摘了什么、为什么摘、怎么验证的。
> 原则：每完成一刀，立即在「执行记录」追加条目；文档随摘除进度滚动更新。

## 1 背景

本仓库 fork 自 `echo-loop/Echo-Loop` 转家庭自用（见 [fork-plan.md](./fork-plan.md)）。
上游是商业 App：订阅制（RevenueCat / Paddle 双支付渠道）、后端配额裁决、paywall 门禁。
家庭自用版不需要任何商业化能力，F4 第一刀整体摘除订阅/配额层。

## 2 摘除对象盘点（2026-08-18 调查结论）

### 2.1 主体：`lib/features/subscription/`（36 个文件，整目录摘除）

| 类别 | 文件 | 说明 |
|---|---|---|
| 模型 | entitlement / entitlement_source / premium_feature / subscription_plan / ai_quota_rejection | 权益与套餐数据模型 |
| Provider | subscription_controller / subscription_plans / subscription_availability / subscription_identity / feature_access / ai_quota_limit / ai_trial_usage | 订阅状态与配额状态 |
| UI | paywall_screen / subscription_debug_screen / ai_quota_exceeded_dialog / feature_gate | paywall 与门禁组件 |
| 服务 | entitlement_repository / entitlement_cache / entitlement_reconciler / paddle_billing_repository / paddle_purchase_service / revenuecat_purchase_service / purchase_service / local_storekit_purchase_service / subscription_management_launcher / ai_quota_limit_store / ai_trial_usage_store / free_allowance_policy | 支付与权益同步 |
| 配置 | ai_trial_limits / plan_pricing / member_status / ai_quota_copy | 商业参数与文案 |

配置文件：`lib/config/revenuecat_config.dart`、`lib/config/paddle_config.dart` 一并摘除。

### 2.2 外部耦合点（23 个文件，需逐个改）

**P0 核心阻断（AI 功能直通改造）：**

| 文件 | 耦合 | 摘后处理 |
|---|---|---|
| `lib/main.dart` | RevenueCat 初始化（212-252）、订阅 provider 预热（443-447）、前台权益刷新（506-518） | 全删 |
| `lib/providers/sentence_ai_provider.dart` | featureAccess 门控 + 402 配额分支 + 试用计数（905-939 等） | 门禁直通，402 分支并入通用错误 |
| `lib/features/chatbot/providers/chat_session_controller.dart` | aiChat 门控（146-162） | 直通 |
| `lib/providers/retell_review_evaluation_provider.dart` | retellReview 门控 + 402 分支（116、178-189） | 直通 |
| `lib/providers/transcription_task_provider.dart` | 402 配额处理 | 并入通用错误 |
| `lib/providers/dictionary/lookup_controller.dart` | aiQuotaRejection | 并入通用错误 |

**P1 UI 入口清理：**

| 文件 | 耦合 |
|---|---|
| `lib/screens/settings_screen.dart` | 订阅 tile（138-249 内）+ 开发者订阅调试入口（895-904） |
| `lib/router/app_router.dart` | paywall 路由 |
| `lib/widgets/dictionary/dictionary_panel.dart` | AI 词典 FeatureGate |
| `lib/screens/retell_player_screen.dart` | 复述评估 FeatureGate/openPaywall |
| `lib/features/chatbot/widgets/chat_view.dart` / `chat_gate_banner.dart` / `message_bubble.dart` / `chat_message.dart` | 聊天门禁横幅与升级入口 |
| `lib/widgets/retell/retell_review_sheet.dart` / `manage_subtitles_sheet.dart` / `practice/annotation_content_view.dart` / `widgets/dictionary/ai_dict_result_view.dart` | 各处门禁/配额 UI |

**P2 交叉依赖：**

| 文件 | 耦合 | 处理 |
|---|---|---|
| `lib/providers/app_update_provider.dart` | 只借 revenuecat_purchase_service 取商店 storefront | 换常量或删除该用途 |
| `lib/features/remote_config/remote_config.dart` | showStoreWebCheckoutFallback / transcriptionLimits 等商业开关 | 框架保留，商业开关随用点摘除 |

**P3 原生层与外围：**

| 位置 | 内容 |
|---|---|
| `ios/Runner/AppDelegate.swift`（1199-1301） | `top.echo-loop/subscription_management` MethodChannel（StoreKit 管理订阅页） |
| `android/app/src/main/AndroidManifest.xml`（行4） | BILLING 权限 |
| `pubspec.yaml` | `purchases_flutter`（RevenueCat SDK）依赖 |
| `test/features/subscription/`（6 个测试文件） | 整目录删除 |
| l10n 三份 arb/codegen | 订阅/配额相关 key 清理 |

### 2.3 明确保留（不属商业层）

- `lib/services/ai_http2_retry_interceptor.dart` — 名字带 402 相关联想，实为 HTTP/2 连接重试，保留。
- `lib/features/remote_config/` 基础框架 — 网盘导入等非商业开关仍在用，保留。

## 3 执行记录

> 按时间倒序追加；每条含：日期 / 摘除内容 / 验证方式 / 结果。

### 2026-08-18 · F4 第一刀：摘除订阅/配额层

**摘除内容**（commit 待填）：

1. **整目录删除**：`lib/features/subscription/`（36 文件：paywall、RevenueCat/Paddle 购买服务、entitlements 同步对账、配额存储、试用计数、FeatureGate、配额弹窗）、`test/features/subscription/`（6 测试）、`lib/config/revenuecat_config.dart`、`lib/config/paddle_config.dart`。
2. **连带摘除**（依赖已断 + 属 F4b 范围提前）：
   - `lib/features/user_region/`（中国区判定；其 storefront 证据源是已删的 purchaseService，且 `isChinaUserProvider` 在 lib/ 内零消费方）
   - `lib/utils/app_store_country.dart`（唯一消费方是上述 storefront 推断）
3. **门禁直通改造**（P0）：
   - `sentence_ai_provider.dart`：删 6 个注入回调（guardFeature/onConsumeTrial/beforeApiRequest/onQuotaExceeded/onBackendQuotaRejected/onApiSucceeded）、`AiFeatureQuotaExceededException` 类、`respectLocalQuotaReset` 参数链（连带 sense_group_service）；402 分支并入通用错误，401 登录引导保留
   - `chat_session_controller.dart`：删 aiChat 本地闸门、`quotaBlocked` 状态、402 映射、试用计数；`ChatGate` 只剩 none/authRequired
   - `retell_review_evaluation_provider.dart`：删 aiRetellReview 闸门、quotaReason 字段、402 分支
   - `transcription_task_provider.dart`：删 `TranscriptionQuotaExceeded` 状态与 402 分支
   - `lookup_controller.dart`：删 `LookupQuotaExceeded` 状态与 402 分支
4. **UI 入口清理**（P1）：settings 订阅 tile 与订阅调试入口、paywall 路由、chatbot 升级横幅/气泡 inline 升级按钮（onUpgrade 链）、AI 词典配额卡、字幕管理配额弹窗、复述评估升级引导——全部删除；登录引导入口全部保留。
5. **交叉依赖**（P2）：`app_update_provider` 改为不查 storefront（Lookup 走默认区）；remote_config 删纯商业开关 `showStoreWebCheckoutFallback`（`aiChatAssistant` 功能开关与 `transcriptionLimits` 上限为功能配置，保留）。
6. **原生与依赖**（P3）：iOS AppDelegate 删 `subscription_management` MethodChannel；AndroidManifest 删 BILLING 权限；pubspec 删 `purchases_flutter`、`in_app_purchase`。
7. **l10n**：删 113 个零消费 key（aiQuota* / premium* / chatUpgrade），经程序化扫描确认（每个 key 全仓 grep 消费数为 0 才删，遵守 §7.29 不盲删），gen-l10n 重新生成。

**保留物**（有意）：
- 401 登录链路（auth/Supabase 层完整保留，不属本刀范围）
- `ai_http2_retry_interceptor.dart`（HTTP/2 重试，非商业）
- remote_config 框架与非商业开关

**验证**：
- `flutter analyze` 全仓 **0 error 0 warning**（含 test/）。
- 全量 `flutter test`：**+4593 通过 / ~13 跳过 / -44 失败**。44 个失败经基线对照确认为 **Windows 开发机预存环境问题、与本次摘除零相关**：
  - `media_playback_screen_test` 31 个：临时目录删除 errno 32（media_kit/ffmpeg 原生句柄滞后释放的文件锁）——改动前基线同文件同样 31 个失败，逐数吻合；
  - 转录/孤儿清理/TTS 缓存/音频导入共 8 个：Windows 路径分隔符（`\` vs `/`）与文件系统时序差异——基线同为 8 个，逐数吻合；
  - 备份 ZIP/百度网盘/媒体引擎共 5 个：文件 IO 同特征，且三个文件对已删符号零引用。
  - CI（Ubuntu）不受上述 Windows 特性影响。

## 4 恢复指引

若未来需要恢复商业化（极不可能）：本档 + git 历史（fork 基线 `6d8b57cb`）即完整恢复依据。
