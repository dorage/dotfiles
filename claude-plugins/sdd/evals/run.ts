// sdd 플러그인 평가를 돌리고, 이전 버전과 비교해 회귀를 찾는다.
//
// 사용법 (리포 루트에서)
//   npx tsx claude-plugins/sdd/evals/run.ts [--base <commit>] [--save-baseline] [--runs N] [-j N] [--case <glob>]
//
// - 지금 버전은 .claude-plugin/plugin.json, 이전 버전은 baseline/current/meta.json 에서 읽는다
// - 셋째 자리만 바뀌면 패치 모드: 지금 버전만 돌리고 baseline/current/aggregate.json 과 비교한다
// - 첫째·둘째 자리가 바뀌면 전체 모드: 이전 커밋을 임시 워크트리로 꺼내 두 버전을 모두 돌리고 비교한다
// - meta.json 이 없으면 첫 실행으로 보고 비교 없이 돌리기만 한다
// - --save-baseline 을 주면 이번 결과를 다음 비교의 기준으로 저장한다
//
// 종료 코드는 compare.ts 와 같다: 0 회귀 없음, 1 회귀 있음, 2 부분 결과·실행 실패

import { spawn, spawnSync } from "node:child_process";
import {
  copyFileSync,
  cpSync,
  existsSync,
  mkdirSync,
  mkdtempSync,
  readdirSync,
  readFileSync,
  rmSync,
  statSync,
  writeFileSync,
} from "node:fs";
import { tmpdir } from "node:os";
import { basename, dirname, join, relative, resolve } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";
import { compareAggregates, formatTable, runPassed, toRun, graderTypes } from "./compare.ts";

// ---------- 순수 함수 (테스트 대상) ----------

export type Mode = "first" | "patch" | "full";

function parseVersion(v: string): [number, number, number] {
  const m = /^(\d+)\.(\d+)\.(\d+)/.exec(v.trim());
  if (!m) throw new Error(`버전 모양이 x.y.z 가 아닙니다: ${v}`);
  return [Number(m[1]), Number(m[2]), Number(m[3])];
}

/** 이전 → 지금 버전으로 모드를 정한다. 셋째 자리만 바뀌면 patch, 첫째·둘째가 바뀌면 full, 이전이 없으면 first */
export function classifyVersionChange(previous: string | undefined, current: string): Mode {
  if (!previous) return "first";
  const [pa, pb] = parseVersion(previous);
  const [ca, cb] = parseVersion(current);
  return pa === ca && pb === cb ? "patch" : "full";
}

export interface Options {
  base?: string;
  saveBaseline: boolean;
  runs?: string;
  concurrency?: string;
  caseGlob?: string;
}

export function parseArgs(argv: string[]): Options {
  const o: Options = { saveBaseline: false };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    const next = () => {
      const v = argv[++i];
      if (v === undefined) throw new Error(`${a} 뒤에 값이 필요합니다`);
      return v;
    };
    if (a === "--base") o.base = next();
    else if (a === "--save-baseline") o.saveBaseline = true;
    else if (a === "--runs") o.runs = next();
    else if (a === "-j" || a === "--concurrency") o.concurrency = next();
    else if (a === "--case") o.caseGlob = next();
    else throw new Error(`모르는 옵션: ${a}`);
  }
  return o;
}

/** claude plugin eval 에 넘길 인자. 셸 없이 배열로 넘긴다 */
export function evalArgs(pluginDir: string, outputDir: string, o: Options): string[] {
  const args = [
    "plugin",
    "eval",
    pluginDir,
    "--ablation",
    "none",
    "--scaffold",
    "--allow-tools",
    "Write",
    "Edit",
    "Bash",
    "Agent",
    "--judge-model",
    "sonnet",
    "--keep-temp",
    "--no-publish",
    "--output-dir",
    outputDir,
  ];
  if (o.runs) args.push("--runs", o.runs);
  if (o.concurrency) args.push("-j", o.concurrency);
  if (o.caseGlob) args.push("--case", o.caseGlob);
  return args;
}

/** stderr 에서 남겨 둔 실행 폴더(root) 경로를 뽑는다. "  kept temp: /tmp/e-XXXX" 또는 "kept temp (run failed): …" */
export function parseKeptRoots(stderr: string): string[] {
  const roots: string[] = [];
  for (const line of stderr.split(/\r?\n/)) {
    const m = /kept temp(?: \([^)]*\))?: (\S.*?)\s*$/.exec(line);
    if (m) roots.push(m[1]);
  }
  return [...new Set(roots)];
}

