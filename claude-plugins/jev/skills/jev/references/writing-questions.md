# Jev 질문 잘 쓰는 법과 피해야 할 것

출처: https://docs.typesafe.ai/concepts/how-to-build-with-system-one.md, https://docs.typesafe.ai/model-jaggedness/jev-1.13.md (2026-09-17 검토본), 각 primitive 페이지.

## 설계 원칙 다섯 가지

- 제어 흐름, 결정적 규칙, 부수효과는 코드에 둔다. 모델은 공통 상식 판단이 필요한 자리에만 넣는다
- 넓은 판단을 좁고 타입 있는 질문으로 쪼갠다. instructions 와 criteria 를 명시적으로 쓴다
- 각 질문에 필요한 맥락만 준다
- 확률과 confidence 로 "실행 / 검토 요청 / 상위로 넘김"을 가른다
- 독립적인 질문은 한 요청에 묶고, 답은 코드에서 조합한다

## 질문 쪼개기 (가장 중요한 개념)

- "1초 안에 아는 사람이 내릴 수 있는 판단"을 하나씩 묻는다
    - 좋은 예: "Does this message convey urgency?"
    - 나쁜 예: "Analyze this message and determine the best course of action" (느린 추론이 필요하다는 신호)
- 넓은 질문은 여러 판단을 하나의 답 뒤에 숨긴다. 원자적 질문은 그 판단을 드러내서 코드에서 점검·조정·조합할 수 있게 한다
- 스팸 판정 분해 예시. "Is `message` spam?" 하나 대신
    - "Does `message.body` ask the recipient to provide a password or other login credential?"
    - "Does `message.body` claim the recipient received an unexpected prize, payment, or reward?"
    - "Does `message.subject` or `message.body` pressure the recipient to act quickly?"
    - "Does the organization named in `message.sender.display_name` conflict with the domain in `message.sender.email`?"
    - "Does `message.links[0].text` conceal or misrepresent the destination in `message.links[0].url`?"
- 툴콜 트레이스 검증도 같은 식이다. "Is `trace.tool_calls` correct?" 하나 대신 툴 선택 적절성, 인자가 요청과 일치하는지, 스키마에 맞는지, 결과 ID 가 호출 ID 와 맞는지, 좌표·날짜·단위가 맞는지를 각각 Noul 로 묻는다
- 쪼개도 왕복은 늘지 않는다. 같은 state 위의 질문은 병렬로 돈다
- "원자적"이 "글자 그대로의 사실 추출"이나 "한 문장 제한"을 뜻하지는 않는다. 범위가 정해진 행동 선택이나 맥락 해석도 하나의 판단이다. 판단되는 관계를 깨뜨리지 않는 선에서 독립적으로 유용한 차원을 나눈다

## state 구성

- 대부분의 요청은 객체로 보낸다. 각 부분에 설명적인 이름을 붙이고 관계를 드러낸다
- 문자열은 텍스트 한 조각만 필요할 때 쓴다
- 배열은 메시지 시퀀스나 레코드 목록에 쓴다
- 결정에 필요한 맥락만 넣는다. 코드에서 먼저 조회·필터링한다
    - 닫힌 티켓이면 모델을 부르지 않는다
    - 배송 완료 주문은 빼고 열린 주문만 넣는다
- 모델 가중치 안의 지식에 기대지 않는다. 정책, 레코드, 참고자료를 state 에 넣는다
- 텍스트만 받는다. 이미지·오디오·비디오는 코드에서 텍스트나 구조화 필드로 바꾼 뒤 보낸다
- 영어가 주 학습 언어다. 한국어를 포함한 CJK 는 받지만 정확도가 낮다. 비영어 작업은 자기 데이터로 테스트하고 confidence 를 더 보수적으로 본다

## instructions 쓰기

- 질문 형식이든 판단할 진술 형식이든 된다. 자기 데이터로 둘 다 시도해 본다
- Noul 은 높은 값이 "예"가 되게 쓴다
    - "Does the message contain personal data?" 는 명확하다
    - "Is the message free of personal data?" 는 의미가 뒤집혀 코드가 반대로 읽게 된다
- 한 Noul 에 조건 하나만. "Is the customer angry and asking for a refund?" 는 둘로 나눈다
- 예/아니오 경계를 모호하지 않게 쓴다. "any Python experience" 처럼 중간 지대가 없는 표현이 좋다
- 경계가 미묘하면 `criteria` 에 `true`/`false` 설명을 붙인다. 붙이고 안 붙이고를 자기 문서로 비교해 나은 쪽을 쓴다
- Score 단계는 "상황"으로 쓴다. 각 단계는 따로 평가되고 모델은 단계 번호나 이웃 단계를 보지 않는다
    - "worse than the previous level" 은 의미가 없다
    - 숫자만 단계로 쓰면 ("0", "1", "2") 모델이 맞출 것이 없어 확률이 흩어진다. 문서 실측: 정렬 어긋남 리포트가 서술형 단계에서는 0.0 / 1.0 인데 숫자 단계에서는 0.55 / 0.33
