# Jev TypeScript SDK 사용법

출처: https://docs.typesafe.ai/sdk/javascript.md 와 하위 API 페이지 (SDK v0.6.0, 2026-09-15). HTTP 원형과 오류 코드는 `http-api.md` 에 있다.

## 설치

- 패키지 이름은 `@typesafe-ai/sdk` 다.
- 문서는 npm 명령만 보여 준다: `npm install @typesafe-ai/sdk`. bun 에서는 아래처럼 설치한다.

```sh
bun add @typesafe-ai/sdk
```

- 런타임 요구사항은 Node.js 20 이상이다. Bun 지원 여부는 (문서 미기재).
- 패키지에 ESM, CommonJS, TypeScript 선언이 모두 들어 있다.
- 생성자는 지원하지 않는 런타임에서 예외를 던진다. 브라우저에서는 `dangerouslyAllowBrowser: true` 가 없으면 막힌다.
- v0.6.0 부터 Score `criteria` 는 순서 배열이다. 그 전에는 정수 키 객체였다.

## 인증과 환경변수

- `ENV` 상수 객체가 환경변수 이름을 담고 있다. 명시 옵션이 환경변수보다 우선한다.
  - `ENV.apiKey = "TYPESAFE_API_KEY"` 는 필수 API 키다. `apiKey` 를 생략했을 때 쓴다.
  - `ENV.baseURL = "TYPESAFE_BASE_URL"` 의 기본값은 `https://api.typesafe.ai` 다.
  - `ENV.defaultModel = "TYPESAFE_DEFAULT_MODEL"` 의 기본값은 `jev-latest` 다.
  - `ENV.logLevel = "TYPESAFE_LOG_LEVEL"` 의 기본값은 `warn` 이다.
- `EnvVar` 타입은 `typeof ENV[keyof typeof ENV]` 다.
- 비어 있거나 공백뿐인 환경변수 값은 무시된다.

`TypeSafeClientConfig` 필드는 모두 선택이다.

- `apiKey?: string` 는 필수 키다. 생략하면 `TYPESAFE_API_KEY` 를 읽는다.
- `baseURL?: string` 는 생략하면 `TYPESAFE_BASE_URL`, 그다음 `https://api.typesafe.ai` 를 쓴다.
- `defaultModel?: string` 는 생략하면 `TYPESAFE_DEFAULT_MODEL`, 그다음 `jev-latest` 를 쓴다.
- `timeout?: number` 는 시도 하나당 밀리초다. 기본값은 `10000` 이다. 전체 재시도 예산은 없다.
- `retry?: Partial<RetryPolicy>` 는 일부만 덮어쓴다. 빠진 필드는 `RetryPolicy` 기본값을 쓴다.
- `defaultHeaders?: Record<string, string>` 는 추가 헤더다. 호출별 헤더가 우선한다.
- `fetch?: Fetch` 의 기본값은 전역 `fetch` 다. 전송 설정이나 테스트용이다.
- `logger?: Logger` 의 기본값은 접두어가 붙은 `console` 이다. `logLevel` 이상만 남긴다.
- `logLevel?: LogLevel` 는 생략하면 `TYPESAFE_LOG_LEVEL`, 그다음 `warn` 을 쓴다.
  - `info` 는 요청 요약을 남기고, `debug` 는 헤더와 본문까지 남긴다.
  - 알려진 인증 헤더는 가려지고 본문은 가려지지 않는다.
- `dangerouslyAllowBrowser?: boolean` 의 기본값은 `false` 다. 켜면 페이지 사용자에게 API 키가 노출된다.
- 문서에 `maxRetries` 라는 최상위 옵션은 없다. 재시도 횟수는 `retry: { maxRetries }` 로 준다.

관련 타입은 다음과 같다.

- `type LogLevel = "debug" | "info" | "warn" | "error" | "off"`
- `const LOG_LEVELS: readonly LogLevel[]` 는 가장 자세한 것부터 나열한다.
- `type Fetch = (input: string, init?: RequestInit) => Promise<Response>`
- `interface Logger` 는 `debug`, `info`, `warn`, `error` 메서드를 가진다. 각 시그니처는 `(message: string, ...args: unknown[]) => void` 이고 `console` 과 호환된다.

`TypeSafeClient` 생성 방법은 다음과 같다.

```ts
new TypeSafeClient(config?: TypeSafeClientConfig) // config 기본값은 {}
```

- 키가 없거나 설정이 틀리거나 런타임이 지원되지 않으면 예외를 던진다.
- 인스턴스 읽기 전용 속성은 `baseURL`, `defaultHeaders`, `defaultModel`, `fetch`, `logger`, `logLevel`, `models`, `retry`, `timeout` 이다.
  - `baseURL` 은 끝 슬래시를 뗀 값이다.
  - `retry` 는 생성자 덮어쓰기를 반영한 완성된 `RetryPolicy` 다.