// ---------- 경로와 파일 ----------

const evalsDir = dirname(fileURLToPath(import.meta.url));
const pluginDir = dirname(evalsDir);
const baselineDir = join(evalsDir, "baseline", "current");
const skillCreatorDir = join(
  process.env.HOME ?? "",
  ".claude/plugins/marketplaces/claude-plugins-official/plugins/skill-creator/skills/skill-creator",
);

interface CaseInfo {
  name: string;
  skill: string;
  dir: string;
}

/** evals/{skill}/{case}/case.yaml 에서 name 줄만 읽어 case 이름 → 스킬·폴더를 만든다. YAML 전체를 읽지 않는다 */
export function listCases(root: string): Map<string, CaseInfo> {
  const m = new Map<string, CaseInfo>();
  for (const skill of readdirSync(root)) {
    const skillDir = join(root, skill);
    if (skill.startsWith("_") || skill.startsWith(".") || !statSync(skillDir).isDirectory()) continue;
    for (const c of readdirSync(skillDir)) {
      const file = join(skillDir, c, "case.yaml");
      if (!existsSync(file)) continue;
      const name = /^name:\s*(\S+)\s*$/m.exec(readFileSync(file, "utf8"))?.[1];
      if (name) m.set(name, { name, skill, dir: join(skillDir, c) });
    }
  }
  return m;
}

function readJson<T>(file: string): T {
  return JSON.parse(readFileSync(file, "utf8")) as T;
}

function git(cwd: string, args: string[]): string {
  const r = spawnSync("git", args, { cwd, encoding: "utf8" });
  if (r.status !== 0) throw new Error(`git ${args.join(" ")} 실패: ${r.stderr.trim()}`);
  return r.stdout.trim();
}

function pluginVersion(dir: string): string {
  return readJson<{ version: string }>(join(dir, ".claude-plugin", "plugin.json")).version;
}

interface Meta {
  version: string;
  commit: string;
  savedAt: string;
}

// ---------- 평가 실행 ----------

interface EvalOutcome {
  aggregatePath: string;
  aggregate: unknown;
  roots: string[];
}

function runEval(dir: string, outputDir: string, o: Options): Promise<EvalOutcome> {
  mkdirSync(outputDir, { recursive: true });
  const args = evalArgs(dir, outputDir, o);
  console.log(`\n$ claude ${args.join(" ")}\n`);
  return new Promise((resolvePromise, reject) => {
    // stdin 은 처음 실행할 때 나오는 신뢰 확인 질문에 답할 수 있게 그대로 잇는다
    const child = spawn("claude", args, { stdio: ["inherit", "inherit", "pipe"] });
    let stderr = "";
    child.stderr.on("data", (chunk: Buffer) => {
      process.stderr.write(chunk);
      stderr += chunk.toString("utf8");
    });
    child.on("error", reject);
    child.on("close", (code) => {
      const aggregatePath = join(outputDir, "aggregate-result.json");
      const roots = parseKeptRoots(stderr);
      if (!existsSync(aggregatePath)) {
        reject(new Error(`aggregate-result.json 이 없습니다 (종료 코드 ${code}): ${aggregatePath}`));
        return;
      }
      // 채점기가 떨어지면 0 이 아닌 코드로 끝날 수 있어서 종료 코드는 실패로 보지 않는다
      resolvePromise({ aggregatePath, aggregate: readJson(aggregatePath), roots });
    });
  });
}

/**
 * 남겨 둔 실행 폴더마다 결과 파일과 trace 를 runs/<case>/run-<n>/ 으로 옮기고 실행 폴더를 지운다.
 * 몇 번째 실행인지는 aggregate 의 tracePath 로 찾고, 못 찾으면 도착 순서로 붙인다.
 */
