---
name: jev
description: >-
  TypeSafe 의 System One 모델 Jev(jev-latest) 사용법. 코드가 Jev 로 분류·라우팅·점수·
  검증 같은 구조화 판단을 내리게 할 때 쓴다. 상황에 맞는 질문 타입(Choice / Score /
  Noul) 고르기, instructions 와 criteria 작성법, 한 요청에 질문 묶기, 확률과 confidence 로
  분기하기, Python SDK(typesafe-sdk)와 TypeScript SDK(@typesafe-ai/sdk) 사용법, 쿡북 요약을
  담는다. 트리거 - 마스터가 "Jev", "TypeSafe", "System One", "typesafe-sdk",
  "@typesafe-ai/sdk", "noul" 을 언급하거나, 코드베이스에 이미 Jev 호출이 있어 그 코드를
  고치거나 넓힐 때. LLM 프롬프트로 JSON 을 받아 파싱하는 코드를 "타입 있는 판단"으로
  바꾸자는 요청에도 쓴다. Jev 와 무관한 일반 LLM 작업, 텍스트 생성, 코딩 에이전트
  모델 교체 요청에는 쓰지 않는다.
---

# Jev 사용법

Jev 는 텍스트를 생성하지 않는다. `state`(판단 대상)와 타입 있는 `questions` 를 받아
질문마다 구조화된 답(선택지, 점수, 예일 확률)과 확률 분포를 돌려준다. 코드가
워크플로를 쥐고, Jev 는 "아는 사람이 1초 안에 내릴 판단"만 맡는다.

## 이 스킬을 쓰지 않는 경우

