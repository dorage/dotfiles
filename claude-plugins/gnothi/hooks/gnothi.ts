#!/usr/bin/env bun
// gnothi - γνῶθι σεαυτόν (네 자신을 알라)
//
// LLM 이 "지금 나는 어느 세션에서, 어느 모델로 돌고 있는가"를 알게 한다.
//
//   SessionStart      session_id 와 model 을 컨텍스트에 주입하고, 모델에 맞는 룰(rules/*.md)을 함께 넣는다.
//                     startup/resume/clear/compact 모두 다시 주입한다. compact 뒤에도 룰이 남아야 하기 때문이다.
//   UserPromptSubmit  트랜스크립트의 마지막 assistant 메시지로 "실제로 답한 모델"을 확인한다.
//                     매칭되는 룰 집합이 바뀌었으면 룰을 다시 주입하고, 모델 이름만 바뀌었으면 한 줄로 알린다.
//   SessionEnd        세션 상태 파일을 지운다.
//
// 모델 판별 출처 (앞에서부터 처음 성공한 것을 쓴다):
//   hook        훅 입력의 .model  — Claude Code 가 넣어줄 때만 있다 (2.1.270 startup 에서는 없었다)
//   transcript  트랜스크립트의 마지막 assistant 메시지 .message.model — resume/compact 와 두 번째 프롬프트부터 확실하다
//   argv        부모 claude 프로세스의 --model 인자 — 별칭(opus, haiku, fable ...)일 수 있다
//   env         ANTHROPIC_MODEL
//   settings    {cwd}/.claude/settings.local.json → {cwd}/.claude/settings.json → ~/.claude/settings.json 의 .model
//   unknown     아무 데서도 못 찾음
//
// 룰 파일:
//   플러그인의 rules/*.md 와 $GNOTHI_RULES_DIR (기본 ~/.claude/gnothi/rules) 의 *.md.
//   같은 파일명이면 사용자 디렉터리의 것이 플러그인 것을 덮는다.
//   파일명(확장자 제외)이 모델 문자열에 대소문자 구분 없이 부분일치하면 주입한다. 예: fable.md ↔ claude-fable-5-1
//   default.md 는 다른 룰이 하나도 매칭되지 않을 때만 주입한다.
//
// 끄기: GNOTHI_DISABLE=1
// 상태 위치 바꾸기: GNOTHI_STATE_DIR (기본 ~/.claude/gnothi/state)

import { existsSync, mkdirSync, readdirSync, readFileSync, rmSync, statSync, unlinkSync, writeFileSync } from "node:fs";
import { basename, dirname, join, resolve } from "node:path";

type HookInput = {
  hook_event_name?: string;
  session_id?: string;
  cwd?: string;
  transcript_path?: string;
  model?: string;
  agent_id?: string;
};

type Source = "hook" | "transcript" | "argv" | "env" | "settings" | "unknown";
const VERIFIED_SOURCES: Source[] = ["hook", "transcript"];

const HOME = process.env.HOME ?? "";
const PLUGIN_DIR = resolve(dirname(Bun.main), "..");
const RULES_DIR = join(PLUGIN_DIR, "rules");
const USER_RULES_DIR = process.env.GNOTHI_RULES_DIR ?? join(HOME, ".claude", "gnothi", "rules");
const STATE_DIR = process.env.GNOTHI_STATE_DIR ?? join(HOME, ".claude", "gnothi", "state");

