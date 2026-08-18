// AI PR review for Sleeping Iron HD-2D via DeepSeek (OpenAI-compatible API).
// Advisory only: never blocks merges; exits 0 even on failure.
// Requires repo secret DEEPSEEK_API_KEY (https://api.deepseek.com). No key = skip.
//
// Context-aware review: the model receives (1) AGENTS.md project law,
// (2) this PR's previous AI-review comments + adjudicated ai-review issues
// (so already-dismissed findings are NOT repeated), (3) current full content
// of changed code files (so guards outside the diff hunks are visible), and
// (4) the reordered diff. Findings are filed as GitHub issues, deduplicated
// by TOPIC (title+detail hash), not by file path.

import { readFileSync } from "node:fs";
import { createHash } from "node:crypto";
import { Buffer } from "node:buffer";

const MAX_DIFF_CHARS = 30000;
const MAX_FILE_CHARS = 8000;
const MAX_FILES_TOTAL_CHARS = 30000;
const MAX_HISTORY_CHARS = 6000;
const MAX_LAW_CHARS = 4000;
const MAX_FINDINGS = 10;
const SEVERITY_LABELS = { high: "ai:high", medium: "ai:medium", low: "ai:low" };

// Per-file sort priority: implementation code first so the size limit cuts
// docs/spec artifacts instead of the code under review.
const PRIORITY_PATTERNS = [
  /^project\.godot$/,
  /^scripts\//,
  /^scenes\//,
  /^resources\//,
  /^\.github\/workflows\//,
  /^\.github\/scripts\//,
  /^assets\//,
  /^\.gdlintrc$/,
];

const SYSTEM_PROMPT = [
  "你是 Sleeping Iron HD-2D 的资深 Godot 4.7 架构师。项目是线性叙事冒险游戏（非开放世界），",
  "架构法律：中央 GameFlow 状态机 + 模块化可拓展 autoload 服务。",
  "你会收到四部分输入：①项目法律 AGENTS.md；②本 PR 之前的 AI 审查评论与已裁决 issues（含驳回理由）；",
  "③本次改动文件的当前完整内容；④重排后的 PR diff。",
  "硬性规则：",
  "- 已裁决或已驳回的问题【不得重复报告】，除非本次 diff 明确表明代码重新引入了该问题；",
  "- 必须结合完整文件内容判断，禁止仅凭 diff 片段缺失上下文而下结论（先查完整文件里是否已有守卫/处理）；",
  "- 只报真实、可行动的问题；风格偏好重复上一轮已被驳回的，视为违规。",
  "重点检查：",
  "1. 状态机解耦：状态流转只能发生在 GameFlow 内，禁止其他类硬编码状态流转；",
  "2. 帧率独立性：_process/_physics_process 必须正确使用 delta，禁止假设固定帧率；",
  "3. 碰撞层：所有物理体/区域必须显式设置 collision layer/mask，禁止默认值；",
  "4. 节点依赖：跨场景引用必须通过 @export 依赖注入或 EventBus 信号，禁止 get_node(\"../../...\") 脆弱路径；",
  "5. 模块化/可拓展：小职责 autoload 服务、组合优于继承、Resource 数据驱动；违反开闭原则或不可插拔的设计要给出重构建议；",
  "6. GDScript 全静态类型、命名规范（文件 snake_case、类型 PascalCase）；",
  "7. HD-2D 视觉不变量（精灵朝向/锚点/透明）与占位符政策（缺美术用 assets/placeholders/ 的 SVG，不阻塞）；",
  "8. 剧情忠实于 docs/source/正文.md，未写到的设定不得编造。",
  `输出必须是严格 JSON 对象（不要 markdown，不要代码块围栏）：`,
  `{"verdict":"👍可合入 | ⚠️建议修改 | 🚫有问题 三选一","summary":"一段总评","findings":[`,
  `{"severity":"high|medium|low","file":"文件路径","line":"行号或位置描述","title":"简短标题（10字内）","detail":"问题描述","suggestion":"建议"}]}`,
  `findings 最多 ${MAX_FINDINGS} 条，按严重程度排序，只报真实问题，无发现则空数组。不要客套话。`,
].join("\n");

