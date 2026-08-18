// AI PR review for Sleeping Iron HD-2D via DeepSeek (OpenAI-compatible API).
// Advisory only: never blocks merges; exits 0 even on failure.
// Requires repo secret DEEPSEEK_API_KEY (https://api.deepseek.com). No key = skip.

import { readFileSync } from "node:fs";

const MAX_DIFF_CHARS = 40000;

const SYSTEM_PROMPT = [
  "你是 Sleeping Iron HD-2D 的资深 Godot 4.7 架构师。项目是线性叙事冒险游戏（非开放世界），",
  "架构法律：中央 GameFlow 状态机 + 模块化可拓展 autoload 服务。审查这个 PR 的 diff（unified diff 格式），",
  "输出精炼的中文 markdown 审查报告。重点检查：",
  "1. 状态机解耦：状态流转只能发生在 GameFlow 内，禁止其他类硬编码状态流转；",
  "2. 帧率独立性：_process/_physics_process 必须正确使用 delta，禁止假设固定帧率；",
  "3. 碰撞层：所有物理体/区域必须显式设置 collision layer/mask，禁止默认值；",
  "4. 节点依赖：跨场景引用必须通过 @export 依赖注入或 EventBus 信号，禁止 get_node(\"../../...\") 脆弱路径；",
  "5. 模块化/可拓展：小职责 autoload 服务、组合优于继承、Resource 数据驱动；违反开闭原则或不可插拔的设计要给出重构建议；",
  "6. GDScript 全静态类型、命名规范（文件 snake_case、类型 PascalCase）；",
  "7. HD-2D 视觉不变量（精灵朝向/锚点/透明）与占位符政策（缺美术用 assets/placeholders/ 的 SVG，不阻塞）；",
  "8. 剧情忠实于 docs/source/正文.md，未写到的设定不得编造。",
  "输出格式：第一行总评（👍可合入 / ⚠️建议修改 / 🚫有问题），然后按严重程度列出发现（文件路径 + 行号或描述 + 建议），",
  "最多 10 条；无发现则明确说明。不要客套话，不要复述 diff。",
].join("");

async function main() {
  const apiKey = process.env.DEEPSEEK_API_KEY;
  if (!apiKey) {
    console.log("DEEPSEEK_API_KEY secret not configured — skipping AI review (advisory only).");
    return;
  }

  const [owner, repo] = (process.env.GITHUB_REPOSITORY ?? "").split("/");
  const event = JSON.parse(readFileSync(process.env.GITHUB_EVENT_PATH, "utf8"));
  const prNumber = event?.pull_request?.number;
  if (!owner || !repo || !prNumber) {
    console.log("Not a pull_request event or missing context — skipping.");
    return;
  }

  const ghHeaders = {
    Authorization: `Bearer ${process.env.GITHUB_TOKEN}`,
    Accept: "application/vnd.github+json",
    "X-GitHub-Api-Version": "2022-11-28",
    "User-Agent": "sleeping-iron-ai-review",
  };

  const diffResp = await fetch(
    `https://api.github.com/repos/${owner}/${repo}/pulls/${prNumber}`,
    { headers: { ...ghHeaders, Accept: "application/vnd.github.v3.diff" }, signal: AbortSignal.timeout(30000) }
  );
  if (!diffResp.ok) throw new Error(`diff fetch failed: ${diffResp.status}`);
  let diff = await diffResp.text();
  if (!diff.trim()) {
    console.log("Empty PR diff — skipping.");
    return;
  }
  const truncated = diff.length > MAX_DIFF_CHARS;
  if (truncated) diff = diff.slice(0, MAX_DIFF_CHARS) + "\n[truncated]";

  const llmResp = await fetch("https://api.deepseek.com/chat/completions", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model: "deepseek-chat",
      temperature: 0.2,
      messages: [
        { role: "system", content: SYSTEM_PROMPT },
        { role: "user", content: `PR diff:\n\n\`\`\`diff\n${diff}\n\`\`\`` },
      ],
    }),
    signal: AbortSignal.timeout(120000),
  });
  if (!llmResp.ok) throw new Error(`deepseek call failed: ${llmResp.status}`);
  const llmJson = await llmResp.json();
  const review = llmJson?.choices?.[0]?.message?.content;
  if (!review) throw new Error("empty review from model");

  const body =
    `🤖 **AI 架构审查（DeepSeek，仅供参考）**\n\n${review}\n\n` +
    (truncated ? "> diff 超过长度限制已被截断审查。\n" : "") +
    "> 本评论由 ai_reviewer.yml 自动生成，不作为合并门禁。";

  const commentResp = await fetch(
    `https://api.github.com/repos/${owner}/${repo}/issues/${prNumber}/comments`,
    {
      method: "POST",
      headers: ghHeaders,
      body: JSON.stringify({ body }),
      signal: AbortSignal.timeout(30000),
    }
  );
  if (!commentResp.ok) throw new Error(`comment post failed: ${commentResp.status}`);
  console.log("AI review posted to PR.");
}

main().catch((error) => {
  // Advisory review must never fail the workflow.
  console.error(`AI review skipped due to error: ${error.message}`);
  process.exit(0);
});
