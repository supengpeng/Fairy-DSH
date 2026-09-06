# dsh-0.1.3-alpha.1 对齐重构记录（验证证据）

范围：Fairy-DSH 全套件按官方 DSH `dsh-0.1.3-alpha.1` 版本规范重构；批准态
按要求**留待隔离验收**，未伪造 SHA-256 与浏览器证据。

## 变更清单（13 个文件）

| 文件 | 变更 |
| --- | --- |
| `fairy-system/capability-matrix.json` | matrixId/dshVersion → `dsh-0.1.3-alpha.1`；`officialRuntimeSha256` → `null` + approval/note 字段；`dom.reasoning` 改为合并触发器 `选择模型`/`Select model` + popup 后缀；官方依赖族版本 → `0.1.3-alpha.1` |
| `fairy-visual/dsh-fairy-visual/src/client/dom-adapter.js` | 注释改为 0.1.3-alpha.1 官方字典核验；reasoning ARIA 联合从 `模型 `/`Model ` 改为 `选择模型`/`Select model`（0.1.3-alpha.1 合并的模型/推理弹窗触发器）；brand slot 注释去 rc.2 |
| `fairy-visual/dsh-fairy-visual/lib/client.js`、`lib/index.iife.js` | 同步内嵌 reasoning 字典（产物与 src 一致） |
| `fairy-startup/dsh-fairy-startup/lib/client.js` | 空工作区语义注释 rc.2+ → 0.1.3-alpha.1 |
| `fairy-system/preflight-build.js` | APPROVED.dshVersion → 0.1.3-alpha.1；runtimeSha256 → null + `runtimeApproval`；verifyCore 对待验收 SHA fail-closed 并给验收指引 |
| `fairy-system/verify.js` | `EXPECTED_RUNTIME_SHA256` → null（待验收）；官方包版本断言 → 0.1.3-alpha.1；verifyCleanRuntime fail-closed |
| `fairy-system/upgrade-preflight.js` | `VISUAL_SETTINGS_VERSION` → 0.1.3-alpha.1（含注释） |
| `fairy-system/test/contract.test.js` | 断言随 verify.js 更新（null 待验收态 + 0.1.3-alpha.1 版本断言） |
| `fairy-system/test/upgrade.test.js` | expectedVersion → 0.1.3-alpha.1；SHA 占位 `PENDING-ACCEPTANCE-SHA256`（验收后替换）；report 正则更新 |
| `fairy-visual/dsh-fairy-visual/test/model-reasoning.test.js` | 用例名 rc.2 → dsh-0.1.3-alpha.1 |
| `fairy-system/README.md`、`UPGRADE_COMPATIBILITY.md` | 目标边界/审计轨迹/验收流程/对齐记录文档化 |

## 规范依据（对照官方 0.1.3-alpha.1 源码）

- DOM/插槽词汇保留：`data-slot`、`data-phase`、`data-composer-seat/card`、
  `data-conversation-scroll`、`data-input-scroll`、`data-chat-flow`。
- 会话树移入 `ui-workspace`，仍为 `role="tree"` + `aria-label` 会话/Sessions。
- 模型选择 = `ui-model-selection` 单个合并触发器：aria `选择模型，当前
  {model}` / `Select model, current {model}`（`aria-haspopup="menu"`），旧的
  `模型 ` / `Model ` 前缀已退休 → adapter `reasoning` 随之更新。
- `ChatNodeStore`/`MutableChatNodeStore`、`sessions`/`workspaces` 服务词汇
  （`baselinesReady`、`recentWorkspaceId`、`startSession()`、`list.subscribe`）
  保留；`ctx.settingsScope`、`@deepseek-ai/dsh-settings` 族版本一致。
- 官方运行时安装树布局（含 `dsh-client-runtime` 入口是否保留）与浏览器证据
  属待验收项，已在 matrix/UPGRADE_COMPATIBILITY 明确标注。

## 测试证据（沙箱内可运行部分）

`node --test-isolation=none --test <fairy-visual|balance-meter|fairy-startup|
fairy-voice|browser-dock 全部用例 + fairy-system test 中非环境耦合用例>`