function collectRuns(roots: string[], aggregate: unknown, runsDir: string): void {
  const tracePaths = new Map<string, string[]>();
  for (const c of (aggregate as { cases?: { name?: string; arms?: { with?: { tracePath?: string }[] } }[] })
    .cases ?? []) {
    tracePaths.set(String(c.name), (c.arms?.with ?? []).map((r) => r.tracePath ?? ""));
  }
  const used = new Map<string, Set<number>>();
  for (const root of roots) {
    const cwd = join(root, "home", "cwd");
    const marker = join(cwd, ".eval-case");
    if (!existsSync(marker)) {
      console.warn(`case 를 알 수 없어 건너뜀: ${root}`);
      continue;
    }
    const caseName = readFileSync(marker, "utf8").trim();
    const taken = used.get(caseName) ?? new Set<number>();
    used.set(caseName, taken);
    const traces = tracePaths.get(caseName) ?? [];
    let n = traces.findIndex((p) => p !== "" && (p === root || p.startsWith(root + "/"))) + 1;
    if (n === 0 || taken.has(n)) {
      n = 1;
      while (taken.has(n)) n++;
    }
    taken.add(n);
    const dest = join(runsDir, caseName, `run-${n}`);
    mkdirSync(dest, { recursive: true });
    if (existsSync(join(cwd, "out"))) cpSync(join(cwd, "out"), join(dest, "out"), { recursive: true });
    const trace = join(root, "out", "trace.jsonl");
    if (existsSync(trace)) copyFileSync(trace, join(dest, "trace.jsonl"));
    // 지우는 대상은 claude plugin eval 이 만든 e-XXXX 폴더뿐이다
    if (basename(root).startsWith("e-") && existsSync(join(root, "home"))) {
      rmSync(root, { recursive: true, force: true });
    } else {
      console.warn(`모양이 낯선 실행 폴더라 지우지 않았습니다: ${root}`);
    }
  }
}

// ---------- 기준 저장 ----------

const BASELINE_TRACE_MAX_BYTES = 10 * 1024 * 1024;

function saveBaseline(version: string, outcome: EvalOutcome, runsDir: string): void {
  mkdirSync(join(baselineDir, "traces"), { recursive: true });
  const meta: Meta = { version, commit: git(pluginDir, ["rev-parse", "HEAD"]), savedAt: new Date().toISOString() };
  writeFileSync(join(baselineDir, "meta.json"), JSON.stringify(meta, null, 2) + "\n");
  copyFileSync(outcome.aggregatePath, join(baselineDir, "aggregate.json"));
  const dirty = git(pluginDir, ["status", "--porcelain", "--", "."]);
  if (dirty) console.warn("커밋하지 않은 변경이 있습니다. meta.json 의 commit 은 HEAD 라서 지금 파일과 다를 수 있습니다.");
  for (const info of listCases(evalsDir).values()) {
    const trace = join(runsDir, info.name, "run-1", "trace.jsonl");
    if (!existsSync(trace)) console.warn(`run-1 trace 가 없어 기준 trace 를 바꾸지 않았습니다: ${info.name}`);
    // baseline 채점기는 10MB 넘는 기준 파일을 읽지 못한다
    else if (statSync(trace).size > BASELINE_TRACE_MAX_BYTES)
      console.warn(`run-1 trace 가 10MB 를 넘어 기준 trace 를 바꾸지 않았습니다: ${info.name}`);
    else copyFileSync(trace, join(baselineDir, "traces", `${info.skill}.jsonl`));
  }
  console.log(`기준을 저장했습니다: ${relative(process.cwd(), baselineDir)} (버전 ${version})`);
}

// ---------- 블라인드 비교용 벤치마크 폴더 ----------

interface RawCaseLite {
  name?: string;
  promptMarkdown?: string;
  graders?: { name?: unknown; type?: unknown }[];
  arms?: { with?: unknown[] };
}

function gradingJson(rawRun: unknown, types: Map<string, string>): object {
  const run = toRun(rawRun as never);
  const expectations = run.graders.map((g) => ({
    text: g.name,
    passed: g.passed,
    evidence: g.explanation ?? "",
  }));
  const passed = expectations.filter((e) => e.passed).length;
  return {
    expectations,
    summary: {
      passed,
      failed: expectations.length - passed,
      total: expectations.length,
      pass_rate: expectations.length ? Number((passed / expectations.length).toFixed(4)) : 0,
    },
    run_passed: runPassed(run, types),
  };
}

/**
 * skill-creator 의 aggregate_benchmark.py 가 읽는 모양으로 벤치마크 폴더를 만든다.
 *   benchmark/eval-<i>/eval_metadata.json
 *   benchmark/eval-<i>/new_skill/run-<n>/{grading.json, outputs/}
 *   benchmark/eval-<i>/old_skill/run-<n>/{grading.json, outputs/}
 *   benchmark/blind/eval-<i>/run-<n>/{A,B}/   ← 어느 쪽이 새 버전인지 감춘 사본
 *   benchmark/blind/key.json                  ← 정답표. 비교가 끝날 때까지 열지 않는다
 */
