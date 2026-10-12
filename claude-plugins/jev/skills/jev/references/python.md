# Jev Python SDK 사용법

출처: https://docs.typesafe.ai/sdk/python.md 와 하위 페이지 (SDK v0.7.2, 2026-09-26). HTTP 원형과 오류 코드는 `http-api.md` 에 있다.

## 설치

- 패키지 이름은 `typesafe-sdk` 이고, import 이름은 `typesafe_sdk` 이다.
- uv 로 설치한다.

```sh
uv add typesafe-sdk
```

- 문서는 pip 도 함께 보여 준다: `pip install typesafe-sdk`.
- HTTP/2 를 쓰려면 extra 를 붙인다: `uv add 'typesafe-sdk[http2]'`. 이 extra 는 v0.7.2 에서 추가됐다.
- 직렬화 라이브러리는 v0.7.0 부터 `pydantic` 이다. 이전에는 `msgspec` 이었다.
- HTTP 계층은 `httpx2` 이다. `timeout`, `transport`, `http_client` 타입이 모두 `httpx2` 타입이다.
- 지원 Python 버전은 3.10 이상이다 (퀵스타트 페이지 기준).

## 인증과 환경변수

- 환경변수 이름은 `typesafe_sdk.constants` 모듈 상수로 노출된다.
  - `API_KEY_ENV = 'TYPESAFE_API_KEY'` 는 API 키다. 필수이고 기본값이 없다.
  - `BASE_URL_ENV = 'TYPESAFE_BASE_URL'` 는 API 루트 URL 이다.
  - `DEFAULT_MODEL_ENV = 'TYPESAFE_DEFAULT_MODEL'` 는 기본 모델이다.
  - `LOG_LEVEL_ENV = 'TYPESAFE_LOG_LEVEL'` 는 `typesafe_sdk` 로거 레벨이다. import 시점에 한 번 적용되고 기본값은 unset 이다.
- 기본값 상수는 다음과 같다.
  - `DEFAULT_BASE_URL = 'https://api.typesafe.ai'`
  - `DEFAULT_MODEL = 'jev-latest'`
  - `DEFAULT_TIMEOUT = 10.0` 이다. HTTP 동작 하나당 초 단위다.
- 명시 인자가 환경변수보다 우선한다. 비어 있거나 공백뿐인 환경변수 값은 무시된다.
- API 키 앞뒤 공백과 개행은 제거된다. 빈 키, 내부 공백, 제어 문자, 비 ASCII 문자는 요청 전에 거부된다.
- `api_key=""` 처럼 명시적으로 빈 키를 주면 환경변수로 대체되지 않는다.
- 잘못된 API 키는 클라이언트 생성 시점에 `TypeSafeError` 를 던진다. 요청이나 재시도 전에 실패한다. 키 값은 로그 예외에 남지 않는다 (v0.7.1).
- `TYPESAFE_LOG_LEVEL` 값은 `debug`, `info`, `warning`, `error`, `off` 중 하나다.
  - `info` 는 요청마다 요약 한 줄을 남긴다.
  - `debug` 는 요청과 응답의 헤더와 본문까지 남긴다.
  - authorization, API 키, 쿠키, 이름에 `token` 이나 `secret` 이 들어간 헤더는 가려진다. 요청과 응답 본문은 가려지지 않는다.
- 표준 logging 으로도 설정한다: `logging.getLogger("typesafe_sdk").setLevel(logging.DEBUG)`.
- 재시도 기본값은 `RetryPolicy()` 기본값이다. 아래 재시도 절에 정리했다.

## 클라이언트 생성

동기 클라이언트 시그니처는 다음과 같다.

```python
TypeSafeClient(
    *,
    api_key: str | None = None,
    model: str | None = None,
    retry: RetryPolicy | None = None,
    timeout: float | httpx2.Timeout | None = None,
    headers: Mapping[str, str] | None = None,
    transport: httpx2.BaseTransport | None = None,
    http_client: httpx2.Client | None = None,
    base_url: str | None = None,
)
```

