# Jev 질문 타입 레퍼런스

출처: https://docs.typesafe.ai/primitives.md 와 하위 페이지(choice, score, noul, advanced). 모델 `jev-1.13.0` 기준.

## 세 가지 질문 타입

- Choice: "이 중 어느 것인가". 정해진 옵션 집합에서 하나를 고른다.
    - 요청 필드: `type: "choice"`, `instructions`, `criteria` (옵션 이름 → 설명 맵, 최대 255개, 설명은 `null` 허용)
    - 응답 필드: `choice`(최고 확률 옵션), `probabilities`(옵션별 확률, 합 1), `confidence`(0~1)
- Score: "어느 단계인가". 순서 있는 단계 중 위치를 잰다.
    - 요청 필드: `type: "score"`, `instructions`, `criteria` (낮은 단계 → 높은 단계 순서의 배열, 최소 2개, 최대 10개)
    - 응답 필드: `score`(확률 가중 평균 위치, 단계 사이 값 가능), `legend`(단계 번호 → 설명), `probabilities`(단계 번호 문자열 → 확률), `confidence`
    - 단계 번호는 배열 인덱스 0부터. 세 단계면 score 범위는 0~2
    - `score = Σ(단계번호 × 확률)`. 예: 0×0.0 + 1×0.57 + 2×0.43 = 1.43
- Noul: "이것이 참인가". 예/아니오 질문에 대해 예일 확률을 돌려준다.
    - 요청 필드: `type: "noul"`, `instructions`, `criteria`(선택, `{true: ..., false: ...}`)
    - 응답 필드: `noul`(0~1). 별도 `confidence` 없음. 결과가 둘뿐이라 값 하나로 분포가 다 설명된다

## 타입 고르는 기준

- 답이 서로 순서 없는 고정 집합 중 하나이면 Choice
    - 티켓 담당 팀, 문서 유형, 프로그래밍 언어
    - 목록이 모든 입력을 못 덮을 수 있으면 `other` 또는 `none_of_the_above` 옵션을 넣는다
- 답이 스펙트럼 위의 위치이고 각 지점을 말로 설명할 수 있으면 Score
    - 버그 심각도, 고객 불만 정도, 숙련도
    - 단계는 "상황"으로 서술한다. "moderately severe" 같은 정도 표현은 못 쓴다
- 답이 깔끔한 예/아니오이고 그 확률 자체가 유용하면 Noul
    - 개인정보 포함 여부, 환불 요청 여부, 특정 기술 언급 여부
- 둘 다 맞아 보이면 코드가 바로 분기할 수 있는 쪽을 고른다
    - Choice 는 세 갈래 코드 경로, Score 는 임곗값, Noul 은 `if` 하나에 대응한다

## Noul 과 Score 를 혼동하지 않기

- Noul 0.5 는 "중간 정도"가 아니라 "예와 아니오가 반반"이다
- "이 후보가 Python 에 강한가?" 를 Noul 로 물으면 "강하다"의 정의가 불명확해 값을 해석하기 어렵다
- 정도를 재고 싶으면 Score 로 단계를 정의한다
    - 경험 없음 / 약간 익숙함 / 업무에서 매일 사용 / 깊은 전문성
- 예/아니오 결정이 필요하면 조건을 명확히 쓴다
    - "이력서에 업무에서 Python 을 썼다고 명시되어 있는가?"
- 문서의 실측 예시(4명의 후보)
    - Java/Go 만 경험: Noul 0.03, Score 0.0
    - 가끔 작은 스크립트: Noul 0.14, Score 1.0
    - 2년간 매일 데이터 파이프라인: Noul 0.81, Score 2.05
    - 8년간 매일, 대형 Django 유지보수: Noul 0.92, Score 2.89
- Noul 값의 간격은 사용자가 정한 것이 아니다. Score 는 각 단계를 따로 판단하므로 사용자가 쓴 단계 근처에 떨어진다

