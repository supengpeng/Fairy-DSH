# Fairy DSH

Fairy 的 DSH 插件套件（开源发布候选目录）。本目录与任何生产环境
完全独立，不包含个人会话、日志、密钥、缓存、
`node_modules` 或完整游戏语料。

## 目录

- `fairy-contracts/`：跨插件契约与诊断边界
- `browser-dock/`、`balance-meter/`、`fairy-startup/`、`fairy-voice/`、`fairy-visual/`：Fairy 插件
- `fairy-system/`：离线检查与验收工具
- `profiles/web/`：独立 Web profile 模板

## 独立测试

需要已安装并固定版本的 DSH CLI、Node.js 和 pnpm。测试时必须使用独立
`DSH_HOME`，不要指向生产目录：

```sh
DSH_HOME="$PWD/.dsh-test-home" ./scripts/test-isolated.sh
```

脚本在仓库根做一次 pnpm 工作区安装（被 `link:` 引用的插件只能从自己的
真实目录解析依赖，profile 内的 `node_modules` 覆盖不到），再安装 profile
依赖并做一次冒烟启动。挂载由 `scripts/link-profile.mjs` 完成，Windows 与
POSIX 均使用绝对目标（相对目标的 junction 经挂载点再解析会漂移）。

## 私有资料注入点

以下内容不随仓库分发，按需要放到独立 `DSH_HOME` 下：

| 内容 | 位置 |
| --- | --- |
| 语音参考音频 / 提示词 | `$DSH_HOME/fairy-voice/runtime/reference/fairy_ref.wav`、`fairy_ref.txt` |
| 语音简报配置 | `$DSH_HOME/fairy-voice/voice-brain.json` |
| browser-dock 运行时状态 | `$DSH_HOME/browser-dock/` |
| Fairy 人格 / 风格 / 世界观语料 | `$DSH_HOME/.agent-presets/fairy/{personality,style,canon,behavior}/` |
| voice-core 私有运行时 | `$DSH_FAIRY_RUNTIME_ROOT/.agent-presets/fairy/runtime/`，并以 `DSH_FAIRY_ENABLE_RUNTIME=1` 显式开启 |

缺省时：语音参考缺失走内置兜底文案并记录一条 warn；voice-core 两行默认
disabled，选中 Fairy preset 只生效 persona 与标准工具面，不会因私有运行时
缺席而拖垮整个 entry tree。

## 第三方依赖

第三方包只通过 manifest/lockfile 引用，不复制其源码。许可证和来源在
`THIRD_PARTY_NOTICES.md` 中维护。

## 许可边界

除文件另有说明外，本仓库中 Fairy-DSH 的原创代码、脚本、测试、配置和
文档按 Apache License 2.0 发布，详见 `LICENSE` 与 `NOTICE`。第三方插件、
依赖及其生成物不在本许可范围内，继续适用各自许可证。

《绝区零》剧情文本、角色资料、官方素材，私有 WORLD CORE、个人语料、会话
数据和运行时密钥均不随仓库发布；本项目不授予相关版权、商标或官方关联权利。
发布前请按 `RELEASE-CHECKLIST.md` 复核分发内容。