// Topic-level marker: file path deliberately excluded so the same complaint
// about a different file cannot create a duplicate issue.
function markerFor(prNumber, finding) {
  const hash = createHash("sha256")
    .update(`${finding.title ?? ""}|${finding.detail ?? ""}`)
    .digest("hex")
    .slice(0, 16);
  return `<!-- ai-review:pr-${prNumber}-${hash} -->`;
}

async function fetchText(url, headers, timeoutMs = 15000) {
  const resp = await fetch(url, { headers, signal: AbortSignal.timeout(timeoutMs) });
  if (!resp.ok) return "";
  return await resp.text();
}

async function fetchJson(url, headers, timeoutMs = 15000) {
  const resp = await fetch(url, { headers, signal: AbortSignal.timeout(timeoutMs) });
  if (!resp.ok) return null;
  return await resp.json();
}

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

  const base = `https://api.github.com/repos/${owner}/${repo}`;
  const web = `https://github.com/${owner}/${repo}`;
  const ghHeaders = {
    Authorization: `Bearer ${process.env.GITHUB_TOKEN}`,
    Accept: "application/vnd.github+json",
    "X-GitHub-Api-Version": "2022-11-28",
    "User-Agent": "sleeping-iron-ai-review",
  };

  // ---- Diff (code-first ordering, .import noise dropped) ----
  const diffResp = await fetch(`${base}/pulls/${prNumber}`, {
    headers: { ...ghHeaders, Accept: "application/vnd.github.v3.diff" },
    signal: AbortSignal.timeout(30000),
  });
  if (!diffResp.ok) throw new Error(`diff fetch failed: ${diffResp.status}`);
  const diff = await diffResp.text();
  if (!diff.trim()) {
    console.log("Empty PR diff — skipping.");
    return;
  }
  const chunks = diff.split(/(?=^diff --git )/m).filter((c) => c.trim() !== "");
  const fileOf = (chunk) => {
    const match = chunk.match(/^diff --git a\/(\S+) b\//m);
    return match ? match[1] : "";
  };
  const priorityOf = (file) => {
    for (let i = 0; i < PRIORITY_PATTERNS.length; i += 1) {
      if (PRIORITY_PATTERNS[i].test(file)) return i;
    }
    return PRIORITY_PATTERNS.length;
  };
  const keep = chunks.filter((c) => !fileOf(c).endsWith(".import"));
  const ordered = [...keep].sort((a, b) => {
    const pa = priorityOf(fileOf(a));
    const pb = priorityOf(fileOf(b));
    return pa !== pb ? pa - pb : keep.indexOf(a) - keep.indexOf(b);
  });
  const changedFiles = ordered.map((c) => fileOf(c)).filter(Boolean);
  const fileList = changedFiles.join(", ");
  let diffBody = `Changed files (${ordered.length}): ${fileList}\n\n${ordered.join("")}`;
  const truncatedDiff = diffBody.length > MAX_DIFF_CHARS;
  if (truncatedDiff) diffBody = diffBody.slice(0, MAX_DIFF_CHARS) + "\n[truncated: remaining diff omitted]";

  // ---- Context 1: AGENTS.md project law ----
  let lawText = "";
  const lawJson = await fetchJson(
    `${base}/contents/AGENTS.md?ref=${event.pull_request.head.sha}`,
    ghHeaders
  );
  if (lawJson?.content) {
    lawText = Buffer.from(lawJson.content, "base64").toString("utf8").slice(0, MAX_LAW_CHARS);
  }

  // ---- Context 2: previous AI review comments + adjudicated issues ----
  const historyParts = [];
  const comments = await fetchJson(`${base}/issues/${prNumber}/comments`, ghHeaders);
  const priorReviews = (comments ?? [])
    .filter((c) => (c.body ?? "").startsWith("🤖"))
    .slice(-2)
    .map((c) => c.body.slice(0, 2500));
  if (priorReviews.length > 0) {
    historyParts.push(`### 本 PR 此前的 AI 审查评论\n${priorReviews.join("\n\n---\n\n")}`);
  }
  const pastIssues = await fetchJson(
    `${base}/issues?state=all&labels=ai-review&per_page=100`,
    ghHeaders
  );
  const issueLines = (pastIssues ?? [])
    .slice(0, 30)
    .map((i) => `- #${i.number} [${i.state}] ${i.title} — ${(i.body ?? "").replace(/\s+/g, " ").slice(0, 300)}`);
  if (issueLines.length > 0) {
    historyParts.push(`### 已裁决的 AI 审查 issues（已驳回的不得重复报告）\n${issueLines.join("\n")}`);
  }
  let historyText = historyParts.join("\n\n");
  if (historyText.length > MAX_HISTORY_CHARS) {
    historyText = historyText.slice(0, MAX_HISTORY_CHARS) + "\n[history truncated]";
  }

  // ---- Context 3: full content of changed code files ----
  const codeFilePattern = /\.gd$|\.tres$|^project\.godot$/;
  const fileParts = [];
  let fileChars = 0;
  for (const path of changedFiles) {
    if (!codeFilePattern.test(path)) continue;
    if (fileChars >= MAX_FILES_TOTAL_CHARS) break;
    const resp = await fetch(
      `${base}/contents/${path.split("/").map(encodeURIComponent).join("/")}?ref=${event.pull_request.head.sha}`,
      { headers: ghHeaders, signal: AbortSignal.timeout(15000) }
    );
    if (!resp.ok) continue;
    const j = await resp.json();
    if (!j?.content) continue;
    let content = Buffer.from(j.content, "base64").toString("utf8");
    if (content.length > MAX_FILE_CHARS) content = content.slice(0, MAX_FILE_CHARS) + "\n[...file truncated]";
    fileParts.push(`### FILE: ${path}\n\`\`\`gdscript\n${content}\n\`\`\``);
    fileChars += content.length;
  }
  const filesText = fileParts.join("\n\n");

  // ---- Assemble the user message ----
  const userParts = [];
  if (lawText) userParts.push(`# ① 项目法律 AGENTS.md\n${lawText}`);
  if (historyText) userParts.push(`# ② 本 PR 审查历史与已裁决 issues\n${historyText}`);
  if (filesText) userParts.push(`# ③ 改动文件当前完整内容\n${filesText}`);
  userParts.push(`# ④ 本次 diff\n\`\`\`diff\n${diffBody}\n\`\`\``);
  const userContent = userParts.join("\n\n");

  const llmResp = await fetch("https://api.deepseek.com/chat/completions", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model: "deepseek-chat",
      temperature: 0.2,
      response_format: { type: "json_object" },
      messages: [
        { role: "system", content: SYSTEM_PROMPT },
        { role: "user", content: userContent },
      ],
    }),
    signal: AbortSignal.timeout(120000),
  });
  if (!llmResp.ok) throw new Error(`deepseek call failed: ${llmResp.status}`);
  const llmJson = await llmResp.json();
  const reviewText = llmJson?.choices?.[0]?.message?.content;
  if (!reviewText) throw new Error("empty review from model");

  let review;
  try {
    review = JSON.parse(reviewText);
  } catch {
    console.warn("Model output was not valid JSON — posting raw text, skipping issue creation.");
    review = null;
  }

  // ---- 1. Post the PR comment ----
  const lines = [];
  lines.push("🤖 **AI 架构审查（DeepSeek，仅供参考）**");
  if (review && typeof review.verdict === "string") lines.push("", review.verdict);
  if (review && typeof review.summary === "string") lines.push("", review.summary);
  if (review && Array.isArray(review.findings) && review.findings.length > 0) {
    lines.push("");
    review.findings.slice(0, MAX_FINDINGS).forEach((f, i) => {
      lines.push(
        `${i + 1}. **[${f.severity ?? "?"}] ${f.title ?? "未命名"}" — ` +
          `${f.file ?? "?"}${f.line ? `:${f.line}` : ""}`,
        `   - 问题：${f.detail ?? ""}`,
        `   - 建议：${f.suggestion ?? ""}`
      );
    });
  } else if (!review) {
    lines.push("", reviewText);
  } else {
    lines.push("", "无发现。");
  }
  lines.push("");
  if (truncatedDiff) lines.push("> diff 超过长度限制已被截断审查。");
  lines.push("> 本评论由 ai_reviewer.yml 自动生成，不作为合并门禁。");

  const commentResp = await fetch(`${base}/issues/${prNumber}/comments`, {
    method: "POST",
    headers: ghHeaders,
    body: JSON.stringify({ body: lines.join("\n") }),
    signal: AbortSignal.timeout(30000),
  });
  if (!commentResp.ok) throw new Error(`comment post failed: ${commentResp.status}`);
  console.log("AI review comment posted to PR.");

  // ---- 2. Create one issue per finding (topic-level dedup) ----
  if (!review || !Array.isArray(review.findings)) return;
  await ensureLabels(base, ghHeaders, ["ai-review", "ai:high", "ai:medium", "ai:low"]);
  const existingMarkers = await fetchExistingMarkers(base, ghHeaders, "ai-review");

  let created = 0;
  let skipped = 0;
  for (const finding of review.findings.slice(0, MAX_FINDINGS)) {
    const marker = markerFor(prNumber, finding);
    if (existingMarkers.has(marker)) {
      skipped += 1;
      continue;
    }
    const severity = finding.severity ?? "medium";
    const label = SEVERITY_LABELS[severity] ?? SEVERITY_LABELS.medium;
    const title = `[AI审查] ${finding.title ?? "未命名问题"}`.slice(0, 120);
    const issueBody = [
      `**严重程度**: ${severity}`,
      `**文件**: \`${finding.file ?? "?"}\`${finding.line ? `  **位置**: ${finding.line}` : ""}`,
      "",
      `**问题**`,
      finding.detail ?? "",
      "",
      `**建议**`,
      finding.suggestion ?? "",
      "",
      `来源: PR #${prNumber}（${web}/pull/${prNumber}）AI 架构审查自动生成，参考性建议。`,
      marker,
    ].join("\n");
    const issueResp = await fetch(`${base}/issues`, {
      method: "POST",
      headers: ghHeaders,
      body: JSON.stringify({ title, body: issueBody, labels: ["ai-review", label] }),
      signal: AbortSignal.timeout(30000),
    });
    if (issueResp.ok) created += 1;
    else console.warn(`issue create failed (${issueResp.status}) for: ${title}`);
  }
  console.log(`AI review issues: ${created} created, ${skipped} deduplicated.`);
}