## Choice 와 Noul 묶음의 차이

- Choice 는 상대적이다. "어느 것이 가장 맞는가"를 정한다. 전부 안 맞아도 하나를 고른다
- Noul 한 개씩은 절대적이다. 모두 낮을 수 있다
- 여러 라벨이 동시에 붙을 수 있으면 라벨마다 Noul 하나씩 묻는다
- "고를지 말지"와 "무엇을 고를지"가 다 필요하면 Choice 와 Noul 을 같이 보낸다
    - skill suggestion 쿡북: Choice 로 스킬을 고르고, Noul 로 제안할지 말지를 정한다

## 응답 읽는 법

- Choice `confidence` 는 확률 분포가 얼마나 한 옵션에 몰렸는지를 요약한 수치다
    - 평평하면 낮다. 어느 옵션도 뚜렷한 승자가 아니라는 뜻
    - 두 팀에 걸친 티켓: returns 0.61, billing 0.35 → confidence 0.42
- Score 의 같은 `score` 가 다른 분포에서 나올 수 있다
    - 1.0 은 "전부 단계 1" 일 수도, "0과 2에 반반" 일 수도 있다
    - `probabilities` 와 `confidence` 를 같이 읽어야 구분된다
- Score 의 낮은 confidence 는 보통 셋 중 하나다
    - 이 입력에 대해 단계들이 겹친다
    - 질문이 둘 이상의 차원을 재고 있다
    - state 에 판단할 정보가 부족하다
- confidence 1.0 은 "분포가 한 곳에 몰렸다"는 뜻이지 "정답"이라는 보장이 아니다

## 구조화된 instructions 와 criteria

- `instructions`, Choice 옵션 설명, Score 단계 설명, Noul 의 `true`/`false` 는 모두 string, object, array, null 을 받는다
- 문자열로 시작한다. 짧고 명확한 질문은 문자열이면 충분하다
- 객체로 바꾸는 시점
    - 질문에 맥락이나 예시가 필요할 때. 긴 배경 설명이나 예시 목록은 질문 옆의 이름 붙은 필드에 둔다
    - 질문의 일부가 코드에서 올 때. DB 레코드를 문자열 템플릿에 끼워 넣지 말고 자기 필드에 둔다
    - 비슷한 질문이 여럿일 때. 보충 데이터로 질문을 구분한다
- 필드 이름(`question`, `focus`, `what`, `not_for`, `examples`, `signals`)은 API 예약어가 아니다. 모델이 이름도 같이 보므로 내용을 설명하는 짧은 이름을 쓴다
- 옵션끼리 헷갈릴 때는 각 옵션에 `what`, `not_for`, `examples` 를 같은 필드 이름으로 준다. 모델이 옵션을 나란히 비교할 수 있다
- Score 단계에 예시를 붙이면 "실제 입력과 닮은 예시"일 때만 효과가 있다
    - 문서 실측: Safari 버그 리포트에 plain string 은 score 1.43 / confidence 0.35
    - 브라우저 관련 예시를 붙이면 1.03 / 0.96
    - 무관한 예시를 붙이면 1.43 / 0.35 로 변화 없음
    - confidence 가 올랐다고 정답이 된 것은 아니다. 기대 단계를 아는 예시로 고치고, 별도 입력으로 검증한다

## 구조화 예시

Noul 에 코드에서 온 레코드를 끼우는 형태:

```json
{
  "same_as_record_18": {
    "type": "noul",
    "instructions": {
      "potential_duplicate": { "name": "Jon Smith", "location": "Oakland, CA", "last_employer": "Google" },
      "question": "Is the resume for the same person as `potential_duplicate`?"
    }
  }
}
```

Choice 옵션 경계를 대비시키는 형태:

```json
{
  "department": {
    "type": "choice",
    "instructions": {
      "question": "Which team should handle this message?",
      "focus": "Classify the customer's primary request, not every topic mentioned."
    },
    "criteria": {
      "billing": {
        "what": "Charges, invoices, refunds, or subscriptions",
        "not_for": "Order tracking or account access",
        "examples": ["I was charged twice", "Where is my refund?"]
      },
      "orders": {
        "what": "Order status, delivery, cancellation, or returns",
        "not_for": "Charges or account access",
        "examples": ["Where is my package?", "Cancel my order"]
      }
    }
  }
}
```

Score 단계에 신호를 붙이는 형태:

```json
{
  "pr_scope": {
    "type": "score",
    "instructions": {
      "question": "How focused is this pull request description on a single change?",
      "note": "Judge the number of independent changes, not the size of any one change."
    },
    "criteria": [
      { "summary": "One change, clearly stated", "signals": ["A single fix or feature"] },
      { "summary": "One main change plus a small related tweak", "signals": ["The tweak supports the main change"] },
      { "summary": "Several independent changes bundled together", "signals": ["Changes that could each be their own PR"] }
    ]
  }
}
```

택소노미를 걷는 형태(옵션 값에 하위 트리를 넣어 모델이 가지 아래를 미리 보게 한다):

```json
{
  "department": {
    "type": "choice",
    "instructions": "Which top-level department does this product belong to?",
    "criteria": {
      "Sporting Goods": { "Cycling": ["Bike Bottles & Cages", "Helmets"], "Outdoor": ["Tents", "Hydration Packs"] },
      "Home & Kitchen": { "Drinkware": ["Water Bottles", "Travel Mugs"] },
      "Baby & Toddler": ["Sippy Cups", "Bibs"]
    }
  }
}
```

- 하위 트리가 너무 크면 직계 자식과 리프 샘플만 남긴다
- 선택된 가지의 자식을 다음 요청의 옵션으로 넣어 리프까지 반복한다. 확률이 비슷하면 여러 경로를 살려 두는 beam search 를 쓴다(hierarchical classification 쿡북)

## state 의 특정 필드를 가리키기

- state 가 JSON 객체면 instructions 에서 백틱으로 감싼 점·인덱스 경로로 가리킨다
    - "Does `ticket.messages[0].text` request a refund?"
    - "Does `refund_policy` support the refund requested in `ticket.messages[0].text`, given `order.charges`?"
- 백틱을 포함해서 쓴다. 모델이 어느 부분을 봐야 하는지 알게 된다

## 하나의 요청에 여러 질문

- 같은 state 를 쓰는 질문은 전부 한 요청에 넣는다. 타입은 자유롭게 섞는다
- 모든 질문은 병렬로, 서로 독립적으로 평가된다. 한 질문의 답이 다른 질문의 맥락이 되지 않는다
- 질문을 늘려도 응답 시간은 거의 안 변한다. 비용은 추가 질문 토큰만큼만 든다
- 질문 ID 는 코드용이다. 모델에 전송되지 않는다. ID 가 자명해 보여도 instructions 에 완전한 질문을 쓴다

## 두 번째 요청이 정말 필요한 경우

- 첫 답이 있어야 두 번째 요청을 만들 수 있을 때만 요청을 나눈다
    - 답을 보고 state 에 넣을 데이터를 더 가져와야 할 때
    - 답이 state 의 구성을 결정할 때
    - 답이 다음 질문의 옵션을 결정할 때
- 그 외에는 한 요청에 다 묻고 코드가 불필요한 답을 버린다
- 문서가 드는 정당한 두 요청 사례
    - skill suggestion: 182개 스킬을 한 번에 순위 매기고, 상위 3개의 전문을 가져와 다시 판단
    - structure recovery: 줄바꿈이 문장을 쪼갰는지 묻고, 그 답으로 블록을 만든 뒤 블록을 분류
    - hierarchical classification: 각 Choice 답으로 다음 요청의 옵션을 정함