- close 나 dispose 메서드는 (문서 미기재).

## 질문 빌더

세 빌더 함수로 질문을 만든다. 직접 객체 리터럴을 써도 된다.

```ts
function noul(instructions?: EntryType, criteria?: { false?: EntryType; true?: EntryType } | null): NoulQuestion;
function choice<T extends ChoiceCriteria>(instructions: EntryType, criteria: T): ChoiceQuestion<T>;
function score<T extends ScoreCriteria>(instructions: EntryType, criteria: T): ScoreQuestion<T>;
```

- `noul` 의 `instructions` 기본값은 `null` 이고, `criteria` 는 선택이다.
- `choice` 의 `criteria` 는 라벨을 키로, 설명을 값으로 둔다. 설명이 없으면 `null` 을 넣는다.
- `score` 의 `criteria` 는 0점부터 순서대로 최소 두 개의 설명이다. 항목이 `null` 이어도 된다.

질문 인터페이스는 다음과 같다.

- `NoulQuestion`
  - `type: "noul"`
  - `instructions?: EntryType`
  - `criteria?: { false?: EntryType; true?: EntryType } | null`
- `ChoiceQuestion<T extends ChoiceCriteria = ChoiceCriteria>`
  - `type: "choice"`
  - `instructions?: EntryType`
  - `criteria: T`
- `ScoreQuestion<T extends ScoreCriteria = ScoreCriteria>`
  - `type: "score"`
  - `instructions?: EntryType`
  - `criteria: T`
- `type Question = NoulQuestion | ScoreQuestion | ChoiceQuestion` 이고 `type` 필드로 구분한다.
- `interface Questions { [name: string]: Question }` 이다. 키가 질문 이름이고 답도 같은 키로 돌아온다.
- 질문 안에 `id`, `options`, `levels` 필드는 없다. 선택지와 단계는 모두 `criteria` 다.

보조 타입 별칭은 다음과 같다.

- `type EntryType = string | { [key: string]: JsonValue } | JsonValue[] | null` 이다. state, instructions, criteria 에 공통으로 쓴다.
- `type JsonValue = string | number | boolean | null | JsonValue[] | { [key: string]: JsonValue }`
- `type ChoiceCriteria = { [label: string]: EntryType }`
- `type Description = EntryType` 이다. `null` 이면 그 라벨을 설명하지 않는다.
- `type ScoreCriteria = readonly [EntryType, EntryType, ...EntryType[]]` 이다. 타입 수준에서 최소 두 개를 강제한다.
- `type ScoreOf<T> = number extends T["length"] ? number : Extract<keyof T, \`${number}\`>` 이다. 고정 길이 튜플이면 인덱스 리터럴, 아니면 `number` 가 된다.
- `type ScoreLegend<T> = { readonly [score in ScoreOf<T>]: T[score] }`

타입이 결과로 흐르는 방식은 다음과 같다.

- `type ResultFor<T>` 는 질문 타입을 답 타입으로 바꾼다.
  - `NoulQuestion` 은 `NoulResponse` 가 된다.
  - `ScoreQuestion<S>` 는 `ScoreResponse<S>` 가 된다.
  - `ChoiceQuestion<E>` 는 `ChoiceResponse<E>` 가 된다.
- `SystemOneResult<Q>["answers"]` 는 문서에 `{ readonly [K in string | number | symbol]: ResultFor<Q[K]> }` 로 표기된다. 질문 키마다 `ResultFor` 가 적용되므로 `answers.tone` 은 질문 이름 그대로 타입이 잡힌다.
- `ChoiceResponse<T>.choice` 타입은 `keyof T & string` 이다. `choice("...", { calm: null, angry: null })` 로 만들면 `"calm" | "angry"` 리터럴 유니온이 된다.
- Score 튜플을 리터럴로 고정하려면 `as const` 가 필요한지 여부는 (문서 미기재).

## 호출

질문은 `systemOne` 메서드로 한다.

```ts
systemOne<Q extends Questions>(request: SystemOneRequest<Q>, options?: RequestOptions): APIPromise<SystemOneResult<Q>>;
```

`SystemOneRequest<Q extends Questions = Questions>` 필드는 다음과 같다.

- `state: EntryType` 는 텍스트, JSON 객체, 배열, 또는 `null` 이다.
- `questions: Q` 는 비어 있으면 안 된다.
- `model?: string` 는 생략하면 클라이언트 `defaultModel` 을 쓴다.
- 요청 변수에 붙인 추가 속성은 `null` 값까지 그대로 전송된다.
- `SystemOneRequestPayload` 는 `POST /v1/systemone` 본문 타입이고 `model: string` 이 확정된 형태다.

