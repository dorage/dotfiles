// 두 번의 평가 결과(aggregate-result.json)를 case 별로 비교해 통과·경고·회귀를 판정한다.
//
// 사용법
//   npx tsx compare.ts <새 aggregate.json> <이전 aggregate.json>
//   npx tsx compare.ts blind <벤치마크 폴더>
//
// 종료 코드: 0 = 회귀 없음, 1 = 회귀 있음, 2 = 부분 결과라 판정하지 않음
//
// aggregate-result.json 의 모양은 공개 문서가 없어 Claude Code 2.1.316 바이너리에서 읽은 것이다.
// 모르는 필드는 무시하고, 없는 필드는 빈 값으로 본다.

import { existsSync, readFileSync, statSync } from "node:fs";
import { join } from "node:path";
import { pathToFileURL } from "node:url";

export type Verdict = "통과" | "경고" | "회귀";

export interface GraderResult {
  name: string;
  passed: boolean;
  scored?: boolean;
  withOnly?: boolean;
  explanation?: string;
}

export interface RunResult {
  score?: number;
  error?: string | null;
  tracePath?: string;
  graders: GraderResult[];
}

export interface CaseSummary {
  name: string;
  runs: number;
  passes: number;
  /** regex·file_exists 채점기가 한 번이라도 떨어진 채점기 이름 */
  hardFailures: string[];
  /** baseline 채점기가 통과한 실행 수. 판정에는 쓰지 않고 참고로만 보여 준다 */
  baselinePasses: number;
}

export interface AggregateSummary {
  partial: boolean;
  version?: string;
  cases: Map<string, CaseSummary>;
}

// 아래 셋은 aggregate-result.json 에서 읽는 부분만 적은 느슨한 모양이다.
interface RawGrader {
  name?: unknown;
  type?: unknown;
  passed?: unknown;
  scored?: unknown;
  withOnly?: unknown;
  explanation?: unknown;
}
interface RawCase {
  name?: unknown;
  graders?: RawGrader[];
  arms?: { with?: RawRun[] };
}
interface RawRun {
  score?: unknown;
  error?: unknown;
  tracePath?: unknown;
  graders?: RawGrader[];
}

/** 이름이 baseline 이거나 종류가 baseline 인 채점기. 실행 통과 판정에서 뺀다 */
export function isBaselineGrader(name: string, type?: string): boolean {
  return type === "baseline" || name === "baseline";
}

/**
 * 회귀를 바로 부르는 채점기인지 본다.
 * case 정의에 종류(type)가 있으면 그것으로, 없으면 이름 규칙(regex-…, file-…)으로 판단한다.
 */
export function isHardGrader(name: string, type?: string): boolean {
  if (type) return type === "regex" || type === "file_exists";
  return name.startsWith("regex-") || name.startsWith("file-");
}

/**
 * 실행 하나가 통과했는지 본다.
 * baseline 채점기를 뺀 나머지가 모두 통과해야 통과다. baseline 은 기준 파일에 따라 결과가 달라져서
 * 그 결과를 다음 비교의 기준으로 쓰면 앞선 결과가 뒤 결과를 끌어내리는 순환이 생기기 때문이다.
 * 채점기가 하나도 없는 실행(오류로 끝난 실행)은 실패다.
 */
export function runPassed(run: RunResult, types: Map<string, string> = new Map()): boolean {
  if (run.error) return false;
  const judged = run.graders.filter(
    (g) => g.scored !== false && !isBaselineGrader(g.name, types.get(g.name)),
  );
  if (judged.length === 0) return false;
  return judged.every((g) => g.passed);
}

function str(v: unknown): string | undefined {
  return typeof v === "string" ? v : undefined;
}

function toGrader(g: RawGrader): GraderResult | null {
  const name = str(g.name);
  if (!name) return null;
  return {
    name,
    passed: g.passed === true,
    scored: typeof g.scored === "boolean" ? g.scored : undefined,
    withOnly: typeof g.withOnly === "boolean" ? g.withOnly : undefined,
    explanation: str(g.explanation),
  };
}