- **226 tests / 221 pass / 5 fail**
- 5 个失败均为沙箱/平台环境问题且与被改文件无关（基线同况）：
  1. `browser-dock startup` spawn EPERM（沙箱禁子进程管道）；
  2. `browser-dock state-watch` SSE 字节计数平台差异（438≠384）；
  3. `accepted-baseline` ×2 依赖 POSIX `/usr/bin/diff`（Windows 缺失）；
  4. `log-triage.test` CJS 脚本在根 `type: module` 下被当 ESM（候选树既有怪癖，
     与本次改动无关）。
- `fairy-system/test/contract.test.js` 9/9 通过（含更新后的
  `EXPECTED_RUNTIME_SHA256 = null` 与 0.1.3-alpha.1 断言）。
- `fairy-visual` 全套通过：contract/settings-contract/aria-i18n/model-reasoning
  /capability/semantic-markers 等均绿，证明 dom-adapter 联合改动无回归。
- `node --check` 语法门禁：verify/preflight-build/upgrade-preflight/dom-adapter/
  lib bundles/startup client 全部 0 退出；matrix JSON 可解析；adapter
  `OFFICIAL_SELECTORS.reasoning/model` 与 matrix `dom.reasoning/model` 逐字一致。

## 待实机确认的 DOM 锚点（2026-09-06 复核新增）

静态（源码）核验不足以证明这些锚点在真实 DOM 中存在/可解析，须在
0.1.3-alpha.1 实机浏览器中逐条确认；确认前不得宣称"能运行"：

1. `[data-slot="conversation.session.header.actions"]` /
   `[data-slot="conversation.session.header.utilities"]`：0.1.3-alpha.1 中
   这两个座位为 `list` 型，`ConversationSessionHeader` 把条目直接渲染进
   CSS-class 容器（`css.headerActions`/`css.headerUtilities`），未见
   `data-slot` 包裹属性 —— Fairy composer-dock 定位与 agent-preset 标签
   锚点依赖此选择器，缺失时相关功能会静默降级。
2. `[data-slot="sidebar.footer.action"]`（list 型）与
   `[data-slot="sidebar.settings"]`：sidebar 快照中曾出现该属性，但
   `SidebarRoot` 源码同样是 class 容器 + 裸渲染条目，需实机确认属性来源
   （条目自身根节点或渲染器锚点）。
3. `[data-slot="conversation.composer.dock"]`（list 型，ui-chat stats 注入）：
   同上，list 座位疑似无 `data-slot` 包裹。
4. `[data-slot="conversation.input.attachments"]`（single 型）与
   `[data-role="dialog"]` 系列：渲染器对 single 座位输出锚点，需实机抽查。
5. 旧 `reasoning` 触发器（`模型 ` 前缀）是否已从 composer 完全移除、新
   `选择模型，当前 …` 触发器在真实 composer 中是否存在。

结论：capability-matrix/dom-adapter 中上述行目前仍是 rc.2 时代的静态声明，
实机 DOM 审计结果将决定保留、降级或删除；如实机确认缺失，相关视觉能力按
"degraded"处理，不阻塞其余功能。

## 实机验证状态（2026-09-06 最终）

- 官方 `@deepseek-ai/dsh@0.1.3-alpha.1` 未发布到 npm（最新 `0.1.2-rc.1`）；
  沙箱内以官方源码（dsh-0.1.3-alpha.1 checkout）直启隔离实例成功：
  `dsh web: http://127.0.0.1:39123`（DSH_HOME 隔离 profile，bundles
  `@deepseek-ai/dsh-base` + `@deepseek-ai/dsh-web-app`），证明该版本源码可启动。
- 用户决策：**停止沙箱内浏览器 DOM 审计**，仅保留验收清单。因此上文"待实机
  确认的 DOM 锚点"没有浏览器结论——在真实机器完成清单前，不得宣称"能在
  dsh-0.1.3-alpha.1 上运行"。
- 残余环境（`.dsh-test-home`、无头 Edge、临时令牌文件）已清理，未入库。

## 待办（不属本次伪造范围）

1. 隔离 profile + 隔离 runtime 验收 0.1.3-alpha.1 候选，取得官方 SHA-256；
2. 将 matrix `officialRuntimeSha256`、preflight `APPROVED.runtimeSha256`、
   verify `EXPECTED_RUNTIME_SHA256`、upgrade.test 占位替换为验收值；
3. 按 `BROWSER-EVIDENCE-MATRIX.md` 补齐 11 项浏览器证据；
4. 重新审查第三方 `dsh-reasoning-effort`/`dsh-message-edit` 锁与补丁对
   0.1.3-alpha.1 的兼容性（本仓库锁定未动）。