- 코딩 에이전트의 LLM 을 Jev 로 바꾸려는 요청. Jev 는 대화·코드 생성·툴 호출을 못 한다. 그런 요청에는 "Jev 는 앱 안의 판단용이고, 에이전트 모델 대체재가 아니다"라고 한 줄로 답한다 (출처: https://docs.typesafe.ai/introduction/coding-agents.md)
- 자유 텍스트를 만들어야 하는 작업. 생성 모델을 쓴다
- 코드가 정확히 계산할 수 있는 것. 산술, 날짜 비교, 세기, 정규식 매칭은 코드에서 한다

## 작업 순서

- 결정부터 찾는다. 앱이 보여주고, 고르고, 바꾸고, 넘기는 행동이 무엇인지 적고, 거기에 필요한 판단을 거꾸로 추적한다. 규칙·계산·정확한 조회·실행은 코드에 남긴다
- 판단마다 질문 타입을 고른다. 아래 "질문 타입 고르기"
- state 를 짠다. 질문에 필요한 맥락만, 이름 붙은 JSON 필드로. 코드에서 먼저 필터링한다
- 질문을 쓴다. 질문 ID 는 모델이 못 보므로 instructions 에 완전한 질문을 쓴다. state 의 특정 부분은 백틱 경로로 가리킨다 (`ticket.messages[0].text`)
- 같은 state 위의 질문은 전부 한 요청에 넣는다. 일부 입력에만 의미 있는 투기적 질문도 넣고 코드가 버린다
- 답을 코드에서 조합한다. 확률과 confidence 로 "실행 / 확인 / 사람에게" 를 가른다. 임곗값은 행동의 리스크에 따라 다르게
- 질문과 임곗값 상수는 한 파일(또는 한 모듈)에 모은다. 사람이 검토할 핵심이 그것이다
- 대표 케이스로 테스트한다. 쿡북 수치는 참고용이지 규칙이 아니다

## 질문 타입 고르기

- 답이 "정해진 집합 중 하나" 이고 옵션 사이에 순서가 없으면 Choice
    - 팀 라우팅, 문서 유형, 의도 분류, 후보 중 선택
    - 목록이 모든 입력을 못 덮으면 `other` / `none_of_the_above` 를 넣는다
    - 하나만 고르면 될 때 쓴다. 여러 라벨이 동시에 붙을 수 있으면 라벨마다 Noul
- 답이 "스펙트럼 위의 위치" 이고 각 단계를 상황으로 서술할 수 있으면 Score
    - 심각도, 불만 정도, 관련성, 품질, 숙련도
    - 단계는 "Broken or degraded feature, but workaround exists" 처럼 상황을 쓴다. "보통", "3" 같은 정도·숫자는 안 된다
    - 하나의 차원만. "punctual and smart and experienced" 는 세 질문이다
- 답이 "예/아니오" 이고 그 확률 자체가 쓸모 있으면 Noul
    - 환불 요청 여부, 개인정보 포함 여부, 인용이 주장을 뒷받침하는지
    - 높은 값이 "예"가 되게 쓴다. 조건은 하나만
    - 0.5 는 "중간 정도"가 아니라 "반반"이다. 정도를 재려면 Score
- 둘 다 맞아 보이면 코드가 바로 분기할 수 있는 쪽. Choice 는 코드 경로, Score 는 임곗값, Noul 은 `if`
- "무엇을 고를지"와 "고를지 말지"가 둘 다 필요하면 Choice 하나와 Noul 들을 같은 요청에

세부와 실측 수치는 `references/question-types.md` 에 있다.

## 요청과 응답의 모양

```json
{
  "state": { "ticket_message": "My flight was cancelled. Can I get a refund?", "refund_policy": "Cancelled flights are eligible for a full refund." },
  "model": "jev-latest",
  "questions": {
    "refund_requested": { "type": "noul", "instructions": "Does `ticket_message` request a refund?" },
    "request_type": {
      "type": "choice",
      "instructions": "What is the main request in `ticket_message`?",
      "criteria": { "refund": "The customer wants money returned.", "rebooking": "The customer wants a replacement flight.", "information": "The customer is asking for information only." }
    },
    "frustration": {
      "type": "score",
      "instructions": "How frustrated does the customer appear in `ticket_message`?",
      "criteria": ["Calm and neutral.", "Concerned but civil.", "Very angry or using strong language."]
    }
  }
}
```

- 응답은 `answers` 아래 같은 키로 온다
    - Noul: `{ "type": "noul", "noul": 0.95 }`
    - Choice: `{ "type": "choice", "choice": "refund", "probabilities": {...}, "confidence": 0.81 }`
    - Score: `{ "type": "score", "score": 1.05, "legend": {...}, "probabilities": {...}, "confidence": 0.92 }`
- Score 의 `score` 는 단계 번호의 확률 가중 평균이다. 세 단계면 0~2. 같은 값이 다른 분포에서 나올 수 있으니 `probabilities` 도 본다
- Noul 에는 confidence 가 없다. 값이 답이자 확신이다

## confidence 로 분기하기

- 높음 → 자동 실행. 중간 → 확인·검토. 낮음 → 사람 또는 다른 시스템
- 임곗값은 행동의 대가에 비례한다. 잔액 조회는 0.6 이면 되고 송금 승인은 0.85 를 넘어야 한다 (문서 예시, 숫자는 자기 데이터로 정한다)
- Noul 은 `noul > T` 로 boolean 을 만들고, 중간 구간(예: 0.2~0.8)은 사람에게 보낸다
- 최고 옵션만 고르면 되는 자리에는 임곗값이 필요 없다
- Noul 로 튜닝한 임곗값을 Choice 로 옮기지 않는다. 같은 질문도 타입이 다르면 수치가 다르다

패턴(fan-out, confidence routing, composite scoring, intent routing)과 코드 예시는 `references/patterns.md` 에 있다.

## 언어별 사용법

- Python: `references/python.md`. `uv add typesafe-sdk`, `TypeSafeClient().system_one(state, questions)`, 답은 `response.answers["id"].noul` 또는 `response.nouls / choices / scores`
- TypeScript: `references/typescript.md`. `bun add @typesafe-ai/sdk`, `new TypeSafeClient().systemOne({ state, questions })`, 질문 빌더 `noul()` / `choice()` / `score()`, 옵션 리터럴이 결과 타입으로 흐른다
- 다른 언어나 직접 호출: `references/http-api.md`. `POST https://api.typesafe.ai/v1/systemone`, Bearer 키
- 환경변수 `TYPESAFE_API_KEY` 는 두 SDK 공통. 웹앱에서는 키를 서버에 둔다

## 반드시 피할 것 (jev-1.13 실측 약점)

- 쓴 대로 읽는다. 의도 말고 조건을 쓴다. 틀린 답을 "사실 이런 뜻"이라고 설명하게 되면 그 설명이 instructions 에 빠진 반쪽이다
- 수학·세기·날짜 비교를 시키지 않는다. 추출은 Choice 로(월·일·연도는 닫힌 집합, "not stated" 포함), 계산은 코드로
- 이중 부정, 여러 홉 추론, 무관한 내용이 많은 큰 state 는 정확도를 떨어뜨린다
- instructions 와 criteria 가 반대 방향을 가리키면 안 된다 (`true` 가 "아니오"인 Noul)
- 질문 사이 산술 항등식을 기대하지 않는다. "refund" 와 "not refund" 두 Noul 의 합은 1 이 아니다 (실측 1.19)
- 텍스트 생성을 시키지 않는다. 후보는 정규식이나 생성 모델로 뽑고 Jev 가 고르게 한다
- 한 요청에 질문 하나만 넣는 습관. 같은 state 면 전부 묶는다 (13개 질문 묶기 실측: 12.2배 저렴, 10.0배 빠름, 답 동일)

전체 목록과 대안은 `references/writing-questions.md` 에 있다.

## 레퍼런스 색인

- `references/question-types.md` — 세 타입의 요청·응답 필드, 고르는 기준, Noul 대 Score 실측, 구조화된 instructions/criteria 예시, 두 번째 요청이 정당한 경우
- `references/writing-questions.md` — 질문 쪼개기, state 구성, instructions 작성 규칙, jev-1.13 약점 9가지와 대안, 체크리스트
- `references/patterns.md` — confidence 의미, 임곗값 정하기, 4개 패턴 코드, 전체 조합 예시
- `references/cookbooks.md` — 쿡북 18편 요약. 문제 / 질문 설계 / state / 코드 조합 / 비용 / 교훈. 새 워크플로를 짤 때 가장 가까운 쿡북부터 본다
- `references/python.md` — Python SDK 설치, 클라이언트, 질문 객체, 응답 타입, 재시도, 예외, 게이트웨이, 완전한 예제
- `references/typescript.md` — TypeScript SDK 설치, 질문 빌더와 제네릭, 응답 타입, 에러 클래스, 재시도, 완전한 예제
- `references/http-api.md` — 엔드포인트, 와이어 포맷, 오류 코드, 가격·레이트 리밋·컨텍스트 한도, 별칭, 게이트웨이

## 상황별 쿡북 바로가기

- 분류·라우팅: classification using confidence, hierarchical classification, intent routing 패턴
- 검색·순위: re-ranking, line-by-line search, classifying RAG passages
- 추출: date extraction, pre-parsed value extraction, SDE cascade
- 검증·가드레일: citation check, LLM guardrails, function calling
- 동일성·정렬: entity alignment, skill suggestion
- 안정성 측정: self-consistency nouls / choices
- 구조 복원: autoformat
- 피처 엔지니어링: autoresearch feature discovery

## 최신 문서 확인

- 이 스킬은 2026-10-01 의 문서를 요약했다. SDK 시그니처나 한도가 의심되면 라이브 문서를 읽는다
- 색인: https://docs.typesafe.ai/llms.txt. 페이지 경로에 `.md` 를 붙이면 마크다운으로 받는다 (예: https://docs.typesafe.ai/primitives/choice.md)
- 공식 에이전트 스킬(라이브 문서를 읽으라는 짧은 안내): https://github.com/typesafe-ai/skills