비동기 클라이언트 `AsyncTypeSafeClient` 는 같은 인자를 받는다. 다른 점은 `transport: httpx2.AsyncBaseTransport | None` 과 `http_client: httpx2.AsyncClient | None` 두 타입뿐이다.

- 모든 인자는 keyword-only 다.
- `api_key` 를 생략하면 `TYPESAFE_API_KEY` 를 읽는다.
- `model` 을 생략하면 `TYPESAFE_DEFAULT_MODEL` 을 읽고, 그것도 없으면 `jev-latest` 를 쓴다.
- `retry` 를 생략하면 `RetryPolicy` 기본값을 쓴다. 재시도를 끄려면 `RetryPolicy(max_retries=0)` 을 넘긴다.
- `timeout` 을 생략하면 `http_client.timeout` 을 물려받고, `http_client` 가 없으면 SDK 기본값 `10.0` 초를 쓴다.
- `headers` 는 모든 요청에 추가할 헤더다.
- `transport` 와 `http_client` 는 동시에 줄 수 없다. 둘 다 주면 `ValueError` 다. 둘 다 SDK 클라이언트가 닫힐 때 함께 닫힌다.
- `base_url` 을 생략하면 `TYPESAFE_BASE_URL` 을 읽는다. 다른 URL 은 TypeSafe OpenAPI 스펙을 따라야 한다.
- 생성 시 `TypeSafeError` 가 나는 경우는 API 키 누락이나 무효, 잘못된 timeout 이다.

컨텍스트 매니저와 종료 방법은 다음과 같다.

- 동기는 `with TypeSafeClient() as client:` 로 쓴다. 수동 종료는 `client.close() -> None` 이다.
- 비동기는 `async with AsyncTypeSafeClient() as client:` 로 쓴다. 수동 종료는 `await client.aclose()` 이다.
- 두 종료 메서드 모두 넘겨받은 `http_client` 까지 닫는다.

HTTP/2 와 게이트웨이 설정 방법은 다음과 같다.

- HTTP/2 는 `TypeSafeClient(http_client=httpx2.Client(http2=True))` 또는 `AsyncTypeSafeClient(http_client=httpx2.AsyncClient(http2=True))` 로 켠다.
- 문서가 보여 주는 게이트웨이 조합은 세 가지다. 셋 다 `api_key`, `base_url`, `model` 을 명시한다.
  - OpenRouter 는 `base_url="https://openrouter.ai/api"`, `model="~typesafe/jev-latest"`, 키는 `OPENROUTER_API_KEY` 다.
  - Vercel AI Gateway 는 `base_url="https://ai-gateway.vercel.sh/typesafe"`, `model="typesafe-ai/jev"`, 키는 `AI_GATEWAY_API_KEY` 다.
  - Pydantic AI Gateway 는 `base_url="https://gateway-us.pydantic.dev/proxy/typesafe"`, `model="jev-latest"`, 키는 `PYDANTIC_AI_GATEWAY_API_KEY` 다.

모델 목록 조회 방법은 다음과 같다.

- `client.models` 는 cached property 다. 동기는 `Models`, 비동기는 `AsyncModels` 를 돌려준다.
- `client.models.list(*, retry=None, timeout=None, extra_headers=None) -> ListModelsResponse` 이다. 비동기는 `await` 로 부른다.
- `list` 의 `extra_headers` 로 인증, SDK 식별, `Accept` 헤더는 덮어쓸 수 없다.

## 질문 객체

질문은 세 가지 pydantic 모델이고, 모두 `typesafe_sdk` 에서 import 한다.

- `Noul` 은 예/아니오 질문이다.
  - `type: Literal['noul']` 는 기본값이 `"noul"` 이라서 직접 넣지 않는다.
  - `instructions: JSONContent | None = None` 는 질문 본문이다. 텍스트, JSON 객체, 배열을 받는다.
  - `criteria: NoulCriteria | None = None` 는 선택 항목이다.
- `NoulCriteria` 는 TypedDict 이고 키는 `true`, `false` 두 개다.
  - 각 값 타입은 `JSONContent | None` 이다. `None` 이면 그 결과를 설명하지 않는다.
