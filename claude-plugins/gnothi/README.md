# gnothi (γνῶθι σεαυτόν, 네 자신을 알라)

LLM 이 "지금 나는 어느 세션에서, 어느 모델로 돌고 있는가"를 알게 하는 Claude Code 플러그인이에요. 세션 ID 와 모델 이름을 컨텍스트에 넣고, 모델에 맞는 마크다운 룰을 함께 넣어요.

## 동작

- SessionStart 훅이 매 세션 시작(startup/resume/clear/compact)마다 다음을 컨텍스트에 주입해요. compact 뒤에도 다시 들어가요.

  ```
  current session_id: 7013b781-1531-49c2-8f07-b4dacea0dfae
  current model: claude-fable-5-1 (via settings)

  (gnothi rule: fable.md)
  # gnothi: Fable
  ...
  ```

- UserPromptSubmit 훅이 프롬프트마다 트랜스크립트의 마지막 응답 모델을 읽어요. 세션 중 `/model` 로 모델을 바꿔서 매칭되는 룰 집합이 달라지면 룰을 다시 주입하고, 모델 이름만 달라졌으면 `current model: ... (switched from ...)` 한 줄만 넣어요. 별칭이 실제 id 로 구체화된 것(opus → claude-opus-5)은 조용히 넘어가요.
- SessionEnd 훅이 세션 상태 파일(`~/.claude/gnothi/state/{session_id}`)을 지워요.
- 서브에이전트 안에서 도는 훅(입력에 `agent_id` 가 있는 경우)은 아무것도 하지 않아요.

## 모델을 알아내는 순서

Claude Code 는 SessionStart 훅 입력에 `model` 을 항상 넣어주지 않아요(2.1.270 의 startup 에서는 없었어요). 그래서 앞에서부터 처음 성공한 출처를 쓰고, 출처 이름을 `(via ...)` 로 같이 적어요.

- `hook` — 훅 입력의 `model`. 확실한 값이에요.
- `transcript` — 트랜스크립트의 마지막 assistant 메시지가 실제로 답한 모델. resume/compact 와 두 번째 프롬프트부터는 이것이 확실한 값이에요.
- `argv` — 부모 `claude` 프로세스의 `--model` 인자. `opus`, `haiku` 같은 별칭일 수 있고, 추정값이에요.
- `env` — `ANTHROPIC_MODEL`. 추정값이에요.
- `settings` — `{cwd}/.claude/settings.local.json`, `{cwd}/.claude/settings.json`, `~/.claude/settings.json` 의 `model`. `claude-fable-5-1[1m]` 처럼 붙는 컨텍스트 윈도우 표기는 떼어내요. 추정값이에요.
- `unknown` — 아무 데서도 못 찾음

추정값(`argv`, `env`, `settings`)일 때는 "시스템 프롬프트의 모델 ID 와 다르면 시스템 프롬프트가 맞다"는 한 줄을 같이 넣어요. LLM 의 시스템 프롬프트에는 실제 모델 ID 가 이미 적혀 있어서, 모델 이름 자체를 알려주는 것보다 **그 모델에 맞는 룰을 골라 넣는 것**이 이 플러그인의 진짜 역할이에요. 추정이 틀려도 첫 응답 뒤 UserPromptSubmit 훅이 트랜스크립트로 실제 모델을 읽어 룰을 바로잡아요.

2.1.270 에서 실측한 예: `claude -p ... --model haiku` 로 띄운 세션이 실제로는 `claude-opus-5` 로 답했어요. 이때 startup 의 `(via argv)` 는 `haiku` 였고, 두 번째 프롬프트에서 `opus.md` 로 바뀌었어요.

## 모델별 룰 쓰기

`rules/` 아래에 마크다운 파일을 두면 돼요. 파일명(확장자 제외)이 모델 문자열에 대소문자 구분 없이 부분일치하면 주입돼요.

- `fable.md` ↔ `claude-fable-5-1`, `fable`
- `haiku.md` ↔ `claude-haiku-4-5-20251001`, `haiku`
- `claude-opus-5.md` 처럼 긴 이름은 별칭 `opus` 로 시작한 세션의 첫 프롬프트에서는 매칭되지 않아요. 짧은 계열 이름을 권해요.
- `default.md` 는 다른 룰이 하나도 매칭되지 않을 때만 들어가요. 모델을 못 알아냈을 때의 안전장치예요.
- 여러 파일이 매칭되면 파일명 순서로 전부 들어가요.

플러그인에 커밋하지 않을 머신별 룰은 `~/.claude/gnothi/rules/` 에 두면 함께 읽혀요(위치는 `GNOTHI_RULES_DIR` 로 바꿀 수 있어요). 같은 파일명이 양쪽에 있으면 사용자 디렉터리의 것이 플러그인 것을 덮어요.

룰 파일은 컨텍스트에 그대로 들어가므로, 주석이나 설명 없이 LLM 에게 줄 지시만 적어요. 기본으로 들어 있는 `fable.md`, `opus.md`, `sonnet.md`, `haiku.md`, `default.md` 는 출발점이니 마스터의 기준으로 고쳐 써요.

## 설치

```sh
claude plugin marketplace add ~/.config/claude-plugins   # 이미 등록돼 있으면 생략
claude plugin install gnothi@dotfiles
```

`jq` 가 필요해요. 훅 파일을 고친 뒤에는 `claude plugin update gnothi@dotfiles` 로 캐시를 갱신하고 새 세션을 열어요.

- 끄기: `claude plugin disable gnothi@dotfiles` 또는 환경변수 `GNOTHI_DISABLE=1`
- 상태 파일 위치 바꾸기: `GNOTHI_STATE_DIR`

## 확인

훅 명령은 파이프로 바로 시험할 수 있어요.

```sh
echo '{"hook_event_name":"SessionStart","session_id":"test","model":"claude-haiku-4-5"}' \
  | ~/.config/claude-plugins/gnothi/hooks/gnothi.sh | jq -r .hookSpecificOutput.additionalContext
```

## 이 플러그인을 쓰는 곳

- `side-issue` 플러그인 — 여기서 주입한 `current session_id` 로 `claude --resume {id} --fork-session --bg` 포크를 띄워요. 환경변수 `CLAUDE_CODE_SESSION_ID` 도 같은 값이지만, 컨텍스트에 적힌 값을 LLM 이 바로 읽을 수 있게 하는 것이 이 플러그인의 역할이에요.
- `wt` 스킬 — PR 본문에 시작 세션 ID 를 남길 때 이 값을 써요.
