// case.yaml 이 규칙대로 쓰였는지, 골든 문서가 그 regex 규칙을 스스로 통과하는지 본다.
// YAML 라이브러리를 쓰지 않으려고, 이 폴더 case.yaml 의 고정된 모양(2칸 들여쓴 "- type:" 블록)만 읽는다.
import { test } from "node:test";
import assert from "node:assert/strict";
import { existsSync, readFileSync } from "node:fs";
import { dirname, join, relative, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { listCases } from "./run.ts";

const evalsDir = dirname(fileURLToPath(import.meta.url));
const pluginDir = dirname(evalsDir);
const golden = (f: string) => readFileSync(join(evalsDir, "_fixtures", f), "utf8");

type Grader = Record<string, string>;

function unquote(v: string): string {
  const t = v.trim();
  if (t.startsWith("'") && t.endsWith("'")) return t.slice(1, -1).replace(/''/g, "'");
  return t;
}

function parseGraders(yaml: string): Grader[] {
  const out: Grader[] = [];
  let cur: Grader | null = null;
  let inGraders = false;
  for (const line of yaml.split("\n")) {
    if (/^graders:\s*$/.test(line)) {
      inGraders = true;
      continue;
    }
    if (inGraders && /^\S/.test(line)) inGraders = false;
    if (!inGraders) continue;
    const start = /^  - type: (\S+)\s*$/.exec(line);
    if (start) {
      cur = { type: start[1] };
      out.push(cur);
      continue;
    }
    const kv = /^    (\w+): (.*)$/.exec(line);
    if (cur && kv) cur[kv[1]] = unquote(kv[2]);
  }
  return out;
}

const cases = [...listCases(evalsDir).values()];

function graderSet(skill: string): Grader[] {
  const info = cases.find((c) => c.skill === skill);
  assert.ok(info, `${skill} case 가 없습니다`);
  return parseGraders(readFileSync(join(info.dir, "case.yaml"), "utf8"));
}

/** 하나의 regex 채점기를 글에 대 본다. claude plugin eval 과 같이 count 는 g 를 붙여 센다 */
function check(g: Grader, text: string): boolean {
  const flags = g.flags ?? "";
  const re = new RegExp(g.pattern, flags);
  const match = g.match ?? "contains";
  if (match === "contains") return re.test(text);
  if (match === "not_contains") return !re.test(text);
  const n = Number(match.slice("count:".length));
  const all = text.match(new RegExp(g.pattern, flags.includes("g") ? flags : flags + "g")) ?? [];
  return all.length === n;
}

for (const info of cases) {
  test(`${info.name}: case.yaml 모양`, () => {
    const yaml = readFileSync(join(info.dir, "case.yaml"), "utf8");
    assert.match(yaml, /^schema_version: "1"$/m);
    assert.match(yaml, /^runs: 3$/m);
    assert.ok(existsSync(join(info.dir, "scaffold.sh")), "scaffold.sh 가 없습니다");
    assert.match(yaml, new RegExp(`/sdd:${info.skill} `), "프롬프트가 /sdd:{스킬} 로 시작하지 않습니다");
    const graders = parseGraders(yaml);
    assert.ok(graders.length >= 5);
    const names = graders.map((g) => g.name);
    assert.equal(new Set(names).size, names.length, "채점기 이름이 겹칩니다");
    for (const g of graders) {
      assert.ok(g.name, "이름 없는 채점기");
      if (g.type === "regex") assert.doesNotThrow(() => new RegExp(g.pattern, g.flags ?? ""), g.name);
      if (g.type === "regex") assert.ok(g.name.startsWith("regex-"), g.name);
      if (g.type === "file_exists") assert.ok(g.name.startsWith("file-"), g.name);
      // min 을 비우면 1 로 채워져 max: 0 과 함께 늘 떨어진다
      if (g.type === "tool_used" && g.max === "0") assert.equal(g.min, "0", `${g.name}: min: 0 이 필요합니다`);
      if (g.type === "baseline") {
        const file = resolve(info.dir, g.baseline_file);
        assert.ok(existsSync(file), `${g.name}: ${g.baseline_file} 가 없습니다`);
        assert.ok(!relative(pluginDir, file).startsWith(".."), "baseline_file 이 플러그인 밖입니다");
        assert.equal(file, join(evalsDir, "baseline", "current", "traces", `${info.skill}.jsonl`));
      }
    }
    assert.ok(graders.some((g) => g.type === "tool_used" && g.tool === "AskUserQuestion" && g.arm === "both"));
    assert.equal(graders.filter((g) => g.type === "llm").length, 2);
    // 기준 trace 가 아직 없는 새 스킬 case 는 baseline 채점기를 두지 않는다. --save-baseline 뒤에 더한다
    const hasTrace = existsSync(join(evalsDir, "baseline", "current", "traces", `${info.skill}.jsonl`));
    assert.equal(graders.filter((g) => g.type === "baseline").length, hasTrace ? 1 : 0);
  });
}

test("골든 requirements.md 가 draft regex 규칙을 통과한다 (닫힌 문서라 추천안 규칙은 뺀다)", () => {
  const text = golden("requirements.md");
  for (const g of graderSet("draft").filter((g) => g.type === "regex" && g.name !== "regex-recommendation-shape")) {
    assert.ok(check(g, text), `${g.name} 실패`);
  }
});

test("draft 추천안 규칙이 열린 결정 모양을 잡는다", () => {
  const g = graderSet("draft").find((g) => g.name === "regex-recommendation-shape")!;
  assert.ok(check(g, "    - 추천안: @초안 a안 — 잔마다 세면 계산이 쉽다"));
  assert.ok(check(g, "    - @미정 — 분담 비율은 계약 조건이다"));
  assert.ok(!check(g, golden("requirements.md")));
});

test("EARS 마커 규칙이 마커 없는 인수 조건을 잡는다", () => {
  const g = graderSet("draft").find((g) => g.name === "regex-ears-has-marker")!;
  assert.ok(!check(g, "1. WHEN 결제하면, THE System SHALL 할인한다."));
  assert.ok(check(g, "1. WHEN 결제하면, THE System SHALL 할인한다. @초안 (A1)"));
});

test("골든 requirements.md 가 persona-review regex 규칙을 통과한다", () => {
  const text = golden("requirements.md");
  for (const g of graderSet("persona-review").filter((g) => g.type === "regex")) {
    assert.ok(check(g, text), g.name);
  }
});

test("persona-review 규칙이 검토 기록이 없거나 맨 끝이 아닌 문서를 잡는다", () => {
  const gs = graderSet("persona-review");
  const log = gs.find((g) => g.name === "regex-review-log")!;
  const last = gs.find((g) => g.name === "regex-review-log-last")!;
  const text = golden("requirements.md");
  // scaffold.sh 가 지우는 것과 같은 모양: 검토 기록 절을 뺀 입력
  const staged = text.replace(/\n+## 참여자별 검토 기록\n[\s\S]*$/, "\n");
  assert.ok(!check(log, staged), "검토 기록이 없는 입력을 통과시켰습니다");
  assert.ok(!check(last, text + "\n## 덧붙인 절\n"), "검토 기록 뒤의 절을 놓쳤습니다");
});

test("draft 규칙이 persona-review 를 부르지 않은 문서를 잡는다", () => {
  const g = graderSet("draft").find((g) => g.name === "regex-persona-review-called")!;
  const text = golden("requirements.md");
  assert.ok(check(g, text));
  assert.ok(!check(g, text.replace(/## 참여자별 검토 기록/, "## 다른 절")));
});

test("골든 design.md 가 design regex 규칙을 통과한다", () => {
  const text = golden("design.md");
  for (const g of graderSet("design").filter((g) => g.type === "regex")) {
    assert.ok(check(g, text), `${g.name} 실패`);
  }
});

test("design 규칙이 -> 없는 결정 제목과 6번째 결정을 잡는다", () => {
  const gs = graderSet("design");
  const arrow = gs.find((g) => g.name === "regex-decision-has-arrow")!;
  assert.ok(!check(arrow, "- **S1. 테이블을 나눌지**\n"));
  const max = gs.find((g) => g.name === "regex-group-max-5")!;
  assert.ok(!check(max, "- *S6. 캐시를 쓴다* ->"));
});

test("brief 의 줄 수 규칙이 골든 요구사항 문서의 번호 줄·헤딩 수와 같다", () => {
  // brief 는 「참여자별 검토 기록」 절을 옮기지 않는다 (references/brief-format.md 「변환 원칙」)
  const text = golden("requirements.md").replace(/\n+## 참여자별 검토 기록\n[\s\S]*$/, "\n");
  for (const skill of ["brief-dev", "brief-nondev"]) {
    for (const g of graderSet(skill).filter((g) => g.match?.startsWith("count:"))) {
      assert.ok(check(g, text), `${skill} ${g.name}: 골든 문서와 수가 다릅니다`);
    }
  }
});

test("brief 규칙은 골든 요구사항 문서(마커가 있는 원본)를 떨어뜨린다", () => {
  const text = golden("requirements.md");
  const dev = graderSet("brief-dev");
  assert.ok(!check(dev.find((g) => g.name === "regex-no-markers")!, text));
  assert.ok(!check(dev.find((g) => g.name === "regex-no-marker-column")!, text));
  // 원본은 「필요한 결정」이 맨 위이고 `---` 가 없어 brief 절 순서를 떨어진다
  assert.ok(!check(dev.find((g) => g.name === "regex-section-order")!, text));
  const nondev = graderSet("brief-nondev");
  assert.ok(!check(nondev.find((g) => g.name === "regex-section-order")!, text));
  // 요구사항 문서는 경로를 적지 않는다 (references/draft.md 「이 문서의 수준」). 경로가 섞인 글로 규칙을 확인한다
  const path = nondev.find((g) => g.name === "regex-no-code-path")!;
  assert.ok(check(path, text), "골든 요구사항 문서에 코드 경로가 남아 있습니다");
  assert.ok(!check(path, text + "\n- 결제는 `src/order/checkout.ts` 에서 계산한다\n"));
  const inline = nondev.find((g) => g.name === "regex-no-inline-code")!;
  assert.ok(check(inline, text), "골든 요구사항 문서에 코드 조각이 남아 있습니다");
  assert.ok(!check(inline, text + "\n- 결제는 `checkout()` 에서 계산한다\n"));
  assert.ok(check(nondev.find((g) => g.name === "regex-no-inline-code")!, "```mermaid\nflowchart LR\n```\n"));
});

test("bdd 규칙이 올바른 feature 를 통과시키고 태그 없는 시나리오를 잡는다", () => {
  const good = [
    "# language: ko",
    "기능: 임직원의 주문 할인",
    "",
    "  @결정",
    "  시나리오: 인증된 임직원이 라떼 2잔을 사면 3,000원이 할인된다",
    "    만약 임직원이 5,900원 라떼 2잔을 결제한다",
    "    그러면 결제 금액은 8,800원이다",
    "",
    "  @초안",
    "  시나리오 개요: 인증하지 않은 사람은 정가로 결제한다",
    "    그러면 결제 금액은 11,800원이다",
  ].join("\n");
  const bad = good.replace("  @초안\n", "");
  const gs = graderSet("bdd").filter((g) => g.type === "regex" && g.target !== "files");
  for (const g of gs) assert.ok(check(g, good), `${g.name} 이 올바른 feature 를 떨어뜨립니다`);
  const every = gs.find((g) => g.name === "regex-every-scenario-tagged")!;
  assert.ok(!check(every, bad));
  const names = graderSet("bdd").find((g) => g.name === "regex-kebab-file-names")!;
  assert.ok(check(names, "out/features/order/customer-pays-order.feature\nout/features-all.txt"));
  assert.ok(!check(names, "out/features/Customer_Pays.feature"));
});

test("draft 규칙이 요구사항 문서의 코드 경로를 잡는다", () => {
  const g = graderSet("draft").find((g) => g.name === "regex-no-code-path")!;
  const text = golden("requirements.md");
  assert.ok(check(g, text));
  assert.ok(!check(g, text + "\n- 결제는 `src/order/checkout.ts` 에서 계산한다\n"));
  assert.ok(!check(g, text + "\n- `in_house_service.py` 가 인증한다\n"));
});

test("references/flow.md 견본이 flow regex 규칙을 통과한다", () => {
  const ref = readFileSync(join(pluginDir, "references", "flow.md"), "utf8");
  const sample = /````markdown\n([\s\S]*?)\n````/.exec(ref);
  assert.ok(sample, "references/flow.md 에 견본이 없습니다");
  for (const g of graderSet("flow").filter((g) => g.type === "regex")) {
    assert.ok(check(g, sample[1]), `${g.name} 실패`);
  }
});

test("flow 결정 문자 규칙이 다른 문서의 결정 문자를 잡는다", () => {
  const g = graderSet("flow").find((g) => g.name === "regex-decision-letters")!;
  assert.ok(!check(g, "- **S1. 정산 탭을 어디에 둘지** ->"));
  assert.ok(check(g, "- **M1. 정산 탭을 어디에 둘지** ->"));
});