- `Choice` 는 이름 붙은 선택지 중 하나를 고르는 질문이다.
  - `criteria: Mapping[str, JSONContent | None]` 는 필수다. 키가 라벨이고 값이 설명이다. 설명이 필요 없으면 `None` 을 넣는다.
  - `instructions: JSONContent | None = None`
- `Score` 는 순서 있는 루브릭으로 점수를 매기는 질문이다.
  - `criteria: Sequence[JSONContent]` 는 필수다. 비어 있으면 안 되는 순서 리스트이고, 0점부터 한 칸씩 설명한다.
  - `instructions: JSONContent | None = None`
  - v0.6.0 부터 리스트로 받는다. 그 전에는 정수 키 dict 였다.
- 별칭 타입은 다음과 같다.
  - `Question = Noul | Choice | Score | QuestionModel`
  - `Questions = Mapping[str, Question]`
  - `JSONValue = str | int | float | bool | Sequence[JSONValue | None] | Mapping[str, JSONValue | None]`
  - `JSONContent = str | Mapping[str, JSONValue | None] | Sequence[JSONValue | None]`

질문 식별 방법은 다음과 같다.

- 질문 객체 안에는 `id` 필드가 없다. `questions` 매핑의 키가 질문 이름이고, 답도 같은 키로 돌아온다.
- `options`, `levels` 라는 필드는 없다. Choice 선택지와 Score 단계는 모두 `criteria` 로 표현한다.
- Score 단계 설명은 응답의 `ScoreAnswer.legend` 로 돌아온다.

dict 형태로 질문하는 방법은 다음과 같다.

- `type` 키에 `"noul"`, `"choice"`, `"score"` 중 하나를 넣는다. 객체와 dict 를 한 요청에 섞어도 된다.
- `NoulModel` 은 `type: Literal['noul']`, `instructions: NotRequired[JSONContent | None]`, `criteria: NotRequired[NoulCriteria | None]` 이다.
- `ChoiceModel` 은 `type: Literal['choice']`, `instructions: NotRequired[JSONContent | None]`, `criteria: Mapping[str, JSONContent | None]` 이다.
- `ScoreModel` 은 `type: Literal['score']`, `instructions: NotRequired[JSONContent | None]`, `criteria: Sequence[JSONContent]` 이다.
- `QuestionModel = NoulModel | ChoiceModel | ScoreModel`
- dict 에 모르는 필드를 넣으면 그대로 전송된다. 문서 예시는 `"weight": 2` 를 쓴다. 이 방법은 앞선 호환용이고, 타입 검사 오류는 무시하라고 안내한다.

구조화된 JSON 을 쓰는 방법은 다음과 같다.

- `instructions`, Choice `criteria` 값, Score `criteria` 항목, `NoulCriteria` 값은 모두 `JSONContent` 이다. 문자열 대신 객체나 배열을 넣을 수 있다.
- HTTP API 문서는 질문은 한 필드에, 참조할 데이터는 다른 필드에 두라고 권한다. 데이터 필드는 백틱으로 이름을 불러 가리킨다.

```python
Noul(
    instructions={
        "potential_duplicate": {"name": "John Smith", "location": "Oakland, California"},
        "question": "Is the resume for the same person as `potential_duplicate`?",
    }
)
```

## 호출

질문은 `system_one` 메서드로 한다. 시그니처는 다음과 같다.

```python
client.system_one(
    state: JSONContent,
    questions: Mapping[str, Question],
    *,
    model: str | None = None,
    retry: RetryPolicy | None = None,
    timeout: float | httpx2.Timeout | None = None,
    extra_headers: Mapping[str, str] | None = None,
    extra_body: Mapping[str, JSONValue | None] | None = None,
    response_model: type[ResponseT] | None = None,
) -> SystemOneResponse | ResponseT
```