`RequestOptions` 는 호출마다 클라이언트 설정을 덮어쓴다.

- `headers?: Record<string, string>` 는 `defaultHeaders` 위에 병합된다.
- `retry?: Partial<RetryPolicy>` 의 빠진 필드는 클라이언트 설정을 물려받는다.
- `signal?: AbortSignal` 는 요청과 대기 중인 재시도를 취소한다.
- `timeout?: number` 는 시도 하나당 밀리초다. 전체 재시도 예산은 없다.

호출 시 예외 조건은 다음과 같다.

- questions 가 비었거나 score criteria 가 두 개 이상의 배열이 아니면 예외다.
- 재시도 후에도 2xx 가 아니면 `APIError` 계열이다.
- 재시도 후에도 연결 실패나 시간 초과면 `APIConnectionError` 계열이다.
- 호출자가 취소하면 `APIUserAbortError` 다.

`APIPromise<T>` 는 `Promise<T>` 를 상속하고 메서드를 더 가진다.

- `await` 하면 파싱된 결과를 준다. 2xx 가 아니면 `APIError` 로 reject 된다.
- `withResponse(): Promise<WithResponse<T>>` 는 결과, HTTP 응답, 요청 ID 를 함께 준다.
- `asResponse(): Promise<Response>` 는 파싱하지 않은 원본 `Response` 를 준다. 이때 같은 promise 의 파싱 결과를 다시 `await` 하면 안 된다.
- `map<U>(fn: (data: T) => U): APIPromise<U>` 는 결과를 바꾸면서 응답과 파싱 한 번을 공유한다.
- `then`, `catch`, `finally` 는 일반 Promise 와 같다.

`WithResponse<T>` 필드는 다음과 같다.

- `data: T` 는 파싱된 본문이다.
- `response: Response` 는 본문을 이미 읽은 HTTP 응답이다.
- `requestId: string | undefined` 는 `x-typesafe-request-id` 헤더 값이다.

## 응답

- `SystemOneResult<Q extends Questions>`
  - `readonly answers` 는 질문 이름별로 `ResultFor<Q[K]>` 타입이 붙은 답이다.
  - `readonly model: string` 는 실제로 답한 모델이다.
  - `readonly usage: Usage`
- `NoulResponse`
  - `readonly type: "noul"`
  - `readonly noul: number` 는 예일 확률이고 0 부터 1 사이다.
  - `confidence` 필드는 없다.
- `ChoiceResponse<T extends ChoiceCriteria = ChoiceCriteria>`
  - `readonly type: "choice"`
  - `readonly choice: keyof T & string` 는 선택된 라벨이다.
  - `readonly confidence: number`
  - `readonly probabilities: { readonly [label in string | number | symbol]: number }`
- `ScoreResponse<T extends ScoreCriteria = ScoreCriteria>`
  - `readonly type: "score"`
  - `readonly score: number` 는 기대 점수이고 정수 단계 사이 값이 나올 수 있다.
  - `readonly confidence: number`
  - `readonly legend: ScoreLegend<T>` 는 점수별 루브릭 설명이다.
  - `readonly probabilities: { readonly [score in number | \`${number}\`]: number }`
- `Usage`
  - `readonly input_tokens: number`
  - `readonly output_tokens: number`
- 모델 목록은 `client.models.list(options?: RequestOptions): APIPromise<ModelCard[]>` 로 조회한다.
- `ModelCard`
  - `readonly name: string`
  - `readonly description: string`
  - `readonly release_date: string`

## 에러

클래스 계층은 다음과 같다.

- `TypeSafeError extends Error` 는 SDK 오류 기반 클래스다. 생성자는 `(message: string, options?: ErrorOptions)` 다.
- `APIError extends TypeSafeError` 는 실패한 HTTP 응답이다.
  - 속성은 `status: number`, `body: unknown`, `headers: Headers`, `requestId: string | undefined` 이다.
  - `body` 는 파싱된 JSON, 응답 텍스트, 빈 본문이면 `undefined` 다.
  - `static fromResponse(status, body, headers): APIError` 는 상태 코드에 맞는 하위 클래스를 만든다.
- 상태별 하위 클래스는 모두 `APIError` 를 상속한다.
  - `BadRequestError` 는 400 이다.
  - `AuthenticationError` 는 401 이다.
  - `PermissionDeniedError` 는 403 이다.
  - `NotFoundError` 는 404 이다.
  - `UnprocessableEntityError` 는 422 이다.
  - `RateLimitError` 는 429 다. `retryAfterMs: number | undefined` 속성에 서버가 요구한 대기 밀리초가 들어 있다.
  - `InternalServerError` 는 5xx 다.
