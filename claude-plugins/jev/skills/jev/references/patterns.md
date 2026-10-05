# Jev 아키텍처 패턴과 confidence 활용

출처: https://docs.typesafe.ai/confidence.md, https://docs.typesafe.ai/patterns.md 와 하위 4개 페이지.

## confidence 란

- Choice 와 Score 답에는 `probabilities` 가 있다. 그 분포의 "모양"이 확신 정도다. 한 곳에 몰리면 확신, 퍼지면 불확실
- `confidence` 는 그 모양을 0~1 숫자 하나로 접은 통계량이다. 직접 계산하지 않아도 임곗값으로 쓸 수 있다
- Noul 은 confidence 가 없다. 값 자체가 답이자 확신이다
- 기본 제공 정의에 묶이지 않는다. 다른 측도가 더 맞으면 `probabilities` 로 직접 계산한다
- "모르겠다"를 표현할 수 있는 시스템만 신뢰할 수 있다. confidence 는 그 신호다

## confidence 를 쓰는 세 갈래

- 높음: 자동 실행
- 중간: 조심해서 진행. 사용자 확인, 검토 플래그, 추가 정보 수집
- 낮음: 실행하지 않음. 사람에게, 명확화 요청으로, 다른 시스템으로
- 경계는 "틀렸을 때의 대가"에 따라 정한다

## 임곗값은 리스크에 비례한다

- 임곗값은 하나의 숫자가 아니다. 같은 시스템 안에서도 행동마다 다르게 둔다
- 문서 예시 (음성 뱅킹)
    - 어떤 행동이든 confidence 0.6 미만이면 상담원에게
    - `check_balance` 는 0.6 이면 실행. 틀려도 잔액을 한 번 더 듣는 정도
    - `approve_transfer` 는 0.85 초과면 실행, 그 사이면 사용자에게 재확인
- 다른 문서 예시는 0.5 바닥 / 0.9 고위험 상한을 쓴다. 숫자는 도메인과 자기 데이터로 정한다. 보수적으로 시작해 관찰하며 조정한다
- 가장 좋은 옵션만 고르면 되는 경우에는 임곗값이 필요 없다. 최고 confidence 를 고르면 된다
- 특정 통계 알고리즘을 염두에 두면 confidence 가 아니라 probabilities 를 쓴다
- 어떤 임곗값이 맞는지는 "confidence 대 정확도"를 자기 데이터에서 그려 보고 정한다

## Noul 임곗값

- 보통 `noul > T` 로 boolean 을 만든다
- 예와 아니오를 똑같이 쉽게 처리할 수 있으면 0.5
- 거짓 "예"가 비싸면(호출, 환불) 올린다
- 참 "예"를 놓치는 것이 비싸면(안전 이슈) 내린다
- 중간 값은 사람에게 보낸다. 문서 예시는 `NO = 0.2`, `YES = 0.8` 사이를 검토로 보낸다
    - 검토가 너무 많으면 간격을 좁히고, 잘못된 라우팅이 새면 넓힌다

## 패턴 1: Speculative fan-out (투기적 확장)

- 시스템에 필요한 질문을 전부 한 요청에 넣고, 코드가 사후에 관련 있는 답만 쓴다
- 티켓 분류 예시. category(Choice) 와 함께 bug_severity(Score), has_reproducible_steps(Noul), refund_requested(Noul), frustration(Score) 를 한 번에 묻는다
    - bug_severity 와 has_reproducible_steps 는 버그 리포트일 때만 의미 있다
    - refund_requested 는 billing 일 때만 의미 있다
    - 기능 요청으로 판명되면 severity 답은 그냥 무시한다
- 코드 예시

```python
if category.choice == "bug_report":
    if bug_severity.score > 1.5 and bug_repro.noul > 0.6:
        escalate_to_engineering(ticket_id, severity="high")
    else:
        add_to_bug_backlog(ticket_id)
elif category.choice == "billing":
    if refund.noul > 0.7:
        route_to_billing_with_flag(ticket_id, refund_likely=True)
    else:
        route_to_billing(ticket_id)
elif category.choice == "feature_request":
    log_feature_request(ticket_id)

if frustration.score > 1.5:
    flag_for_priority_response(ticket_id)
```

- 투기적 질문의 전제는 질문 안에 명시한다. "If the customer wants to return something, why?" 처럼
- 효과 실측 (parallel questions 쿡북): 13개 질문을 한 호출로 묶으면 13개 별도 호출 대비 12.2배 저렴, 10.0배 빠름, 답은 동일
- 추가 질문도 토큰은 쓴다. 실제 요청 예산, 비용, 종단 지연을 측정한다
- 코딩 에이전트는 "질문 하나당 호출 하나" 습관에 빠지기 쉽다. 의식적으로 묶는다

## 패턴 2: Confidence-gated routing (확신 게이트 라우팅)

- 답은 "무엇"을, confidence 는 "실행해도 되는지"를 말한다. 두 축으로 분기한다
- 코드 예시