- 비동기 클라이언트에서는 `await client.system_one(...)` 로 부른다. 인자는 같다.
- `state` 와 `questions` 는 위치 인자로도, 키워드로도 넘길 수 있다.
- `state` 는 텍스트, JSON 객체, 배열 중 하나다. `None` 은 안 되지만 객체 안의 값은 `None` 이어도 된다.
- `questions` 는 비어 있으면 안 된다. 값은 질문 객체나 dict 다.
- `model` 이 `None` 이면 클라이언트 기본 모델을 쓴다.
- `retry` 와 `timeout` 은 이번 호출에만 클라이언트 설정을 덮어쓴다. `timeout` 은 초 단위다.
- `extra_headers` 는 이번 호출에 추가할 헤더다.
- `extra_body` 는 `state`, `model`, `questions` 를 넣은 뒤 본문 최상위에 얕게 병합된다. 같은 키가 있으면 나중 값이 이긴다. 객체 값은 깊은 병합 없이 통째로 바뀐다.
- `response_model` 에 pydantic `BaseModel` 타입을 주면 그 타입으로 돌려준다 (v0.7.0).
  - `SystemOneResponse` 를 상속하면 `result.billing` 같은 속성 접근과 `result.nouls["billing"]` 가 함께 된다.
  - 상속하지 않은 `BaseModel` 이면 응답 JSON 구조 그대로 정의한다. 예시는 `answers: BillingAnswers` 필드를 둔다.
- 호출 시 `TypeSafeError` 가 나는 경우는 questions 가 비었거나 Score criteria 리스트가 빈 경우다.

## 응답

`system_one` 의 기본 반환 타입은 `SystemOneResponse` 다. pydantic 모델이고 설정은 `extra="ignore", frozen=True, strict=True` 이다.

- `model: str` 는 실제로 답한 모델이다.
- `usage: Usage` 는 토큰 사용량이다.
- `answers: dict[str, Answer]` 는 모든 답을 질문 이름으로 묶은 것이다.
- `nouls: dict[str, NoulAnswer]` 는 cached property 다.
- `choices: dict[str, ChoiceAnswer]` 는 cached property 다.
- `scores: dict[str, ScoreAnswer]` 는 cached property 다.
- `request_id: str` 는 `x-typesafe-request-id` 응답 헤더 값이다.
- `raw_http_response: httpx2.Response` 는 원본 응답이다. 상태, 헤더, 본문을 볼 수 있다.

답 타입은 다음과 같다.

- `NoulAnswer`
  - `type: Literal['noul']`
  - `noul: float` 는 예일 확률이고 0 부터 1 사이다. 1 에 가까우면 예, 0 에 가까우면 아니오, 0.5 근처면 불확실하다.
  - `confidence` 필드는 없다.
- `ChoiceAnswer`
  - `type: Literal['choice']`
  - `choice: str` 는 criteria 중 확률이 가장 높은 라벨이다.
  - `confidence: float` 는 0 부터 1 사이다. 문서는 낮은 값을 검토 대상으로 표시하라고 권한다.
  - `probabilities: dict[str, float]` 는 라벨별 확률이고 합은 대략 1 이다.
- `ScoreAnswer`
  - `type: Literal['score']`
  - `score: float` 는 확률 가중 평균이고 정수 단계 사이 값이 나올 수 있다.
  - `confidence: float` 는 0 부터 1 사이다.
  - `legend: dict[int, str | dict[str, Any] | list[Any]]` 는 정수 점수별 루브릭 설명이다.
  - `probabilities: dict[int, float]` 는 정수 점수별 확률이다.
- `Answer` 는 `NoulAnswer | ChoiceAnswer | ScoreAnswer` 이고 `type` 으로 구분한다.
- `Usage`
  - `input_tokens: int | None = None`
  - `output_tokens: int | None = None`
  - API 가 보고하지 않으면 `None` 이다.
- `ListModelsResponse`
  - `models: tuple[ModelMetadata, ...]`
  - `request_id`, `raw_http_response` 를 함께 가진다.
- `ModelMetadata`
  - `name: str` 는 요청 `model` 에 넣을 수 있는 이름이나 별칭이다.
  - `description: str`
  - `release_date: str` 는 YYYY-MM-DD 형식이다.

앞선 호환 규칙은 다음과 같다.

- 모르는 답 종류는 경고 로그를 남기고 건너뛴다. 전체를 보려면 `result.raw_http_response.json()["answers"]` 를 읽는다.
- 알려진 응답의 모르는 필드는 무시된다.