- `APIConnectionError extends TypeSafeError` 는 DNS, TLS, 연결 끊김 같은 전달 실패다. 기본 메시지는 `"Connection error."` 다.
- `APITimeoutError extends APIConnectionError` 는 전체 응답이 제한 시간 안에 오지 않은 경우다. `timeoutMs: number` 속성을 가진다.
- `APIUserAbortError extends TypeSafeError` 는 `AbortSignal` 로 취소한 경우다. 기본 메시지는 `"Request was aborted."` 다.

`RetryPolicy` 인터페이스 필드와 기본값은 다음과 같다. 모두 `readonly` 다.

- `maxRetries: number` 의 기본값은 2 다. `0` 이면 재시도하지 않는다.
- `backoffInitialMs: number` 의 기본값은 500 이다. 시도마다 두 배가 되고 `backoffMaxMs` 에서 멈춘다.
- `backoffMaxMs: number` 의 기본값은 5000 이다.
- `backoffJitter: number` 의 기본값은 0.25 다. 대기마다 무작위로 빼는 비율이다.
- `httpStatuses: ReadonlySet<number>` 의 기본값은 408, 429, 500–599 다. 따라서 529 도 재시도된다.
- `respectRetryAfter: boolean` 의 기본값은 true 다. `Retry-After` 와 `retry-after-ms` 를 `maxRetryAfterMs` 까지 따른다.
- `maxRetryAfterMs: number` 의 기본값은 60000 이다. 이보다 긴 서버 지연은 백오프로 대체한다.
- `apiConnectionError: boolean` 의 기본값은 true 다. 응답 본문이 중간에 끊긴 경우도 재시도한다.
- `apiTimeoutError: boolean` 의 기본값은 true 다.

## 완전한 예제 (최소)

```ts
// main.ts — 실행: TYPESAFE_API_KEY=... bun run main.ts
import { noul, TypeSafeClient } from "@typesafe-ai/sdk";

const client = new TypeSafeClient();

const { answers } = await client.systemOne({
  state: "I was charged twice. Please help.",
  questions: { billing: noul("Is this about billing?") },
});

console.log(answers.billing.noul);
```

## 완전한 예제 (Noul + Choice + Score)

```ts
// triage.ts — 실행: TYPESAFE_API_KEY=... bun run triage.ts
import {
  APIError,
  APIConnectionError,
  choice,
  noul,
  RateLimitError,
  score,
  TypeSafeClient,
} from "@typesafe-ai/sdk";

// 판단 기준값은 예시다. 문서는 confidence 가 0 부터 1 사이라는 것만 말한다.
const CONFIDENCE_FLOOR = 0.7;

const client = new TypeSafeClient({
  timeout: 15_000,
  retry: { maxRetries: 3 },
});

const state = {
  ticket_id: "T-1042",
  channel: "email",
  messages: [
    { from: "customer", text: "I was charged twice. Please fix this ASAP." },
    { from: "agent", text: "Sorry about that. Can you share the invoice number?" },
    { from: "customer", text: "INV-778. This is the second time this month." },
  ],
};

const questions = {
  billing: noul("Is this ticket about billing?", {
    true: "Payments, invoices, refunds",
    false: "Anything else",
  }),
  tone: choice("What is the customer's tone in `messages`?", {
    calm: null,
    frustrated: null,
    angry: "Hostile language or threats to cancel",
  }),
  urgency: score("How urgent is this ticket?", ["can wait", "this week", "today"]),
};

try {
  const { data, requestId } = await client.systemOne({ state, questions }).withResponse();
  const { billing, tone, urgency } = data.answers;

  // tone.choice 타입은 "calm" | "frustrated" | "angry" 다.
  if (tone.confidence < CONFIDENCE_FLOOR || urgency.confidence < CONFIDENCE_FLOOR) {
    console.log("review", tone.probabilities, urgency.probabilities);
  } else {
    switch (tone.choice) {
      case "angry":
        console.log("escalate", { billing: billing.noul > 0.5, urgency: urgency.score });
        break;
      case "frustrated":
        console.log(urgency.score >= 1.5 ? "priority queue" : "normal queue");
        break;
      case "calm":
        console.log("auto reply");
        break;
    }
  }

  console.log(data.model, data.usage.input_tokens, data.usage.output_tokens, requestId);
} catch (error) {
  if (error instanceof RateLimitError) {
    console.error("rate limited, retry after ms:", error.retryAfterMs);
  } else if (error instanceof APIError) {
    console.error("API error", error.status, error.requestId, error.body);
  } else if (error instanceof APIConnectionError) {
    console.error("connection failed", error.message);
  } else {
    throw error;
  }
}
```
