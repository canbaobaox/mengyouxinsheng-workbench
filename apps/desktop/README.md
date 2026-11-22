# 桌面应用（Tauri 2 + React + Vite）

## 前置

- Node.js 20+
- Rust stable（`rustup` 安装，含 cargo）
- Windows 10/11 自带 WebView2（多数机器已有；离线安装包需另加约 127 MB WebView2）

> 注意：搭骨架的机器（Linux 云电脑）没有 cargo，`src-tauri/` 是手写最小结构，
> 未经 `cargo check`。请在开发机（Windows 或装好 Rust 的机器）上验证。

## 开发

```bash
npm install
npm run dev          # 网页开发模式 http://localhost:1420
npm run tauri dev    # 桌面开发模式（需 cargo）
```

## 打包

```bash
npm run tauri build  # 产出 .msi / NSIS 安装包（需 cargo）
```

## 目录

- `src/`：React 前端。M0 只有占位界面；M2 接入 Tailwind + shadcn/ui、React Flow 流程图、岗位详情页、虚拟办公室。
- `src-tauri/`：Tauri 配置、Rust 入口、SQLite 插件（`tauri-plugin-sql`）。

## 数据库

SQLite 单文件存在本机。表结构见仓库根目录 `db/schema.sql`；数据文件（`*.db`）不进仓库。
