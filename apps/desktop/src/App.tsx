// M0 骨架：静态占位界面。
// M2 再接真实数据（SQLite）与 React Flow 流程图、岗位详情页、虚拟办公室。
const STAGES = [
  "选品",
  "编导",
  "拍摄",
  "剪辑",
  "分发",
  "投放",
  "对帐",
  "复盘",
] as const;

export default function App() {
  return (
    <main style={{ fontFamily: "system-ui, sans-serif", padding: 24 }}>
      <h1>梦由心生工作台</h1>
      <p>
        骨架阶段（M0）：目录、岗位配置、数据库、CI 已就位；派活引擎与可视化待实现。
      </p>
      <ol>
        {STAGES.map((stage, index) => (
          <li key={stage}>
            第 {index + 1} 步：{stage}
          </li>
        ))}
      </ol>
      <p>
        岗位配置：config/posts/；流水线与守卫：config/crew.jsonc；数据库：db/schema.sql。
      </p>
    </main>
  );
}