// settings 의 model 값은 "claude-fable-5-1[1m]" 처럼 컨텍스트 윈도우 표기가 붙을 수 있다. 그 부분은 떼어낸다.
const stripSuffix = (m: string) => m.replace(/\[.*$/, "");

function readJson(path: string): any | null {
  try {
    return JSON.parse(readFileSync(path, "utf8"));
  } catch {
    return null;
  }
}

function modelFromTranscript(transcript: string | undefined): string | null {
  if (!transcript || !existsSync(transcript)) return null;
  let text: string;
  try {
    text = readFileSync(transcript, "utf8");
  } catch {
    return null;
  }
  const lines = text.split("\n").filter((l) => l.includes('"type":"assistant"'));
  for (let i = lines.length - 1; i >= 0; i--) {
    try {
      const m = JSON.parse(lines[i])?.message?.model;
      // "<synthetic>" 은 Claude Code 가 만든 메시지라 실제 모델이 아니다.
      if (typeof m === "string" && m && !m.startsWith("<")) return m;
    } catch {
      /* 깨진 줄은 건너뛴다 */
    }
  }
  return null;
}

function modelFromArgv(): string | null {
  try {
    const out = Bun.spawnSync(["ps", "-o", "args=", "-p", String(process.ppid)]).stdout.toString();
    const m = /--model[= ]+(\S+)/.exec(out);
    return m?.[1] ?? null;
  } catch {
    return null;
  }
}

function modelFromSettings(cwd: string | undefined): string | null {
  const candidates = [
    cwd && join(cwd, ".claude", "settings.local.json"),
    cwd && join(cwd, ".claude", "settings.json"),
    join(HOME, ".claude", "settings.json"),
  ].filter(Boolean) as string[];
  for (const f of candidates) {
    const m = readJson(f)?.model;
    if (typeof m === "string" && m) return stripSuffix(m);
  }
  return null;
}

function resolveModel(input: HookInput): { model: string; source: Source } {
  if (typeof input.model === "string" && input.model) return { model: stripSuffix(input.model), source: "hook" };
  const t = modelFromTranscript(input.transcript_path);
  if (t) return { model: t, source: "transcript" };
  const a = modelFromArgv();
  if (a) return { model: a, source: "argv" };
  const e = process.env.ANTHROPIC_MODEL;
  if (e) return { model: stripSuffix(e), source: "env" };
  const s = modelFromSettings(input.cwd);
  if (s) return { model: s, source: "settings" };
  return { model: "unknown", source: "unknown" };
}

// 룰 파일 목록. 파일명 기준으로 사용자 디렉터리가 플러그인 디렉터리를 덮는다. 파일명 정렬.
function ruleFiles(): Map<string, string> {
  const byName = new Map<string, string>();
  for (const dir of [RULES_DIR, USER_RULES_DIR]) {
    if (!existsSync(dir)) continue;
    for (const name of readdirSync(dir)) {
      if (!name.endsWith(".md")) continue;
      const path = join(dir, name);
      if (statSync(path).isFile()) byName.set(name, path);
    }
  }
  return new Map([...byName.entries()].sort(([a], [b]) => (a < b ? -1 : a > b ? 1 : 0)));
}

// 모델에 매칭되는 룰 파일 경로들. 아무 것도 없으면 default.md.
function matchRules(model: string): string[] {
  const modelLc = model.toLowerCase();
  const matched: string[] = [];
  let defaultPath: string | null = null;
  for (const [name, path] of ruleFiles()) {
    const stem = name.slice(0, -3);
    if (stem === "default") {
      defaultPath = path;
      continue;
    }
    if (modelLc.includes(stem.toLowerCase())) matched.push(path);
  }
  if (matched.length === 0 && defaultPath) matched.push(defaultPath);
  return matched;
}

// 룰 파일들을 이어 붙인다. 각 파일 앞에 어느 파일인지 한 줄 남긴다.
function renderRules(paths: string[]): string {
  return paths.map((p) => `\n(gnothi rule: ${basename(p)})\n${readFileSync(p, "utf8")}\n`).join("");
}

function emit(event: string, ctx: string) {
  process.stdout.write(JSON.stringify({ hookSpecificOutput: { hookEventName: event, additionalContext: ctx } }) + "\n");
}

type State = { model: string; ruleset: string };

function stateFile(sid: string) {
  return join(STATE_DIR, sid || "nosid");
}

function loadState(sid: string): State {
  try {
    const [model = "", ruleset = ""] = readFileSync(stateFile(sid), "utf8").trimEnd().split("\t");
    return { model, ruleset };
  } catch {
    return { model: "", ruleset: "" };
  }
}

function saveState(sid: string, s: State) {
  mkdirSync(STATE_DIR, { recursive: true });
  writeFileSync(stateFile(sid), `${s.model}\t${s.ruleset}\n`);
}

// 오래 남은 상태 파일 정리 (SessionEnd 가 안 불린 세션)
function pruneState(days = 7) {
  if (!existsSync(STATE_DIR)) return;
  const cutoff = Date.now() - days * 86400_000;
  for (const name of readdirSync(STATE_DIR)) {
    const p = join(STATE_DIR, name);
    try {
      if (statSync(p).isFile() && statSync(p).mtimeMs < cutoff) unlinkSync(p);
    } catch {
      /* 무시 */
    }
  }
}

async function main() {
  if (process.env.GNOTHI_DISABLE === "1") return;

  let input: HookInput;
  try {
    input = JSON.parse(await Bun.stdin.text());
  } catch {
    return;
  }
  const event = input.hook_event_name;
  if (!event) return;

  // 서브에이전트 안에서 도는 훅은 건너뛴다. 서브에이전트는 자기 컨텍스트가 따로 있고 세션 주인이 아니다.
  if (input.agent_id) return;

  const sid = input.session_id || process.env.CLAUDE_CODE_SESSION_ID || "";

  if (event === "SessionStart") {
    pruneState();
    const { model, source } = resolveModel(input);
    const rules = matchRules(model);
    saveState(sid, { model, ruleset: rules.join(",") });

    let ctx = `current session_id: ${sid || "unknown"}\ncurrent model: ${model} (via ${source})`;
    // hook/transcript 는 실제로 답한(답할) 모델이다. 나머지는 추정이라, 시스템 프롬프트의 모델 ID 가 다르면 그쪽이 맞다.
    // 2.1.270 실측: `--model haiku` 로 띄운 세션이 실제로는 claude-opus-5 로 답했다 (argv 만 믿으면 틀린다).
    if (!VERIFIED_SOURCES.includes(source)) {
      ctx += `\n(gnothi: 위 model 은 ${source} 에서 읽은 추정값이다. 시스템 프롬프트의 모델 ID 와 다르면 시스템 프롬프트가 맞다. 첫 응답 뒤부터는 실제로 답한 모델로 룰을 다시 준다.)`;
    }
    ctx += renderRules(rules);
    emit(event, ctx);
    return;
  }

  if (event === "UserPromptSubmit") {
    const model = modelFromTranscript(input.transcript_path);
    if (!model) return;
    const rules = matchRules(model);
    const ruleset = rules.join(",");
    const prev = loadState(sid);

    if (ruleset !== prev.ruleset) {
      saveState(sid, { model, ruleset });
      emit(event, `current model: ${model} (switched from ${prev.model || "unknown"}; via transcript)` + renderRules(rules));
      return;
    }
    if (model !== prev.model) {
      saveState(sid, { model, ruleset });
      // 별칭이 실제 id 로 구체화된 것(opus → claude-opus-5)이면 조용히 넘어간다. 진짜 바뀐 것만 알린다.
      const refined = prev.model && prev.model !== "unknown" && model.toLowerCase().includes(prev.model.toLowerCase());
      if (refined) return;
      emit(event, `current model: ${model} (switched from ${prev.model || "unknown"}; via transcript)`);
    }
    return;
  }

  if (event === "SessionEnd") {
    rmSync(stateFile(sid), { force: true });
  }
}

await main();
