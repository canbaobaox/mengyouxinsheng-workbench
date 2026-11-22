// M0 骨架：最小 Tauri 入口。
// M1 在此挂 sidecar（派活引擎）与 SQL 插件；M2 再加审批与事件命令。
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

fn main() {
    tauri::Builder::default()
        .plugin(tauri_plugin_sql::Builder::default().build())
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
