-- 梦由心生工作台 — SQLite 表结构
-- 本地优先：单文件 SQLite；飞书多维表格只作可选同步。
-- 约定：时间统一用 ISO 8601 文本（UTC）；金额用分（整数）存，避免浮点误差；
-- 佣金率用千分比整数存（如 200 表示 20.0%）；列名不用数字开头。
-- event_log 为事件溯源表：只追加，不更新、不删除（靠应用层约束）。

PRAGMA foreign_keys = ON;

-- 商品库：选品岗的候选与在推商品
CREATE TABLE IF NOT EXISTS products (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  name          TEXT NOT NULL,
  platform_pid  TEXT,               -- 平台商品 ID（如精选联盟商品 ID）
  price_cents   INTEGER NOT NULL DEFAULT 0,
  commission_rate_permille INTEGER NOT NULL DEFAULT 0, -- 佣金率千分比，200 = 20.0%
  sales_30d     INTEGER NOT NULL DEFAULT 0,            -- 近 30 天销量
  rating        REAL,               -- 商品评分（满分 5）
  return_rate_permille INTEGER,     -- 退货率千分比
  merchant_score REAL,              -- 商家体验分
  status        TEXT NOT NULL DEFAULT '待上架'
                    CHECK (status IN ('在推', '待上架', '在售', '淘汰')),
  score         REAL,               -- 选品评分；权重未定前留空，权重是示例权重、未定
  created_at    TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now')),
  updated_at    TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now'))
);
CREATE INDEX IF NOT EXISTS idx_products_status ON products (status);

-- 订单：对帐的最小粒度；归因不可变（建好后不改 video_id / product_id）
CREATE TABLE IF NOT EXISTS orders (
  id              INTEGER PRIMARY KEY AUTOINCREMENT,
  order_no        TEXT NOT NULL UNIQUE,
  product_id      INTEGER REFERENCES products (id),
  order_date      TEXT NOT NULL,     -- YYYY-MM-DD
  price_cents     INTEGER NOT NULL DEFAULT 0,
  commission_rate_permille INTEGER NOT NULL DEFAULT 0,
  commission_cents INTEGER NOT NULL DEFAULT 0,
  status          TEXT NOT NULL DEFAULT '待结算'
                    CHECK (status IN ('待结算', '已结算', '退货')),
  video_id        TEXT,              -- 带来这单的视频
  platform        TEXT NOT NULL DEFAULT '抖音',
  created_at      TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now'))
);
CREATE INDEX IF NOT EXISTS idx_orders_date ON orders (order_date);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders (status);

-- 工单：8 步流转的主体；阶段字段是步骤推导的唯一依据（复盘不是岗）
CREATE TABLE IF NOT EXISTS work_orders (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  title         TEXT NOT NULL,
  product_id    INTEGER REFERENCES products (id),
  stage         TEXT NOT NULL DEFAULT '选品'
                  CHECK (stage IN ('选品', '编导', '拍摄', '剪辑', '分发', '投放', '对帐', '复盘')),
  status        TEXT NOT NULL DEFAULT '待开始'
                  CHECK (status IN ('待开始', '进行中', '已完成', '已阻塞')),
  assignee_post TEXT,               -- 当前负责岗位 id（如 xuanpin）
  script_text   TEXT,               -- 编导脚本正文（合规检查的输入）
  evidence      TEXT,               -- 证据链接/摘要（JSON 文本）
  created_at    TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now')),
  updated_at    TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now'))
);
CREATE INDEX IF NOT EXISTS idx_work_orders_stage ON work_orders (stage);
CREATE INDEX IF NOT EXISTS idx_work_orders_status ON work_orders (status);

-- 日志：岗的动作留痕
CREATE TABLE IF NOT EXISTS ops_logs (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  work_order_id INTEGER REFERENCES work_orders (id),
  post          TEXT NOT NULL,      -- 岗位 id
  action        TEXT NOT NULL,      -- 如：选品通过/脚本过审/拍摄完成/发布/对帐/复盘
  detail        TEXT,
  created_at    TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now'))
);
CREATE INDEX IF NOT EXISTS idx_ops_logs_order ON ops_logs (work_order_id);