## 재시도와 예외

`RetryPolicy` 는 dataclass 다. 시그니처와 기본값은 다음과 같다.

```python
RetryPolicy(
    max_retries: int = 2,
    backoff_initial: float = 0.5,
    backoff_max: float = 5.0,
    backoff_jitter: float = 0.25,
    http_statuses: set[int] = {408, 429, *range(500, 600)},
    respect_retry_after: bool = True,
    api_connection_error: bool = True,
    api_timeout_error: bool = True,
    exceptions: set[type[BaseException]] = set(),
    predicate: Callable[[BaseException], bool] | None = None,
    timeout: float | None = 30.0,
)
```

- `max_retries` 는 첫 시도 뒤 최대 재시도 횟수다. `0` 이면 재시도하지 않는다.
- `backoff_initial` 은 첫 대기 초다. 시도마다 두 배가 되고 `backoff_max` 에서 멈춘다. 0 이면 대기가 꺼진다.
- `backoff_max` 는 최대 대기 초다. 0 이면 대기가 꺼진다.
- `backoff_jitter` 는 대기마다 무작위로 빼는 비율이다. 0 과 1 사이다.
- `http_statuses` 는 재시도할 상태 코드다. 기본은 408, 429, 500 부터 599 까지다. 따라서 529 도 재시도된다.
- `respect_retry_after` 가 참이면 `Retry-After` 와 `retry-after-ms` 응답 헤더를 따른다. 최대 상한 값은 (문서 미기재).
- `api_connection_error` 가 참이면 `TypeSafeAPIConnectionError` 를 재시도한다.
- `api_timeout_error` 가 참이면 `TypeSafeAPITimeoutError` 를 재시도한다.
- `exceptions` 는 기본 규칙에 더해 재시도할 예외 타입이다.
- `predicate` 는 예외를 받아 `True` 를 돌려주면 추가로 재시도한다.
- `timeout` 은 SDK 호출 하나당 전체 재시도 예산 초다. 첫 시도와 대기를 모두 포함한다. `None` 이면 제한이 없다. 다음 대기가 예산에 닿거나 넘으면 마지막 오류를 다시 던진다.
- 클라이언트 `retry=` 로 주거나 호출마다 `retry=` 로 준다. 문서 예시는 `RetryPolicy(max_retries=3, backoff_max=0.2, timeout=1.0)` 이다.

예외 계층은 다음과 같다.

- `TypeSafeError(Exception)` 는 SDK 실패의 기반 클래스다. 키 오류, 빈 questions 도 이 타입이다.
- `TypeSafeAPIError(TypeSafeError)` 는 실패한 HTTP 응답이다.
  - 속성은 `status`, `body`, `headers`, `endpoint`, `request_id` 다.
  - `body` 는 JSON 오류 본문이나 평문이고, 본문이 비면 `None` 이다.
  - `endpoint` 는 자격 정보, 쿼리, fragment 를 뺀 메서드와 URL 이다.
  - `request_id` 는 `x-typesafe-request-id` 헤더 값이고 없으면 `None` 이다.
- 상태별 하위 클래스는 모두 `TypeSafeAPIError` 를 상속한다.
  - `TypeSafeBadRequestError` 는 400 이다.
  - `TypeSafeAuthenticationError` 는 401 이다.
  - `TypeSafePermissionDeniedError` 는 403 이다.
  - `TypeSafeNotFoundError` 는 404 이다.
  - `TypeSafeUnprocessableEntityError` 는 422 이다.
  - `TypeSafeRateLimitError` 는 429 이다. `retry_after_ms` 속성에 서버가 요구한 대기 밀리초가 들어 있고, 없으면 `None` 이다.
  - `TypeSafeInternalServerError` 는 5xx 다.