async function ensureLabels(base, headers, names) {
  for (const name of names) {
    const resp = await fetch(`${base}/labels/${encodeURIComponent(name)}`, {
      headers,
      signal: AbortSignal.timeout(15000),
    });
    if (resp.ok) continue;
    await fetch(`${base}/labels`, {
      method: "POST",
      headers,
      body: JSON.stringify({ name, color: name.startsWith("ai:") ? "0075ca" : "0e8a16" }),
      signal: AbortSignal.timeout(15000),
    }).catch(() => {});
  }
}

async function fetchExistingMarkers(base, headers, label) {
  const markers = new Set();
  for (const state of ["open", "closed"]) {
    const resp = await fetch(`${base}/issues?state=${state}&labels=${label}&per_page=100`, {
      headers,
      signal: AbortSignal.timeout(15000),
    });
    if (!resp.ok) continue;
    const issues = await resp.json();
    for (const issue of issues) {
      const body = issue.body ?? "";
      for (const match of body.matchAll(/<!-- ai-review:([a-z0-9-]+) -->/g)) {
        markers.add(`<!-- ai-review:${match[1]} -->`);
      }
    }
  }
  return markers;
}

main().catch((error) => {
  // Advisory review must never fail the workflow.
  console.error(`AI review skipped due to error: ${error.message}`);
  process.exit(0);
});
