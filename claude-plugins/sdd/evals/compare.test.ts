// compare.ts 판정 규칙 테스트
import { test } from "node:test";
import assert from "node:assert/strict";
import { mkdirSync, mkdtempSync, readFileSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { blindVerdict, compareAggregates, summarize, tallyBlind, verdictFor, type CaseSummary } from "./compare.ts";

const fixtures = join(dirname(fileURLToPath(import.meta.url)), "test-fixtures");
const load = (f: string): unknown => JSON.parse(readFileSync(join(fixtures, f), "utf8"));
const c = (passes: number, runs = 3, hardFailures: string[] = []): CaseSummary => ({
  name: "x",
  runs,
  passes,
  hardFailures,
  baselinePasses: 0,
});

test("같으면 통과 (3/3 → 3/3)", () => assert.equal(verdictFor(c(3), c(3)), "통과"));
test("나아지면 통과 (2/3 → 3/3)", () => assert.equal(verdictFor(c(2), c(3)), "통과"));
test("실행 1번 떨어지면 경고 (3/3 → 2/3)", () => assert.equal(verdictFor(c(3), c(2)), "경고"));
test("실행 2번 떨어지면 회귀 (3/3 → 1/3)", () => assert.equal(verdictFor(c(3), c(1)), "회귀"));
test("regex·file_exists 실패는 나아져도 회귀 (1/3 → 2/3)", () =>
  assert.equal(verdictFor(c(1), c(2, 3, ["regex-rule"])), "회귀"));
test("이전 결과 없는 새 case 는 규칙 위반이 없으면 통과", () => assert.equal(verdictFor(undefined, c(0)), "통과"));
test("실행 수가 다르면 비례로 잰다 (3/3 → 4/5 경고)", () => assert.equal(verdictFor(c(3), c(4, 5)), "경고"));

test("픽스처 전체 비교: case 별 판정과 종료 코드 1", () => {
  const r = compareAggregates(load("aggregate-new.json"), load("aggregate-old.json"));
  assert.equal(r.partial, false);
  const v = Object.fromEntries(r.rows.map((row) => [row.name, `${row.old}→${row.new} ${row.verdict}`]));
  assert.deepEqual(v, {
    same: "3/3→3/3 통과", // baseline 만 떨어진 실행은 통과로 센다
    warn: "3/3→2/3 경고",
    regress: "3/3→1/3 회귀", // 오류로 끝난 실행은 실패
    hard: "1/3→2/3 회귀", // regex 실패
    better: "2/3→3/3 통과",
    "brand-new": "-→1/3 통과",
  });
  assert.equal(r.exitCode, 1);
});

test("회귀가 없으면 종료 코드 0", () => {
  const old = load("aggregate-old.json");
  assert.equal(compareAggregates(old, old).exitCode, 0);
});

test("부분 결과면 판정하지 않고 종료 코드 2", () => {
  const r = compareAggregates(load("aggregate-partial.json"), load("aggregate-old.json"));
  assert.equal(r.partial, true);
  assert.equal(r.rows.length, 0);
  assert.equal(r.exitCode, 2);
  assert.equal(compareAggregates(load("aggregate-old.json"), load("aggregate-partial.json")).exitCode, 2);
});

test("모르는 필드와 빠진 필드를 견딘다", () => {
  const s = summarize({ cases: [{ name: "a", arms: { with: [{ graders: [{ name: "regex-x", passed: false }] }] } }] });
  assert.deepEqual(s.cases.get("a")?.hardFailures, ["regex-x"]); // case 정의에 type 이 없으면 이름 규칙으로 본다
  assert.equal(summarize(null).cases.size, 0);
  assert.equal(summarize(load("aggregate-old.json")).version, "0.5.0");
});

test("블라인드: 4승 4패는 통과", () => assert.equal(blindVerdict(4, 4), "통과"));
test("블라인드: 3승 5패는 회귀", () => assert.equal(blindVerdict(3, 5), "회귀"));

test("블라인드 승패 세기: key.json 과 comparison.json", () => {
  const dir = mkdtempSync(join(tmpdir(), "sdd-blind-"));
  const key = { "eval-1/run-1": { A: "new", B: "old" }, "eval-1/run-2": { A: "old", B: "new" }, "eval-2/run-1": { A: "new", B: "old" } };
  mkdirSync(join(dir, "blind"), { recursive: true });
  writeFileSync(join(dir, "blind", "key.json"), JSON.stringify(key));
  const put = (slot: string, winner: string) => {
    mkdirSync(join(dir, "blind", slot), { recursive: true });
    writeFileSync(join(dir, "blind", slot, "comparison.json"), JSON.stringify({ winner }));
  };
  put("eval-1/run-1", "A"); // 새 버전 승
  put("eval-1/run-2", "A"); // 이전 버전 승
  put("eval-2/run-1", "TIE");
  assert.deepEqual(tallyBlind(dir), { wins: 1, losses: 1, ties: 1, missing: [] });
});
