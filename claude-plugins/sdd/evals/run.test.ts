// run.ts 의 순수 함수 테스트. 실제 평가(claude plugin eval)는 돌리지 않는다
import { test } from "node:test";
import assert from "node:assert/strict";
import { existsSync, mkdirSync, mkdtempSync, readFileSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { buildBenchmark, classifyVersionChange, evalArgs, listCases, parseArgs, parseKeptRoots } from "./run.ts";

const here = dirname(fileURLToPath(import.meta.url));

test("블라인드 비교용 폴더를 skill-creator 모양으로 만든다", () => {
  const load = (f: string) => JSON.parse(readFileSync(join(here, "test-fixtures", f), "utf8"));
  const tmp = mkdtempSync(join(tmpdir(), "sdd-bench-"));
  const newRuns = join(tmp, "new-runs");
  mkdirSync(join(newRuns, "same", "run-1", "out"), { recursive: true });
  writeFileSync(join(newRuns, "same", "run-1", "out", "requirements.md"), "# 새 문서\n");
  const bench = join(tmp, "benchmark");
  const slots = buildBenchmark(bench, {
    new: { aggregate: load("aggregate-new.json"), runsDir: newRuns },
    old: { aggregate: load("aggregate-old.json"), runsDir: join(tmp, "old-runs") },
  });
  // case 이름 순: better, brand-new, hard, regress, same, warn → same 은 eval-5. brand-new 는 이전 결과가 없어 자리가 없다
  assert.equal(slots.length, 5 * 3);
  const meta = JSON.parse(readFileSync(join(bench, "eval-5", "eval_metadata.json"), "utf8"));
  assert.equal(meta.eval_name, "same");
  const grading = JSON.parse(readFileSync(join(bench, "eval-5", "new_skill", "run-2", "grading.json"), "utf8"));
  assert.deepEqual(grading.summary, { passed: 3, failed: 1, total: 4, pass_rate: 0.75 });
  assert.equal(grading.expectations[0].text, "file-output");
  assert.ok(existsSync(join(bench, "eval-5", "new_skill", "run-1", "outputs", "requirements.md")));
  assert.ok(existsSync(join(bench, "eval-5", "old_skill", "run-1", "grading.json")));
  const key = JSON.parse(readFileSync(join(bench, "blind", "key.json"), "utf8"));
  const side = key["eval-5/run-1"].A === "new" ? "A" : "B";
  assert.ok(existsSync(join(bench, "blind", "eval-5", "run-1", side, "requirements.md")));
});

test("셋째 자리만 바뀌면 패치 (0.4.2 → 0.4.3)", () => assert.equal(classifyVersionChange("0.4.2", "0.4.3"), "patch"));
test("둘째 자리가 바뀌면 전체 (0.4.2 → 0.5.0)", () => assert.equal(classifyVersionChange("0.4.2", "0.5.0"), "full"));
test("첫째 자리가 바뀌면 전체 (0.9.1 → 1.0.0)", () => assert.equal(classifyVersionChange("0.9.1", "1.0.0"), "full"));
test("기준이 없으면 첫 실행", () => assert.equal(classifyVersionChange(undefined, "0.5.0"), "first"));

test("kept temp 줄에서 실행 폴더를 뽑는다", () => {
  const stderr = [
    "  scaffold: /x/scaffold.sh",
    "  kept temp: /tmp/e-abc123",
    "  kept temp (run failed): /tmp/e-def456",
    "  kept temp: /tmp/e-abc123",
  ].join("\n");
  assert.deepEqual(parseKeptRoots(stderr), ["/tmp/e-abc123", "/tmp/e-def456"]);
});

test("옵션을 읽고 eval 인자로 넘긴다", () => {
  const o = parseArgs(["--runs", "1", "-j", "2", "--case", "draft-*", "--save-baseline"]);
  assert.equal(o.saveBaseline, true);
  const args = evalArgs("/p", "/out", o);
  assert.deepEqual(args.slice(0, 3), ["plugin", "eval", "/p"]);
  for (const flag of ["--scaffold", "--keep-temp", "--no-publish"]) assert.ok(args.includes(flag));
  assert.deepEqual(args.slice(-6), ["--runs", "1", "-j", "2", "--case", "draft-*"]);
  assert.throws(() => parseArgs(["--nope"]));
});

test("case 아홉 개를 스킬 이름과 함께 찾는다", () => {
  const cases = listCases(dirname(fileURLToPath(import.meta.url)));
  assert.deepEqual(
    [...cases.values()].map((c) => c.skill).sort(),
    ["bdd", "brief-dev", "brief-nondev", "design", "draft", "flow", "persona-review", "quick", "task"],
  );
});
