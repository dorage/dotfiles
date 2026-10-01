# jev

TypeSafe 의 System One 모델 **Jev** 를 코드 안에서 쓰는 법을 담은 스킬 플러그인이에요. Jev 는 텍스트를 생성하지 않고, `state` 와 타입 있는 `questions` 를 받아 질문마다 구조화된 답(선택지, 점수, 예일 확률)과 확률 분포를 돌려줘요. 이 플러그인은 LLM 이 그 API 를 올바르게 쓰도록 판단 기준과 코드 모양을 미리 알려줘요.

공식 스킬(https://github.com/typesafe-ai/skills)은 "라이브 문서를 읽어라"는 짧은 안내예요. 이 플러그인은 2026-10-01 기준 문서 111쪽(개념, 질문 타입, 패턴, 쿡북 18편, SDK 레퍼런스)을 한국어로 요약해 오프라인에서도 같은 판단을 내릴 수 있게 했어요.

## 언제 동작하나

- 마스터가 Jev, TypeSafe, System One, `typesafe-sdk`, `@typesafe-ai/sdk`, noul 을 언급할 때
- 코드베이스에 이미 Jev 호출이 있어 그 코드를 고치거나 넓힐 때
- "LLM 에 JSON 달라고 해서 파싱하는 코드"를 타입 있는 판단으로 바꾸자는 요청일 때

Jev 와 무관한 일반 LLM 작업, 텍스트 생성, 코딩 에이전트의 모델을 바꾸려는 요청에는 쓰지 않아요.

## 스킬이 알려주는 것

- 지금 상황에 맞는 질문 타입 고르기
    - 정해진 집합 중 하나면 Choice, 스펙트럼 위 위치면 Score, 예/아니오면 Noul
    - Noul 0.5 는 "중간"이 아니라 "반반"이라는 것, Choice 와 Noul 묶음의 차이 같은 자주 틀리는 지점
- Jev 를 잘 쓰는 법
    - 넓은 판단을 원자적 질문으로 쪼개고 코드에서 조합하기
    - 같은 state 위의 질문은 전부 한 요청에 묶기 (13개 묶으면 12.2배 저렴, 10.0배 빠름)
    - 확률과 confidence 로 "실행 / 확인 / 사람에게" 가르기, 임곗값은 행동 리스크에 비례
    - jev-1.13 의 실측 약점 9가지 (글자 그대로 읽기, 산술·세기·날짜, 간접 참조, 큰 state, 적대적 내용, 모순된 criteria, 구조적 불변식, 생성)와 대안
- Python 환경 사용법 (`typesafe-sdk`, `uv add`)
- TypeScript 환경 사용법 (`@typesafe-ai/sdk`, `bun add`)
- HTTP API 원형, 가격, 레이트 리밋, 컨텍스트 한도, 별칭, 게이트웨이
- 쿡북 18편 요약. 문제 / 질문 설계(실제 질문 문구) / state 구성 / 코드 조합(실제 임곗값) / 비용 / 교훈

## 파일 구성

- `skills/jev/SKILL.md` — 진입점. 작업 순서, 질문 타입 결정 기준, 요청·응답 모양, 피할 것, 레퍼런스 색인
- `skills/jev/references/question-types.md` — 세 타입의 필드와 고르는 기준, 구조화된 instructions/criteria 예시
- `skills/jev/references/writing-questions.md` — 질문 쪼개기, state 구성, 작성 규칙, 약점과 대안, 체크리스트
- `skills/jev/references/patterns.md` — confidence 의미와 임곗값, fan-out / confidence routing / composite scoring / intent routing
- `skills/jev/references/cookbooks.md` — 쿡북 18편 요약
- `skills/jev/references/python.md` — Python SDK 치트시트와 완전한 예제
- `skills/jev/references/typescript.md` — TypeScript SDK 치트시트와 완전한 예제
- `skills/jev/references/http-api.md` — 엔드포인트, 와이어 포맷, 오류, 모델 한도

## 설치

이 플러그인은 dotfiles 리포의 로컬 마켓플레이스 `dotfiles`(`~/.config/claude-plugins`)에 속해요.

```sh
claude plugin marketplace add ~/.config/claude-plugins   # 이미 등록돼 있으면 생략
claude plugin install jev@dotfiles
```

## 전제 조건

- Jev 를 실제로 호출하려면 https://console.typesafe.ai/keys 에서 만든 키를 `TYPESAFE_API_KEY` 환경변수에 둬요
- 스킬 자체는 키 없이도 동작해요. 코드 설계와 질문 작성만 도와요

## 문서 갱신

이 스킬은 2026-10-01 의 문서를 요약했어요. SDK 시그니처나 한도가 바뀐 것 같으면 https://docs.typesafe.ai/llms.txt 에서 색인을 받아 해당 페이지 경로에 `.md` 를 붙여 읽고 레퍼런스를 고쳐요.
