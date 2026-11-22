# 梦由心生工作台 (mengyouxinsheng-workbench)

抖音精选联盟一人公司 AI 工作台：7 岗 Agent 分工 + 8 步工单流转，本地部署开源版。

## 愿景

一个人、一台电脑、一套工作台，就能把抖音精选联盟带货的整条链路跑起来：选品、写脚本、拍、剪、发、投放、对帐、复盘。7 个岗位各是一位窄专家 Agent，CEO（总管）负责派活、校验与汇总，关键节点停下来等人点头。数据存在本地，不依赖云服务。

业务模式说清楚：**抖音精选联盟达人带货赚佣金，没有店铺、不进货、不囤货。** 选品只看佣金率、销量、评分、退货率。

## 组织：董事长 + CEO + 7 岗

| 角色 | 职责 | 铁律 |
|---|---|---|
| 董事长（用户） | 战略、预算、拍板不可逆事项 | 花钱、删数据、对外公开须先点头 |
| CEO 蚕宝宝（总管 Agent） | 统筹、派活、校验、汇总 | 只派活、校验、汇总，不做专家活 |
| 选品 | 从精选联盟选品池挑商品 | 佣金率低于 20% 不推 |
| 编导 | 写脚本，合规写进脚本里 | 极限词零出现、医疗功效零宣称；合规是编导的责任 |
| 拍摄 | 按脚本拍摄 | 画质不达标重拍 |
| 剪辑 | 剪辑、字幕、封面 | 字幕错字零容忍 |
| 分发 | 多平台发布 | 每天至少发 1 条 |
| 投放 | 付费投放 | ROI 低于 1.5 立即停 |
| 对帐 | 佣金登记与勾稽 | 每一笔佣金都留记录 |

## 8 步工单流转

```text
选品 → 编导 → 拍摄 → 剪辑 → 分发 → 投放 → 对帐 → 复盘
```

守卫规则（流程里的硬门槛，命中即打回，不靠自觉）：

- **ROI < 1.5 禁止进投放**，已在投的立即停。
- **脚本命中禁词禁止进拍摄**，打回编导改。
- **发前审查是强制人工节点**：验脸验声留证据，审查通过才允许发布，任何 Agent 不得自行放行。

## 核心设计

- **岗位可配置**：每个岗位就是一份配置文件（`config/posts/*.jsonc`，CrewAI 式 role + goal + backstory + tools + guardrails）。改功能改配置，不改代码；以后可在界面上直接改。
- **流程透明可见**：每个工单是一条可追踪的线。点开一个岗位，能看到流程图（当前节点高亮）、步骤时间线、正在干什么、全部历史事件与审批记录、每一步的证据。状态落库，不丢、不靠口头汇报。
- **喂数据生成 SOP（三层做法）**：目前没有成熟开源产品能把历史工单直接喂进去就生成可执行工作流，可行的是：(1) 把工单/日志导出为事件日志，用 PM4Py 做流程发现（离线分析）；(2) 用 LLM 总结高频路径、变体与瓶颈，起草 SOP；(3) 人工批准后落为可执行规则。数据质量（case ID、时间戳、活动命名一致性）是前提。
- **人工审批（HITL）**：改禁词表、改选品标准、花钱、对外发布、发前审查，全部停下来等人点头；审批留痕。
- **多 Agent 防抢活**：单一派活入口 + 认领（lease）+ 显式交接（点名下一岗）+ 凭证据完成 + 跳数熔断。

## 技术拼法（已敲定，见调研报告）

| 层 | 选型 | 借鉴来源 |
|---|---|---|
| 流程骨架 | LangGraph StateGraph + SQLite checkpoint | langchain-ai/langgraph（MIT） |
| 派活与审批 | 事件 → rules.json 派活 → 挂起零消耗 → 卡片审批 → 续跑；指令数据分离；8 层熔断 | KKKKhazix/agent-autoloop（MIT） |
| 岗位配置 | agents/*.jsonc + crew.jsonc 文件化 | crewAIInc/crewAI（MIT） |
| SOP 执行载体 | SOP / SOPStep / SOPEngine | agentscope-ai/agentscope（Apache-2.0） |
| 状态机 | XState（与 LangGraph 同构表达） | statelyai/xstate（MIT） |
| 可视化 | React Flow 流程图 + shadcn/ui + Recharts/ECharts | xyflow/xyflow、shadcn-ui/ui（MIT） |
| 桌面壳 | Tauri 2 + React + Node/Python sidecar | Tauri（Apache-2.0/MIT） |
| 数据 | SQLite 单文件（本地优先），飞书多维表格作可选同步 | — |
| 佣金模型 | 订单归因不可变 + 佣金记账与分发分离，退货订单佣金冲回 | Medusa 式模型（MIT 核心） |

完整调研见 `docs/plan.md` 与调研报告（`research_notes/workbench-open-source-research-20261122-0954/report.md`，不在本仓库内）。

## 快速开始

前置：Node.js 20+、Rust stable（cargo）、Windows 10/11 自带 WebView2（多数机器已有）。

```bash
git clone https://github.com/canbaobaox/mengyouxinsheng-workbench.git
cd mengyouxinsheng-workbench
npm install
npm run dev          # 网页开发模式（localhost）
npm run tauri dev    # 桌面开发模式（需 cargo）
npm run tauri build  # 打包 .msi / NSIS 安装包（需 cargo）
```

模型调用走 OpenAI 兼容 API，Key 由用户在设置页自填，存系统 keychain，**绝不进代码、不进仓库**。

## 仓库结构

```text
.
├── apps/desktop/            # Tauri 桌面应用（React 前端 + Rust 壳）
│   ├── src/                 # 前端：仪表盘、工单看板、岗位详情、虚拟办公室
│   └── src-tauri/           # Tauri 配置、Rust 入口、SQLite 插件
├── config/
│   ├── crew.jsonc           # 8 步流转、守卫、派活与审批规则
│   └── posts/               # 7 个岗位的角色卡（role/goal/backstory/tools/guardrails）
├── db/
│   └── schema.sql           # SQLite 表结构（商品/订单/工单/日志/事件/审批/每日数据）
├── docs/
│   └── plan.md              # 产品方案
└── .github/workflows/ci.yml # lint + typecheck + 构建 + schema 校验
```

## 当前状态：M0 骨架阶段

已就位：目录结构、岗位配置、数据库表结构、CI、产品方案。
待实现：派活引擎（M1）、审批与可视化（M2）、喂数据 SOP（M3）、打包发布（M4）。详见 `docs/plan.md` 第 11 节。

## 许可证与借鉴来源

本项目 MIT 协议（见 LICENSE）。借鉴的开源项目只取 MIT / Apache-2.0 宽松协议者；以下项目**许可证不合，只借思路、不复用代码**：n8n（Sustainable Use License）、OtoDock（FSL-1.1）、My Virtual Office / PM4Py / AppFlowy / Plane（AGPL-3.0）、Vendure（GPLv3）。MetaGPT 已停滞，不在其上建系统。Grok Bot 为闭源商业产品，只借“一岗一窄 Bot + 总管派活 + 显式交接”的分工模式。

## 安全须知

- 仓库里绝不放任何密钥、Key、token、密码。API Key 只存在用户本机系统 keychain。
- 改禁词表、改选品标准、花钱、删数据、对外公开，须先经董事长（用户）批准。
- 没接上真实数据的地方，一律显示“暂无数据/示例”，不许用写死数字冒充。