```python
action = response.answers["intent"]

if action.confidence < 0.6:
    route_to_support_agent(account_id)
elif action.choice == "check_balance":
    show_balance(account_id)
elif action.choice == "approve_transfer":
    if action.confidence > 0.85:
        approve_transfer(account_id)
    else:
        ask_user_to_confirm("Just to confirm: you would like to approve this transfer, is that correct?")
else:
    route_to_support_agent(account_id)
```

- Choice/Score 의 confidence 는 분포의 집중도를 요약할 뿐, 워크플로 전체의 정확성이나 실행 허가가 아니다
- 수용 가능한 대안이 여럿이면 확률이 퍼진다. 무해한 선호 선택에서는 낮은 confidence 가 선택을 무효화하지 않는다
- 쓰지 않는 분기의 불확실성은 무시한다

## 패턴 3: Composite scoring (복합 점수)

- 복잡한 판단을 독립 차원으로 쪼개 각각 Score 로 묻고, 코드가 가중치로 합친다
- 이력서 심사 예시. python_depth, team_leadership, system_design, generalist 를 5단계 Score 로 각각 묻는다
- 척도 길이가 다르면 합치기 전에 정규화한다. `score / (len(criteria) - 1)` 로 0~1 로 맞춘다
- 코드 예시

```python
py      = response.answers["python_depth"].score / 4
lead    = response.answers["team_leadership"].score / 4
arch    = response.answers["system_design"].score / 4
general = response.answers["generalist"].score / 4

ic_score = (0.40 * py) + (0.10 * lead) + (0.40 * arch) + (0.10 * general)
em_score = (0.15 * py) + (0.40 * lead) + (0.20 * arch) + (0.25 * general)
```

- 가중치는 코드에 있다. 상위 후보가 기대와 다르면 가중치를 바꾸고 다시 돌린다. 추론을 다시 할 필요가 없다
- 가중합은 "보완되는 선호"에 맞다. "심각한 위반 하나라도 있으면 탈락" 같은 규칙은 별도 조건으로 둔다
- Noul 도 섞을 수 있다. 문서 예시: `0.4 * answers_request.noul + 0.4 * citations_are_supported.noul + 0.2 * (1 - contradicts_context.noul)`
- 라벨이 있으면 확률들을 피처로 삼아 고전 ML 모델을 학습시킨다 (autoresearch 쿡북). 라벨이 없으면 비싼 추론 모델 앙상블로 라벨을 만든다

## 패턴 4: Intent routing (의도 라우팅)

- 들어오는 요청을 분류해 결정적 코드, 전문 LLM, 사람 중 최적 핸들러로 보낸다. 비싼 자원은 정말 필요한 요청에만 쓴다
- 문서 예시. intent(Choice: order_status, product_question, return_exchange, complaint) 와 complexity(Score 3단계) 를 한 요청에
- 코드 예시

```python
if intent.confidence < 0.5:
    return route_to_human_agent(ticket_id)

if intent.choice == "order_status":
    handle_order_status(ticket_id)            # 결정적 코드, LLM 없음
elif intent.choice == "product_question":
    handle_with_llm(ticket_id, PRODUCT_SPECIALIST)
elif intent.choice == "return_exchange":
    handle_with_llm(ticket_id, RETURNS_SPECIALIST)
elif intent.choice == "complaint":
    low_confidence = complexity.confidence < 0.5
    if complexity.score > 1 or low_confidence:
        route_to_human_agent(ticket_id)
    else:
        handle_with_llm(ticket_id, COMPLAINT_RESOLUTION)
```

- 보조 Score 에도 confidence 검사를 둔다. 복잡도를 확신 못 하면 사람에게

## 전체를 합친 예시 (문서의 triage_ticket)

- 결정적 상태는 모델 없이 처리 (`status == "closed"` 면 바로 반환)
- state 에는 질문에 필요한 구조화 맥락만 (티켓 메시지·발신자·링크, 고객 플랜·열린 주문, 민감 자격증명 목록)
- 한 요청에 topic(Choice, 구조화 criteria), requests_credentials / sender_identity_mismatch / unexpected_reward / refund_requested / mentions_open_order (Noul, 구조화 instructions 와 criteria), frustration(Score, 구조화 단계)
- 코드에서 조합
    - `spam_risk = 0.45 * requests_credentials + 0.30 * sender_identity_mismatch + 0.25 * unexpected_reward`
    - `0.4 < spam_risk < 0.6` 이거나 `topic.confidence < 0.75` 면 사람 검토
    - `spam_risk >= 0.6` 이면 격리
    - topic 별로 투기적 답을 골라 쓴다 (`refund_requested.noul >= 0.7`, `mentions_open_order.noul >= 0.7`)
    - `frustration.confidence >= 0.7 and frustration.score >= 1.5` 면 high priority

## 정책은 명시적으로, 원시 판단은 재사용 가능하게

- 가중치나 표시 필터를 바꾸는 일은 증거와 질문 의미가 그대로면 추론을 다시 돌릴 필요가 없다
- 타입 있는 출력은 인터페이스를 보장하지 진실을 보장하지 않는다. 대상 도메인에서 성능을 검증한다
- 질문과 임곗값 상수는 한 파일에 모은다. 사람이 검토할 가장 중요한 부분이다
