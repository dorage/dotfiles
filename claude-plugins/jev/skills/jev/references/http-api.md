# Jev HTTP API, 모델, 한도

출처: https://docs.typesafe.ai/api.md, https://docs.typesafe.ai/models.md (2026-10-01 기준).

## 엔드포인트

```http
POST https://api.typesafe.ai/v1/systemone
Authorization: Bearer <API_KEY>
Content-Type: application/json
```

- API 키는 https://console.typesafe.ai/keys 에서 만든다
- 모델 목록: `GET https://api.typesafe.ai/v1/models` (같은 Bearer 헤더). `models[]` 에 `name`, `description`, `release_date`
- 플레이그라운드: https://console.typesafe.ai/playground

## 요청 본문

- `state` (필수): string | object | array. 평가할 내용
- `model` (필수): string. `"jev-latest"` 권장
- `questions` (필수): `map<string, Question>`. 키는 사용자가 정하고 답은 같은 키로 돌아온다. 키는 모델에 전송되지 않는다

질문 와이어 포맷:

```json
{
  "state": "Help! My payouts have been failing for 3 days.",
  "model": "jev-latest",
  "questions": {
    "is_urgent": {
      "type": "noul",
      "instructions": "Does this convey urgency?",
      "criteria": { "true": "Explicitly time-sensitive", "false": "No urgency expressed" }
    },
    "department": {
      "type": "choice",
      "instructions": "Which team should handle this?",
      "criteria": {
        "billing": "Payments, invoicing, refunds",
        "technical": "Bugs, outages, integrations",
        "sales": "Pricing, upgrades, new accounts"
      }
    },
    "frustration": {
      "type": "score",
      "instructions": "How frustrated is the customer?",
      "criteria": ["Calm", "Frustrated", "Very angry"]
    }
  }
}
```

- `noul.criteria` 는 선택. `true`/`false` 각각 string | object | array
- `choice.criteria` 는 필수. `map<string, string | object | array | null>`. 최대 255 옵션
- `score.criteria` 는 필수. `array<string | object | array>`. 최소 2, 최대 10 단계
- `instructions` 는 모두 string | object | array

## 응답 본문

```json
{
  "model": "jev-1.13.0",
  "answers": {
    "is_urgent": { "type": "noul", "noul": 0.95 },
    "department": {
      "type": "choice",
      "choice": "billing",
      "probabilities": { "billing": 0.88, "technical": 0.12, "sales": 0.0 },
      "confidence": 0.81
    },
    "frustration": {
      "type": "score",
      "score": 1.05,
      "legend": { "0": "Calm", "1": "Frustrated", "2": "Very angry" },
      "probabilities": { "0": 0.0, "1": 0.95, "2": 0.05 },
      "confidence": 0.92
    }
  },
  "usage": { "input_tokens": 304, "output_tokens": 18 }
}
```

- `model` 은 실제로 답한 버전 ID. 별칭을 보냈어도 버전이 온다. 로그에 남겨 둔다
- Score 의 `probabilities` 와 `legend` 키는 단계 번호 문자열. Python SDK 는 정수 키로 바꿔 준다

## 오류

- `401 Unauthorized`: API 키 누락 또는 무효
- `422 Unprocessable Entity`: 요청 본문 검증 실패 (필수 필드 누락, 잘못된 질문). 본문에 문제 필드가 적혀 온다
- `429 Too Many Requests`: 레이트 리밋 초과. 지수 백오프로 재시도. `retry-after` 헤더가 있으면 따른다
- `529 Overloaded`: 일시 과부하. 잠시 뒤 재시도
- SDK 기본 재시도 정책이 429/529 를 자동 처리한다. HTTP 를 직접 쓰면 직접 백오프를 구현한다

## 모델과 한도 (jev-1.13.0)

- 가격: 입력 토큰당 과금. $0.042 / Mtok ($42 / Btok). 출력 토큰은 무료
- 레이트 리밋: 초당 100K 토큰, 초당 40 요청. 수요에 따라 예고 없이 바뀔 수 있다. 상향은 sales@typesafe.ai
- 컨텍스트: 요청당 64k 토큰 (state + 모든 질문 합계). state + 가장 긴 질문 하나는 32k 이내
- 입력: 텍스트만. string, JSON object, 텍스트 값 배열. 이미지·오디오·비디오 불가
- 지연: 대부분의 쿼리가 약 100ms (문서 표현은 "about 100 ms", 사례 지도는 150ms)

## 별칭

- `jev-latest` → `jev-1.13.0`. 최신 안정 공식 릴리스. SDK 기본값
- `jev-preview` → `jev-1.13.0`. 프리뷰가 있으면 `jev-latest` 보다 앞서 간다. 지금은 같다
- 별칭은 새 릴리스가 나오면 이동한다. 임곗값을 특정 버전에 맞춰 튜닝했다면 버전 ID 를 고정하고 자기 일정에 맞춰 옮긴다

## 커스터마이징과 데이터

- 고객 데이터로 파인튜닝하거나 LoRA 를 붙이지 않는다. 같은 가중치가 모든 계정을 서빙한다
- 도메인 적응은 요청으로 한다. 독점 내용은 `state` 에, 도메인 규칙과 경계 사례는 `instructions` 와 `criteria` 에
- 고객 요청·응답으로 학습하지 않는다. 엔터프라이즈는 zero data retention 가능 (https://docs.typesafe.ai/legal)

## 게이트웨이 경유 (Python SDK 문서 기준)

- OpenRouter: `base_url="https://openrouter.ai/api"`, `model="~typesafe/jev-latest"`, OpenRouter 키
- Vercel AI Gateway: `base_url="https://ai-gateway.vercel.sh/typesafe"`, `model="typesafe-ai/jev"`
- Pydantic AI Gateway: `base_url="https://gateway-us.pydantic.dev/proxy/typesafe"`, `model="jev-latest"`

## cURL 예시

```bash
curl -X POST https://api.typesafe.ai/v1/systemone \
  -H "Authorization: Bearer $TYPESAFE_API_KEY" \
  -H "Content-Type: application/json" \
  -d @- <<'EOF'
{
  "state": "Hi, I've been trying to connect my Stripe account for 3 days and the integration keeps failing. I'm losing sales. Please help ASAP.",
  "model": "jev-latest",
  "questions": {
    "urgency": { "type": "noul", "instructions": "Does this message express urgency?" }
  }
}
EOF
```
