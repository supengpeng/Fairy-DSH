# DSH Upgrade Compatibility Matrix

This document defines a read-only gate for an official DSH candidate. It does
not authorize an install, lockfile refresh, package change, or runtime patch.

## Current state

| State | Value |
| --- | --- |
| Target matrix | `dsh-0.1.3-alpha.1` (`capability-matrix.json`, `dshVersion` `0.1.3-alpha.1`) |
| Target runtime approval | **pending isolated candidate acceptance** — `officialRuntimeSha256` is `null` and must not be backfilled with the rc.2-era hash |
| Superseded baseline (audit trail) | `0.1.1-rc.2`, SHA-256 `13a5fe0ee8cddda2306d302eb0dbfdd601e96d14baeb512867b4b6d1d72f6679` |

Until a candidate is accepted, `verify.js` and `preflight-build.js` fail
closed by design; `fairy-system/test/upgrade.test.js` success paths only run
after the accepted SHA-256 replaces the `PENDING-ACCEPTANCE-SHA256`
placeholder there and in the matrix.

## Source-aligned surface (dsh-0.1.3-alpha.1)

Verified against the official `0.1.3-alpha.1` source (client packages and
their zh/en locale dictionaries):

- DOM selectors and slot vocabulary are retained: `data-slot` holes (`root`,
  `sidebar`, `conversation`, `shell.overlay`, `sidebar.settings`,
  `conversation.session.header.*`, …), `data-phase` hero/active,
  `data-composer-seat`, `data-composer-card`, `data-conversation-scroll`,
  `data-input-scroll`, `data-chat-flow`.
- The session tree lives in the official `ui-workspace` surface but keeps
  `role="tree"` + `aria-label` `会话`/`Sessions` and `treeitem` rows; sidebar
  `新建会话`/`New session`/`New Session` and `打开侧边栏`/`收起侧边栏`/
  `Open sidebar`/`Collapse sidebar` labels are unchanged.
- Model selection is a single merged composer popup trigger
  (`ui-model-selection`): `选择模型，当前 {model}` / `Select model, current
  {model}` with `aria-haspopup="menu"`. The DOM adapter's `reasoning`
  capability now targets that same trigger (`^选择模型` / `^Select model` +
  popup suffix) instead of the retired `模型 ` / `Model ` prefix; `model` and
  `reasoning` resolve to one node again.
- `@deepseek-ai/dsh-settings`, the `dsh-client-ui-*` conversation/layout/
  sidebar/model-selection/settings/slots packages, `dsh-client-connection`,
  `dsh-api-remotes`, `dsh-brand` and `dsh-invariants` are all at
  `0.1.3-alpha.1`; `@deepseek-ai/cordis` `4.0.1` and `@deepseek-ai/schemastery`
  `3.18.1` are unchanged.
- Official client services keep the reviewed vocabulary: `sessions`
  (`sessions.clear()`, `sessions.list`, binding), `workspaces`
  (`workspaces.list`, `baselinesReady`, `recentWorkspaceId`,
  `workspaces.startSession()`), `ChatNodeStore`/`MutableChatNodeStore`
  (`get(key)`, `values()`) with `user`/`assistant-step` node kinds, and
  `ctx.settingsScope.bind` on the client side.
- The installed-tree layout of the browser runtime entry (whether
  `@deepseek-ai/dsh-client-runtime/lib/client.js` remains the entry inside the
  published `@deepseek-ai/dsh` tree) is part of the candidate acceptance and
  has **not** been asserted yet.

## Reviewed Baseline (audit trail: `0.1.1-rc.2`)

| Surface | Declaration / resolved version | Upgrade contract |
| --- | --- | --- |
| Official browser runtime | `0.1.1-rc.2`, SHA-256 `13a5fe0ee8cddda2306d302eb0dbfdd601e96d14baeb512867b4b6d1d72f6679` | Browser ModuleLoader registration, `factory(require)`, client lifecycle and slots remain present. |
| Fairy Visual host settings | `@deepseek-ai/dsh-settings` exactly `0.1.1-rc.2` | The host alone imports `settingsNamespace` and registers its schema through `ctx.inject(['settings'])` / `settings.register`. |
| Fairy Visual client settings | Official runtime `0.1.1-rc.2` | The client uses `ctx.settingsScope.bind`; it must not import or bundle `@deepseek-ai/dsh-settings`. |
| `dsh-reasoning-effort` | `github:HanaAyane/dsh-reasoning-effort#main`, resolved lock version `0.6.2` | The current lock pin is commit `83bc8c548749d7156a03d11d875d8117e9b5d994` plus patch hash `9cbcceae243982ca0241cd41471317da9112c3e61e345b3b32f205d90aec18b5`. |
| `dsh-message-edit` | exact `0.2.3` | The current lock patch hash is `6365b2e53f9a2f366898ef2d78648c34823df11e9bfc2a47162e6626803763cb`. |