export function toRun(r: RawRun): RunResult {
  return {
    score: typeof r.score === "number" ? r.score : undefined,
    error: str(r.error) ?? null,
    tracePath: str(r.tracePath),
    graders: (r.graders ?? []).map(toGrader).filter((g): g is GraderResult => g !== null),
  };
}

/** case 정의의 채점기 이름 → 종류 */
export function graderTypes(c: RawCase): Map<string, string> {
  const m = new Map<string, string>();
  for (const g of c.graders ?? []) {
    const name = str(g.name);
    const type = str(g.type);
    if (name && type) m.set(name, type);
  }
  return m;
}

export function summarizeCase(c: RawCase): CaseSummary {
  const name = str(c.name) ?? "(이름 없음)";
  const types = graderTypes(c);
  const runs = (c.arms?.with ?? []).map(toRun);
  const hard = new Set<string>();
  let passes = 0;
  let baselinePasses = 0;
  for (const run of runs) {
    if (runPassed(run, types)) passes++;
    for (const g of run.graders) {
      const type = types.get(g.name);
      if (isBaselineGrader(g.name, type) && g.passed) baselinePasses++;
      if (!g.passed && isHardGrader(g.name, type)) hard.add(g.name);
    }
  }
  return { name, runs: runs.length, passes, hardFailures: [...hard].sort(), baselinePasses };
}

export function summarize(raw: unknown): AggregateSummary {
  const obj = (raw ?? {}) as {
    partial?: unknown;
    cases?: RawCase[];
    suite?: { plugins?: { name?: unknown; version?: unknown }[] };
  };
  const cases = new Map<string, CaseSummary>();
  for (const c of obj.cases ?? []) {
    const s = summarizeCase(c);
    cases.set(s.name, s);
  }
  const plugin = (obj.suite?.plugins ?? []).find((p) => p.name === "sdd") ?? obj.suite?.plugins?.[0];
  return { partial: obj.partial === true, version: str(plugin?.version), cases };
}

/**
 * case 하나의 판정.
 * - 새 실행에서 regex·file_exists 채점기가 한 번이라도 떨어지면 회귀
 * - 이전과 같거나 나아지면 통과, 실행 1번만큼 떨어지면 경고, 2번 이상 떨어지면 회귀
 * - 실행 수가 다르면 이전 통과 수를 새 실행 수에 맞춰 비례로 바꾼 뒤 잰다
 * - 이전 결과가 없는 새 case 는 regex·file_exists 만 본다
 */
export function verdictFor(oldCase: CaseSummary | undefined, newCase: CaseSummary): Verdict {
  if (newCase.hardFailures.length > 0) return "회귀";
  if (!oldCase || oldCase.runs === 0) return "통과";
  const expected =
    oldCase.runs === newCase.runs
      ? oldCase.passes
      : Math.round((oldCase.passes / oldCase.runs) * newCase.runs);
  const drop = expected - newCase.passes;
  if (drop <= 0) return "통과";
  if (drop === 1) return "경고";
  return "회귀";
}

export interface CompareRow {
  name: string;
  old: string;
  new: string;
  verdict: Verdict;
  note: string;
}

export interface CompareResult {
  partial: boolean;
  rows: CompareRow[];
  exitCode: 0 | 1 | 2;
}

export function compareAggregates(newRaw: unknown, oldRaw: unknown): CompareResult {
  const n = summarize(newRaw);
  const o = summarize(oldRaw);
  if (n.partial || o.partial) return { partial: true, rows: [], exitCode: 2 };
  const rows: CompareRow[] = [];
  for (const [name, nc] of [...n.cases].sort(([a], [b]) => a.localeCompare(b))) {
    const oc = o.cases.get(name);
    const verdict = verdictFor(oc, nc);
    const notes: string[] = [];
    if (!oc) notes.push("이전 결과 없음");
    if (nc.hardFailures.length > 0) notes.push(`규칙 위반: ${nc.hardFailures.join(", ")}`);
    notes.push(`baseline ${nc.baselinePasses}/${nc.runs}`);
    rows.push({
      name,
      old: oc ? `${oc.passes}/${oc.runs}` : "-",
      new: `${nc.passes}/${nc.runs}`,
      verdict,
      note: notes.join(" · "),
    });
  }
  const exitCode = rows.some((r) => r.verdict === "회귀") ? 1 : 0;
  return { partial: false, rows, exitCode };
}

