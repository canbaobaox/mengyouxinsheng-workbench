import react from "@vitejs/plugin-react";
import { defineConfig } from "vite";

// Tauri 开发端口固定 1420（与 src-tauri/tauri.conf.json 的 devUrl 一致）。
export default defineConfig({
  build: { outDir: "dist" },
  clearScreen: false,
  plugins: [react()],
  server: { port: 1420, strictPort: true },
});