## Peer API Risks

`dsh-reasoning-effort` declares `^0.1.0-rc.6` peer ranges for the browser
runtime, connection, conversation, model-selection, settings, slots, remotes,
and Cordis. The dsh-0.1.3-alpha.1 family satisfies those ranges numerically,
but semver range acceptance is not evidence that its ModuleLoader bundle,
`conversation.input.model`, or `settings.general.item` slots remain
compatible; the lockfile commit and patch hash stay the effective pins and a
third-party re-review is part of the candidate acceptance.

`dsh-message-edit` declares no runtime peer dependencies. Its bundle was built
against rc.6 development dependencies and implicitly relies on the browser
ModuleLoader plus `conversation.view` and `conversation.session.header.actions`.
Treat those as peer API contracts even though its manifest does not state them.

## Upgrade Blockers

Do not upgrade until a candidate preserves, or has an explicitly reviewed
replacement for, all of the following:

- accepted runtime version and SHA-256 (dsh-0.1.3-alpha.1 candidate);
- ModuleLoader boot protocol and lifecycle/slot behavior;
- Visual settings import boundary, resolved version, `settings.register`, and
  client `settingsScope` bridge;
- Visual slots, DOM attributes/selectors, and Chinese ARIA anchors;
- reasoning peer ranges, slots, source commit, and patch hash;
- message-edit version, bundled ModuleLoader/slot contract, and patch hash.

The reasoning declaration points to a moving Git branch. The lockfile commit
and patch hash are therefore the actual reproducibility pins. A lockfile diff
for either third-party plugin is a blocking review item, not routine upgrade
noise.

## Read-only Commands

```sh
cd <fairy-dsh-checkout>
node fairy-system/upgrade-preflight.js --report
node fairy-system/upgrade-preflight.js \
  --profile /absolute/isolated/profile \
  --runtime /absolute/isolated/runtime/lib/client.js \
  --expected-version 0.1.3-alpha.1 \
  --expected-sha256 <ACCEPTED_SHA256>
```

## 2026-08-25 capability boundary

- The official DOM selector, attribute, slot, ARIA, Session, and Workspace
  contracts are versioned in `capability-matrix.json`.
- Fairy Visual's official DOM selectors are resolved through
  `fairy-visual/dsh-fairy-visual/src/client/dom-adapter.js`; observer helpers
  consume adapter exports instead of duplicating official selectors.
- The approved Visual settings dependency is
  `@deepseek-ai/dsh-settings@0.1.1-rc.2`, aligned with the installed DSH
  runtime family. (Superseded by the dsh-0.1.3-alpha.1 target above.)
- `upgrade-preflight.js` rejects the active profile/runtime by default and
  validates only an explicitly supplied isolated candidate pair.
- Browser evidence is required for normal/HDD, Light/Dark, historical-session,
  composer-replacement, sidebar-transition, and console-error cases before a
  new runtime can be approved.

## dsh-0.1.3-alpha.1 alignment record

- `capability-matrix.json`: matrixId/dshVersion moved to `dsh-0.1.3-alpha.1`;
  `officialRuntimeSha256` is `null` pending acceptance; the `dom.reasoning`
  selector follows the merged `选择模型`/`Select model` composer popup
  trigger; the official dependency family is listed at `0.1.3-alpha.1`
  (`@deepseek-ai/cordis`/`@deepseek-ai/schemastery` unchanged).
- `dom-adapter.js` re-verifies its zh/en unions and the model/reasoning
  vocabulary against the official 0.1.3-alpha.1 locale dictionaries.
- `preflight-build.js`, `verify.js` and `upgrade-preflight.js` constants now
  target `0.1.3-alpha.1` and fail closed on the missing runtime approval.
- Third-party pins (`dsh-reasoning-effort`, `dsh-message-edit`) and the
  profile locks are intentionally unchanged pending their compatibility
  re-review during candidate acceptance.
