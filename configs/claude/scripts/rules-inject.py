#!/usr/bin/env python3
"""Bash 로 파일을 다뤘을 때도 .claude/rules 규칙을 컨텍스트에 넣는다.

auto mode 와 bypass 모드에서는 Claude 가 Read/Edit 대신 cat, sed, grep 을 쓰라는
지시를 받는다. rules 파일의 paths frontmatter 는 Read/Edit 계열 도구의 file_path
에만 걸리므로, 그 모드에서는 규칙이 통째로 죽는다. 이 훅이 Bash 커맨드에 등장한
파일 경로를 훑어서 같은 매칭을 대신 해준다.

PostToolUse(matcher: Bash) 훅으로 붙인다. stdin 으로 훅 JSON 을 받고,
매칭된 규칙이 있으면 additionalContext 로 돌려준다. 없으면 아무것도 출력하지 않는다.
같은 규칙은 세션당 한 번만 넣는다.
"""

import json
import os
import re
import shlex
import sys
from pathlib import Path

MAX_CONTEXT = 8000  # additionalContext 상한 (Claude Code 가 넘는 만큼 잘라낸다)
MAX_TOKENS = 200  # 괴상하게 긴 커맨드에서 헛돌지 않도록 훑을 토큰 수를 막는다
STATE_ROOT = Path(os.environ.get("TMPDIR") or "/tmp") / "claude-rules-inject"


def glob_to_regex(pattern):
    """picomatch 스타일 glob 을 정규식으로 바꾼다. **, *, ?, {a,b} 만 다룬다."""
    out = []
    i, n = 0, len(pattern)
    while i < n:
        c = pattern[i]
        if c == "*":
            if pattern[i : i + 3] == "**/":
                out.append("(?:.*/)?")
                i += 3
                continue
            if pattern[i : i + 2] == "**":
                out.append(".*")
                i += 2
                continue
            out.append("[^/]*")
            i += 1
            continue
        if c == "?":
            out.append("[^/]")
            i += 1
            continue
        if c == "{":
            close = pattern.find("}", i)
            if close != -1:
                alts = pattern[i + 1 : close].split(",")
                out.append("(?:" + "|".join(re.escape(a.strip()) for a in alts) + ")")
                i = close + 1
                continue
        out.append(re.escape(c))
        i += 1
    return re.compile("^" + "".join(out) + "$")


def split_frontmatter(text):
    """(frontmatter 줄 목록, 본문) 을 돌려준다. frontmatter 가 없으면 (None, 원문)."""
    lines = text.split("\n")
    if not lines or lines[0].strip() != "---":
        return None, text
    for idx in range(1, len(lines)):
        if lines[idx].strip() == "---":
            return lines[1:idx], "\n".join(lines[idx + 1 :])
    return None, text


def parse_paths(front_lines):
    """frontmatter 의 paths 값을 읽는다. 블록 리스트, 인라인 리스트, 홑값을 받는다."""
    paths = []
    in_block = False
    for line in front_lines:
        head = re.match(r"^paths\s*:\s*(.*)$", line)
        if head:
            rest = head.group(1).strip()
            if not rest:
                in_block = True
            elif rest.startswith("["):
                paths += [
                    item.strip().strip("\"'")
                    for item in rest.strip("[]").split(",")
                    if item.strip()
                ]
            else:
                paths.append(rest.strip("\"'"))
            continue
        if in_block:
            item = re.match(r"^\s+-\s*(.+?)\s*$", line)
            if item:
                paths.append(item.group(1).strip("\"'"))
            elif line.strip():
                in_block = False
    return [p for p in paths if p]


def rule_files(project_dir):
    """사용자 규칙과 프로젝트 규칙을 모은다."""
    roots = [Path.home() / ".claude" / "rules"]
    if project_dir:
        roots.append(Path(project_dir) / ".claude" / "rules")
    found = []
    for root in roots:
        if root.is_dir():
            found += sorted(root.rglob("*.md"))
    return found