export function buildBenchmark(
  benchDir: string,
  sides: { new: { aggregate: unknown; runsDir: string }; old: { aggregate: unknown; runsDir: string } },
): string[] {
  const cases = new Map<string, { new?: RawCaseLite; old?: RawCaseLite }>();
  for (const side of ["new", "old"] as const) {
    for (const c of (sides[side].aggregate as { cases?: RawCaseLite[] }).cases ?? []) {
      const name = String(c.name);
      cases.set(name, { ...cases.get(name), [side]: c });
    }
  }
  const key: Record<string, { A: string; B: string }> = {};
  const names = [...cases.keys()].sort();
  names.forEach((name, idx) => {
    const evalName = `eval-${idx + 1}`;
    const evalDir = join(benchDir, evalName);
    const pair = cases.get(name)!;
    mkdirSync(evalDir, { recursive: true });
    writeFileSync(
      join(evalDir, "eval_metadata.json"),
      JSON.stringify(
        { eval_id: idx + 1, eval_name: name, prompt: pair.new?.promptMarkdown ?? pair.old?.promptMarkdown ?? "" },
        null,
        2,
      ) + "\n",
    );
    for (const side of ["new", "old"] as const) {
      const c = pair[side];
      if (!c) continue;
      const types = graderTypes(c as never);
      (c.arms?.with ?? []).forEach((rawRun, r) => {
        const runDir = join(evalDir, `${side}_skill`, `run-${r + 1}`);
        mkdirSync(runDir, { recursive: true });
        writeFileSync(join(runDir, "grading.json"), JSON.stringify(gradingJson(rawRun, types), null, 2) + "\n");
        const src = join(sides[side].runsDir, name, `run-${r + 1}`, "out");
        if (existsSync(src)) cpSync(src, join(runDir, "outputs"), { recursive: true });
      });
    }
    const runCount = Math.min(pair.new?.arms?.with?.length ?? 0, pair.old?.arms?.with?.length ?? 0);
    for (let r = 1; r <= runCount; r++) {
      const slot = `${evalName}/run-${r}`;
      const newIsA = Math.random() < 0.5;
      key[slot] = newIsA ? { A: "new", B: "old" } : { A: "old", B: "new" };
      for (const label of ["A", "B"] as const) {
        const side = key[slot][label];
        const src = join(evalDir, `${side}_skill`, `run-${r}`, "outputs");
        const dest = join(benchDir, "blind", slot, label);
        mkdirSync(dest, { recursive: true });
        if (existsSync(src)) cpSync(src, dest, { recursive: true });
      }
    }
  });
  mkdirSync(join(benchDir, "blind"), { recursive: true });
  writeFileSync(join(benchDir, "blind", "key.json"), JSON.stringify(key, null, 2) + "\n");
  return Object.keys(key);
}

function printBlindSteps(benchDir: string, slots: string[]): void {
  const rel = relative(process.cwd(), benchDir) || ".";
  console.log(`
## 블라인드 비교 다음 단계 (LLM 이 할 일)

- 자리 ${slots.length}개마다 하위 에이전트 하나로 ${skillCreatorDir}/agents/comparator.md 를 따르게 한다
    - output_a_path: ${rel}/blind/<eval-i>/<run-n>/A
    - output_b_path: ${rel}/blind/<eval-i>/<run-n>/B
    - eval_prompt: ${rel}/<eval-i>/eval_metadata.json 의 prompt
    - 결과는 ${rel}/blind/<eval-i>/<run-n>/comparison.json 에 쓴다
    - blind/key.json 은 비교가 모두 끝날 때까지 읽지 않는다
- 모두 끝나면 승패를 센다: npx tsx ${relative(process.cwd(), join(evalsDir, "compare.ts"))} blind ${rel}
- 점수 요약을 만든다: cd ${skillCreatorDir} && uv run python -m scripts.aggregate_benchmark ${resolve(benchDir)} --skill-name sdd
`);
}

// ---------- 메인 ----------

function printCompare(newAgg: unknown, oldAgg: unknown): 0 | 1 | 2 {
  const r = compareAggregates(newAgg, oldAgg);
  if (r.partial) {
    console.log("부분 결과: 끝나지 않은 평가가 섞여 있어 판정하지 않습니다.");
    return 2;
  }
  console.log(formatTable(r.rows));
  console.log(r.exitCode === 1 ? "\n회귀가 있습니다." : "\n회귀가 없습니다.");
  return r.exitCode;
}