export function formatTable(rows: CompareRow[]): string {
  const head = ["case", "이전", "새", "판정", "메모"];
  const body = rows.map((r) => [r.name, r.old, r.new, r.verdict, r.note]);
  const lines = [head, head.map(() => "---"), ...body].map((cells) => `| ${cells.join(" | ")} |`);
  return lines.join("\n");
}

/** 블라인드 비교 판정: 새 버전이 이긴 수가 진 수 이상이면 통과 (4:4 통과, 3:5 회귀). 비긴 것은 세지 않는다 */
export function blindVerdict(wins: number, losses: number): Verdict {
  return wins >= losses ? "통과" : "회귀";
}

export interface BlindTally {
  wins: number;
  losses: number;
  ties: number;
  missing: string[];
}

/**
 * 벤치마크 폴더의 blind/key.json 과 blind/eval-*\/run-*\/comparison.json 을 읽어 새 버전의 승패를 센다.
 * key.json 모양: { "eval-1/run-1": { "A": "new", "B": "old" }, ... }
 * comparison.json 은 skill-creator agents/comparator.md 의 출력이다 ({ "winner": "A" | "B" | "TIE", ... }).
 */
export function tallyBlind(benchmarkDir: string): BlindTally {
  const blindDir = join(benchmarkDir, "blind");
  const key = JSON.parse(readFileSync(join(blindDir, "key.json"), "utf8")) as Record<
    string,
    { A: string; B: string }
  >;
  const t: BlindTally = { wins: 0, losses: 0, ties: 0, missing: [] };
  for (const [slot, sides] of Object.entries(key)) {
    const file = join(blindDir, slot, "comparison.json");
    if (!existsSync(file)) {
      t.missing.push(slot);
      continue;
    }
    const winner = String((JSON.parse(readFileSync(file, "utf8")) as { winner?: unknown }).winner ?? "")
      .trim()
      .toUpperCase();
    if (winner !== "A" && winner !== "B") {
      t.ties++;
      continue;
    }
    if (sides[winner] === "new") t.wins++;
    else t.losses++;
  }
  return t;
}

function readJson(path: string): unknown {
  return JSON.parse(readFileSync(path, "utf8"));
}

function main(argv: string[]): number {
  if (argv[0] === "blind") {
    const dir = argv[1];
    if (!dir || !existsSync(dir) || !statSync(dir).isDirectory()) {
      console.error("사용법: npx tsx compare.ts blind <벤치마크 폴더>");
      return 2;
    }
    const t = tallyBlind(dir);
    if (t.missing.length > 0) {
      console.log(`부분 결과: comparison.json 이 없는 자리 ${t.missing.length}개 (${t.missing.join(", ")})`);
      return 2;
    }
    const v = blindVerdict(t.wins, t.losses);
    console.log(`블라인드 비교: 새 버전 ${t.wins}승 ${t.losses}패 ${t.ties}무 → ${v}`);
    return v === "회귀" ? 1 : 0;
  }
  const [newPath, oldPath] = argv;
  if (!newPath || !oldPath) {
    console.error("사용법: npx tsx compare.ts <새 aggregate.json> <이전 aggregate.json>");
    return 2;
  }
  const result = compareAggregates(readJson(newPath), readJson(oldPath));
  if (result.partial) {
    console.log("부분 결과: 비용 한도나 중단으로 끝나지 않은 평가라 판정하지 않습니다.");
    return 2;
  }
  console.log(formatTable(result.rows));
  console.log(result.exitCode === 1 ? "\n회귀가 있습니다." : "\n회귀가 없습니다.");
  return result.exitCode;
}

export { main as compareMain };

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  process.exitCode = main(process.argv.slice(2));
}