def load_rules(project_dir):
    """paths 를 가진 규칙만 [(파일, 패턴들, 본문)] 로 돌려준다.

    paths 가 없는 규칙은 Claude Code 가 이미 항상 로드하므로 건드리지 않는다.
    """
    rules = []
    for path in rule_files(project_dir):
        try:
            text = path.read_text(encoding="utf-8")
        except OSError:
            continue
        front, body = split_frontmatter(text)
        if front is None:
            continue
        patterns = parse_paths(front)
        if not patterns and body.strip():
            continue
        if patterns and body.strip():
            rules.append((path, [glob_to_regex(p) for p in patterns], body.strip()))
    return rules


def candidate_paths(command, cwd):
    """커맨드 문자열에서 실제로 존재하는 파일 경로를 뽑는다.

    쉘 문법을 온전히 해석하지 않는다. 토큰을 넉넉히 긁은 뒤 디스크에 있는 것만
    남기는 방식이라, 플래그나 sed 주소식 같은 건 존재 검사에서 저절로 걸러진다.
    """
    try:
        tokens = shlex.split(command, posix=True)
    except ValueError:
        tokens = re.split(r"[\s|;&<>()]+", command)
    base = Path(cwd) if cwd else Path.cwd()
    seen = []
    for token in tokens[:MAX_TOKENS]:
        token = token.strip().strip(",;")
        if not token or token.startswith("-"):
            continue
        try:
            resolved = Path(os.path.expanduser(token))
            if not resolved.is_absolute():
                resolved = base / resolved
            resolved = resolved.resolve()
            if resolved.is_file() and resolved not in seen:
                seen.append(resolved)
        except (OSError, ValueError):
            continue
    return seen


def matches(rule_patterns, file_path, project_dir):
    """절대 경로와 프로젝트 상대 경로 양쪽으로 맞춰본다."""
    targets = [str(file_path)]
    if project_dir:
        try:
            targets.append(str(file_path.relative_to(Path(project_dir).resolve())))
        except ValueError:
            pass
    return any(p.match(t) for p in rule_patterns for t in targets)


def already_sent(session_id, keys):
    """세션당 한 번만 넣도록, 이미 보낸 규칙을 걸러낸다."""
    if not session_id:
        return set()
    state = STATE_ROOT / f"{re.sub(r'[^A-Za-z0-9_-]', '_', session_id)}.txt"
    try:
        STATE_ROOT.mkdir(parents=True, exist_ok=True)
        sent = set(state.read_text(encoding="utf-8").split("\n")) if state.is_file() else set()
        fresh = [k for k in keys if k not in sent]
        if fresh:
            with state.open("a", encoding="utf-8") as fh:
                fh.write("\n".join(fresh) + "\n")
        return sent
    except OSError:
        return set()


def main():
    payload = json.load(sys.stdin)
    if payload.get("tool_name") != "Bash":
        return
    command = (payload.get("tool_input") or {}).get("command")
    if not command:
        return

    cwd = payload.get("cwd") or os.getcwd()
    project_dir = os.environ.get("CLAUDE_PROJECT_DIR") or cwd

    rules = load_rules(project_dir)
    if not rules:
        return

    files = candidate_paths(command, cwd)
    if not files:
        return

    hits = [
        (path, body)
        for path, patterns, body in rules
        if any(matches(patterns, f, project_dir) for f in files)
    ]
    if not hits:
        return

    sent = already_sent(payload.get("session_id"), [str(p) for p, _ in hits])
    hits = [(p, b) for p, b in hits if str(p) not in sent]
    if not hits:
        return

    blocks = [f"Contents of {path}:\n\n{body}" for path, body in hits]
    context = "\n\n".join(blocks)[:MAX_CONTEXT]
    json.dump(
        {"hookSpecificOutput": {"hookEventName": "PostToolUse", "additionalContext": context}},
        sys.stdout,
    )


if __name__ == "__main__":
    try:
        main()
    except Exception:
        # 훅이 죽어도 Bash 호출마다 잡음을 내지 않도록 조용히 물러난다.
        pass