async function main(argv: string[]): Promise<number> {
  const o = parseArgs(argv);
  // 일부 case 만 돌린 결과로 기준을 덮으면, 다음 비교에서 빠진 case 가 모두 "이전 결과 없음" 이 된다
  if (o.caseGlob && o.saveBaseline) throw new Error("case 를 걸러 낸 결과는 기준으로 저장하지 않습니다. --case 를 빼고 돌리세요.");
  const version = pluginVersion(pluginDir);
  const metaPath = join(baselineDir, "meta.json");
  const meta = existsSync(metaPath) ? readJson<Meta>(metaPath) : undefined;
  const mode = classifyVersionChange(meta?.version, version);
  const sha = git(pluginDir, ["rev-parse", "--short", "HEAD"]);
  const outDir = join(evalsDir, "results", `${version}-${sha}`);
  console.log(`버전 ${meta?.version ?? "(기준 없음)"} → ${version}: ${mode === "full" ? "전체" : mode === "patch" ? "패치" : "첫 실행"} 모드`);

  if (mode !== "full") {
    const cur = await runEval(pluginDir, outDir, o);
    collectRuns(cur.roots, cur.aggregate, join(outDir, "runs"));
    let code: number = 0;
    const basePath = join(baselineDir, "aggregate.json");
    if (mode === "patch" && existsSync(basePath)) code = printCompare(cur.aggregate, readJson(basePath));
    else console.log("비교할 기준 결과가 없어 돌리기만 했습니다. 결과를 검토한 뒤 --save-baseline 으로 기준을 저장하세요.");
    if (o.saveBaseline) saveBaseline(version, cur, join(outDir, "runs"));
    console.log(`결과: ${relative(process.cwd(), outDir)}`);
    return code;
  }

  const base = o.base ?? meta?.commit;
  if (!base) throw new Error("전체 모드인데 기준 커밋이 없습니다. --base <commit> 을 주세요.");
  const repoRoot = git(pluginDir, ["rev-parse", "--show-toplevel"]);
  const tmp = mkdtempSync(join(tmpdir(), "sdd-eval-base-"));
  git(repoRoot, ["worktree", "add", "--detach", tmp, base]);
  try {
    const oldPlugin = join(tmp, relative(repoRoot, pluginDir));
    const oldVersion = pluginVersion(oldPlugin);
    // 옛 버전에는 평가 case 가 없을 수 있어서 지금 case 를 옮겨 놓는다. 결과와 기준은 옮기지 않는다
    const oldEvals = join(oldPlugin, "evals");
    rmSync(oldEvals, { recursive: true, force: true });
    mkdirSync(oldEvals, { recursive: true });
    for (const entry of readdirSync(evalsDir)) {
      if (entry === "results" || entry === "baseline") continue;
      cpSync(join(evalsDir, entry), join(oldEvals, entry), { recursive: true });
    }
    // baseline 채점기가 읽을 파일만 빈 자리로 둔다
    mkdirSync(join(oldEvals, "baseline", "current", "traces"), { recursive: true });
    for (const info of listCases(evalsDir).values()) {
      writeFileSync(join(oldEvals, "baseline", "current", "traces", `${info.skill}.jsonl`), '{"type":"placeholder"}\n');
    }

    const cur = await runEval(pluginDir, outDir, o);
    collectRuns(cur.roots, cur.aggregate, join(outDir, "runs"));
    const oldOut = join(outDir, `old-${oldVersion}`);
    const old = await runEval(oldPlugin, oldOut, o);
    collectRuns(old.roots, old.aggregate, join(oldOut, "runs"));

    console.log(`\n## ${oldVersion} → ${version} 비교\n`);
    const code = printCompare(cur.aggregate, old.aggregate);
    const benchDir = join(outDir, "benchmark");
    const slots = buildBenchmark(benchDir, {
      new: { aggregate: cur.aggregate, runsDir: join(outDir, "runs") },
      old: { aggregate: old.aggregate, runsDir: join(oldOut, "runs") },
    });
    printBlindSteps(benchDir, slots);
    if (o.saveBaseline) saveBaseline(version, cur, join(outDir, "runs"));
    console.log(`결과: ${relative(process.cwd(), outDir)}`);
    return code;
  } finally {
    try {
      git(repoRoot, ["worktree", "remove", "--force", tmp]);
    } catch (e) {
      console.warn(`임시 워크트리를 지우지 못했습니다. 직접 지우세요: git worktree remove --force ${tmp} (${String(e)})`);
    }
  }
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  main(process.argv.slice(2)).then(
    (code) => {
      process.exitCode = code;
    },
    (e: unknown) => {
      console.error(e instanceof Error ? e.message : String(e));
      process.exitCode = 2;
    },
  );
}