-- 事件：金额与业务事件（出单、退货、投放等），对帐勾稽的输入
CREATE TABLE IF NOT EXISTS events (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  work_order_id INTEGER REFERENCES work_orders (id),
  type          TEXT NOT NULL,      -- 如：选品/脚本/拍摄/剪辑/发布/投放/出单/退货/对帐/复盘
  product_id    INTEGER REFERENCES products (id),
  amount_cents  INTEGER NOT NULL DEFAULT 0,
  detail        TEXT,
  created_at    TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now'))
);
CREATE INDEX IF NOT EXISTS idx_events_type ON events (type);

-- 审批：人工审批留痕（HITL）
CREATE TABLE IF NOT EXISTS approvals (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  work_order_id INTEGER REFERENCES work_orders (id),
  stage         TEXT NOT NULL,
  approver      TEXT NOT NULL DEFAULT '董事长',
  decision      TEXT NOT NULL DEFAULT '待定'
                  CHECK (decision IN ('待定', '批准', '打回')),
  reason        TEXT,
  evidence      TEXT,               -- 审批依据（JSON 文本）
  created_at    TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now'))
);
CREATE INDEX IF NOT EXISTS idx_approvals_order ON approvals (work_order_id);

-- 每日数据：每日一行汇总；ROI = 投放收入 / 投放花费（收入指投放带来的佣金）
CREATE TABLE IF NOT EXISTS daily_stats (
  id                INTEGER PRIMARY KEY AUTOINCREMENT,
  date              TEXT NOT NULL UNIQUE, -- YYYY-MM-DD
  commission_cents  INTEGER NOT NULL DEFAULT 0,
  order_count       INTEGER NOT NULL DEFAULT 0,
  video_count       INTEGER NOT NULL DEFAULT 0,
  ad_spend_cents    INTEGER NOT NULL DEFAULT 0,
  ad_revenue_cents  INTEGER NOT NULL DEFAULT 0,
  created_at        TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now'))
);

-- 岗位状态：7 岗当前状态（虚拟办公室小宠物的状态来源）
CREATE TABLE IF NOT EXISTS post_states (
  post                TEXT PRIMARY KEY, -- 岗位 id
  status              TEXT NOT NULL DEFAULT '待命',
  current_work_order_id INTEGER REFERENCES work_orders (id),
  progress_permille   INTEGER NOT NULL DEFAULT 0,
  current_task        TEXT NOT NULL DEFAULT '待命',
  updated_at          TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now'))
);

-- SOP 规则：喂数据三层做法的落地点；须人工批准后才可启用
CREATE TABLE IF NOT EXISTS sop_rules (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  name        TEXT NOT NULL,
  source      TEXT NOT NULL DEFAULT 'manual'
                CHECK (source IN ('manual', 'llm-draft', 'pm4py')),
  status      TEXT NOT NULL DEFAULT '草稿'
                CHECK (status IN ('草稿', '待批', '已启用', '已停用')),
  content     TEXT NOT NULL,        -- SOP / YAML 规则正文
  created_at  TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now')),
  updated_at  TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now'))
);

-- 事件溯源：只追加的事实日志（Agent-Autoloop 式）；应用层禁止 UPDATE/DELETE
CREATE TABLE IF NOT EXISTS event_log (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  seq         INTEGER NOT NULL UNIQUE, -- 单调递增序号（由写入方分配）
  thread_id   TEXT NOT NULL,           -- 工单 thread（work_orders.id 的文本形式）
  actor       TEXT NOT NULL,           -- 行为方：岗位 id / ceo / 董事长 / system
  event_type  TEXT NOT NULL,           -- 如：dispatch / handoff / approve / reject / complete / guard_block
  payload     TEXT NOT NULL DEFAULT '{}', -- JSON 文本
  created_at  TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now'))
);
CREATE INDEX IF NOT EXISTS idx_event_log_thread ON event_log (thread_id, seq);