- `TypeSafeAPIConnectionError(TypeSafeError, ConnectionError)` 는 HTTP 응답 없이 실패한 요청이다.
- `TypeSafeAPITimeoutError(TypeSafeAPIConnectionError, TimeoutError)` 는 시간 초과다. `timeout` 속성에 사용한 설정이 들어 있다.
- `TypeSafeAPIResponseValidationError(TypeSafeAPIError)` 는 성공 응답인데 본문 구조가 틀린 경우다. `field_path` 에 `answers.tone.confidence` 같은 점 경로가 들어 있다.
- 예외와 응답은 pickle 가능하다 (v0.6.0).

## 완전한 예제 (동기)

```python
from typesafe_sdk import (
    Choice,
    Noul,
    Score,
    TypeSafeAPIError,
    TypeSafeClient,
)

# 판단 기준값은 예시다. 문서는 낮은 confidence 를 검토 대상으로 표시하라고만 권한다.
CONFIDENCE_FLOOR = 0.7

state = {
    "ticket_id": "T-1042",
    "channel": "email",
    "messages": [
        {"from": "customer", "text": "I was charged twice. Please fix this ASAP."},
        {"from": "agent", "text": "Sorry about that. Can you share the invoice number?"},
        {"from": "customer", "text": "INV-778. This is the second time this month."},
    ],
}

questions = {
    "billing": Noul(
        instructions="Is this ticket about billing?",
        criteria={"true": "Payments, invoices, refunds", "false": "Anything else"},
    ),
    "tone": Choice(
        instructions="What is the customer's tone in `messages`?",
        criteria={"calm": None, "frustrated": None, "angry": None},
    ),
    "urgency": Score(
        instructions="How urgent is this ticket?",
        criteria=["can wait", "this week", "today"],
    ),
}

with TypeSafeClient() as client:
    try:
        result = client.system_one(state, questions)
    except TypeSafeAPIError as error:
        print("API error", error.status, error.request_id)
        raise

billing = result.nouls["billing"]
tone = result.choices["tone"]
urgency = result.scores["urgency"]

if tone.confidence < CONFIDENCE_FLOOR or urgency.confidence < CONFIDENCE_FLOOR:
    print("review", tone.probabilities, urgency.probabilities)
elif billing.noul > 0.5 and urgency.score >= 1.5:
    print("route to billing, priority", tone.choice)
else:
    print("normal queue", tone.choice, round(urgency.score, 2))

print(result.model, result.usage.input_tokens, result.usage.output_tokens, result.request_id)
```

## 완전한 예제 (비동기)

```python
import asyncio

from typesafe_sdk import (
    AsyncTypeSafeClient,
    Choice,
    ChoiceAnswer,
    Noul,
    NoulAnswer,
    RetryPolicy,
    Score,
    ScoreAnswer,
    SystemOneResponse,
    TypeSafeRateLimitError,
)

# 판단 기준값은 예시다.
CONFIDENCE_FLOOR = 0.7


class TicketResponse(SystemOneResponse):
    billing: NoulAnswer
    tone: ChoiceAnswer
    urgency: ScoreAnswer


async def main() -> None:
    state = {
        "ticket_id": "T-1042",
        "customer": {"plan": "pro", "tenure_months": 14},
        "message": "I was charged twice. Please fix this ASAP.",
    }
    async with AsyncTypeSafeClient(retry=RetryPolicy(max_retries=3)) as client:
        try:
            result = await client.system_one(
                state=state,
                questions={
                    "billing": Noul(instructions="Is this ticket about billing?"),
                    "tone": Choice(
                        instructions="What is the customer's tone?",
                        criteria={"calm": None, "frustrated": None, "angry": None},
                    ),
                    "urgency": Score(
                        instructions="How urgent is this ticket?",
                        criteria=["can wait", "this week", "today"],
                    ),
                },
                response_model=TicketResponse,
            )
        except TypeSafeRateLimitError as error:
            print("rate limited, retry after ms:", error.retry_after_ms)
            return

    if result.tone.confidence < CONFIDENCE_FLOOR:
        print("tone uncertain, send to human", result.tone.probabilities)
    elif result.billing.noul > 0.5 and result.tone.choice == "angry":
        print("escalate billing", result.urgency.legend)
    else:
        print("auto reply", result.tone.choice, result.urgency.score)


asyncio.run(main())
```