- 단계는 구분해 서술할 수 있는 만큼만. 셋이면 충분할 때가 많다. 최대 10
- 드물지만 다르게 다뤄야 하는 극단은 자기 단계를 준다. "very angry" 로 끝나는 척도에 "abusive or threatening" 을 추가하는 식
- 중간이 전혀 없고 몇 개의 이산 범주면 Score 대신 Choice 나 Noul 여러 개를 쓴다
- Choice 옵션 설명은 옵션끼리 구분되게 쓴다. 옵션 이름과 설명이 모두 모델에 전송된다
- 옵션 이름이 자명하면 설명을 `null` 로 둘 수 있다 (`{"calm": null, "frustrated": null, "angry": null}`)

## 피해야 할 것 (jev-1.13 jaggedness)

- 글자 그대로 읽기
    - 쓴 질문에 답하지, 의도한 질문에 답하지 않는다. 범위 지정어, 부정, 암묵적 조건을 액면대로 읽는다
    - 틀린 답을 보고 "사실 이런 뜻이었는데"라고 설명하게 되면, 그 설명이 instructions 에 빠진 반쪽이다
    - 해석이 불가피하면 두 개의 문자 그대로의 질문으로 나누고 코드에서 합친다
- 수학과 숫자
    - 계산기가 아니다. 모든 산술은 코드에서 한다
    - 세기(counting)가 불안정하다. 글자 수, 단어 등장 횟수, 긴 목록의 항목 수 모두. 셀 단위를 정규식이나 파서가 찾을 수 있으면 모델이 할 일이 없다
    - 세어야 하면 코드가 후보를 순회하며 항목마다 Noul 하나씩 묻고 코드가 더한다
    - 수치 표현보다 의미 표현에 강하다. 색은 hex 보다 영어 이름, 저수준 어셈블리보다 고수준 언어
    - Score 의 기댓값으로 두 단계 사이의 정확한 크기를 복원하지 않는다. 임곗값 통과 여부에만 쓴다
- 날짜·시간 비교
    - 날짜를 순서 있는 양이 아니라 텍스트로 읽는다. 어느 날짜가 먼저인지, 간격, 윈도우 포함 여부가 불안정하다
    - 추출은 모델, 산술은 코드. 월·일·연도는 각각 닫힌 집합이라 Choice 로 추출하고 "not stated" 옵션을 둔다. 코드가 날짜를 조립하고 순서·기간·요일을 계산한다 (date extraction 쿡북)
- 간접 참조
    - 이중 부정, 속성의 속성, 여러 홉의 추론은 정확도가 떨어진다
    - 최대한 직접적으로 쓰고 state 의 관련 부분을 이름으로 가리킨다
- 무관한 내용으로 가득한 큰 state
    - 결정과 무관한 내용이 늘수록 정확도가 떨어진다 (context rot)
    - 코드에서 먼저 조회·필터링한다. 코드로 못 거르면 Noul 로 관련성을 먼저 거른다 (classifying RAG passages 쿡북)
- 적대적 내용
    - state 는 데이터이고 모델은 이를 적대적으로 보지 않는다. 주입된 지시, 오도하는 프레이밍, 자기 분류를 주장하는 텍스트가 답을 움직일 수 있다
    - criteria 를 명시적으로 쓰고 배포 전에 엣지 케이스를 테스트한다
- instructions 와 criteria 의 모순
    - `true` 가 "아니오"를, `false` 가 "예"를 뜻하게 쓰면 성능이 떨어진다
    - criteria 를 instructions 의 연장으로 취급해 둘을 정렬한다
- 구조적 불변식 기대
    - 같은 질문을 Noul 로 묻고 yes/no Choice 로 물으면 수치가 다르다. 문서 실측: Noul 0.22 인데 Choice yes 0.01 / no 0.99 / confidence 0.97
    - 질문과 그 부정을 두 Noul 로 물으면 합이 1 이 아니다. 실측: refund 0.72 + not_refund 0.47 = 1.19
    - Noul 로 튜닝한 임곗값을 Choice 로 옮기지 않는다. 별개 질문 사이의 산술 항등식을 기대하지 않는다
- 생성
    - 텍스트를 생성하도록 학습되지 않았다. Choice 를 연쇄해 강제하면 잘 안 되고 느리다
    - 추출은 정규식이나 생성 모델로 후보를 뽑고 Jev 가 고르게 한다. 답 공간이 유한하면 값을 묻지 말고 옵션 중 선택을 묻는다

## 요약 체크리스트

- 코드가 정확히 계산할 수 있는 것을 모델에 묻고 있지 않은가
- 한 질문 안에 여러 판단을 숨기고 있지 않은가
- 여러 층의 간접 참조가 필요한 System Two 작업은 아닌가
- 질문에 필요한 것보다 많은 맥락을 state 에 넣고 있지 않은가
- 질문과 임곗값 상수를 한 파일에 모아 사람이 검토하기 쉽게 했는가
- 자기 데이터의 대표 케이스로 테스트했는가. 실패하면 state, 질문, 후보, 답, 조합, 결과를 따로 보고 "증거 부족 / 모델 오류 / 코드 오류 / 서비스 장애"를 구분했는가
- 쿡북의 임곗값과 수치는 평가할 예시이지 보편 규칙이 아니다
- 웹앱에서는 API 키를 서버 쪽에 둔다
