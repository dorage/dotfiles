---
name: pug-frame
description: Write pug-frame wireframe syntax — a Pug-based DSL that renders multiple app screens (mobile/tablet/desktop frames) onto one canvas, used in `pug-frame` code blocks (Obsidian notes, Markdown, .pf files) and by @pug-frame/canvas viewers. Use whenever the user asks to author, edit, or explain a wireframe/mockup/screen flow written in pug-frame, or writes inside a ```pug-frame code block. Covers frames, structure keywords, placeholder elements, value widgets, p- attributes (p-focus/p-tooltip/p-icon/p-scrollbar), and Tailwind utilities.
---

# pug-frame 작성

pug-frame은 [Pug](https://pugjs.org/) 문법 위에 와이어프레임 의미를 얹은 DSL이다. **한 문서에 여러 화면**을 담고, 각 화면은 프레임(mobile 등) 크기의 박스로 캔버스에 나열된다. Obsidian 노트나 Markdown의 ` ```pug-frame ` 코드블록, `.pf` 파일에서 쓴다.

## 언제 사용하나

- 사용자가 pug-frame으로 와이어프레임/목업/화면 흐름을 작성·수정·설명해 달라고 할 때.
- ` ```pug-frame ` 코드블록 안을 작성할 때.

## 핵심 규칙 (먼저 이것부터)

1. **기본 문법은 Pug와 100% 동일하다.** 들여쓰기 중첩, `태그#id.class(attr='v') 텍스트` 순서를 그대로 따른다. 텍스트는 태그 뒤에 그대로 쓴다: `div Rescene`.
2. **들여쓰기 0의 프레임 키워드가 화면 하나를 시작한다.** `mobile`, `tablet`, `desktop`. 여러 개를 빈 줄로 구분해 나열하면 여러 화면이 된다.
3. **선택자 순서는 Pug 규칙**: `#id` → `.class` → `(attrs)`. 예: `section.flex.gap-2(p-scrollbar-x)`. 클래스는 반드시 attribute보다 **앞**.
4. 키워드 매핑은 **줄의 선행 태그 토큰**일 때만 일어난다. `#id`/`.class`/`(attrs)` 잔여부는 그대로 보존된다.
5. 유효한 HTML 태그(`div`, `section`, `span`, `button`, `p`, `ul`, `li`, `a`, `input`, `h1`~`h6` 등)는 매핑 없이 그대로 통과한다.

## 프레임 키워드 (들여쓰기 0, 화면 시작)

- `mobile` — 375 × 812
- `tablet` — 768 × 1024
- `desktop` — 1440 × 900

`#id`를 붙이면(`mobile#main-1`) 프레임 바깥 위에 id 라벨이 표시되고, 이 id는 `p-focus`의 이동 대상이 된다.

## 구조 키워드 (프레임 내부 시맨틱 영역)

실제 태그 대신 클래스 div로 매핑된다(중첩 `<body>` 무효화 회피). 공통: 검은 border + 흰 배경 + 패딩 + 컨텐츠 클리핑.

- `header`, `nav`, `main`, `body`, `footer`
- `main`과 `body`는 남는 세로 공간을 채운다(`flex: 1`).
- `section`은 매핑 없이 그대로 통과하는 중립 그룹으로 쓴다.

## 요소 키워드 (자리표시자·위젯)

### 자리표시자 (값 없음, 자기완결)

- `circle` — 원형 아바타(48×48). 흔히 `circle(p-icon='user')`로 아이콘 아바타.
- `image` — 이미지 박스(회색 + 대각선, 최소 64×64).
- `video` — 비디오 박스(가운데 재생 삼각형).
- `search` — 검색 바(돋보기 + 입력 라인).
- `navigation` — 하단 탭 바(균등 분할).
- `spinner` — 로딩 스피너.

### 드롭다운

```pug-frame
dropdown 정렬선택
    item 추천순
    item 인기순
```

- `dropdown` — 라벨(트레일링 텍스트) + 캐럿 + `item` 목록.
- `item` — 항목 한 줄.

### 제목·링크

- `h1`~`h6` — 표준 태그, 레벨별 크기 적용.
- `link` — `<a>`로 매핑, 링크 스타일(밑줄). `link(href='#') 더보기`.

## 값 기반 위젯 (p-* 값으로 내부가 그려짐)

값이 없으면 기본값, 범위 밖은 clamp. 렌더 단계에서 마크업이 생성되어 **정적 출력에도 남는다**.

- `calendar(p-date="YYYY-MM-DD")` — 해당 월 달력, 지정일 강조(없으면 오늘).
- `monthpick(p-month="YYYY-MM")` — 12개월 그리드(없으면 이번 달).
- `yearpick(p-year="YYYY")` — 12년 그리드(없으면 올해).
- `rating(p-star=N)` — 별 5개 중 N개(0~5 clamp).
- `progressbar(p-progress=N)` — 진행바 N%(0~100 clamp).
- `toggle(p-on)` — `p-on` 있으면 on.
- `checkbox(p-on)` — `p-on` 있으면 체크.

## p- attribute (pug-frame 전용, `요소(p-<기능>='<값>')`)

### 컨텐츠 — 렌더 단계에서 반영, 정적 출력에도 남음

- `p-icon='<이름>'` — 요소 안에 [lucide](https://lucide.dev/icons/) 아이콘을 인라인 SVG로. 이름은 kebab-case(`user`, `chevron-right`, `settings`). 모르는 이름은 점선 사각형. SVG는 `currentColor`(텍스트 색을 따름), 기본 24×24.
- 위젯 값(`p-date`/`p-month`/`p-year`/`p-star`/`p-progress`/`p-on`) — 위 "값 기반 위젯" 참고.

### 인터랙션 — canvas 뷰어 전용, **정적 HTML 출력에서는 제거됨**

- `p-focus='<대상 id>'` — 클릭하면 그 id를 가진 요소(보통 다른 프레임)로 카메라 이동. 화면 흐름 연결에 쓴다.
- `p-tooltip='<내용>'` — 오른쪽 상단에 `*` 마커, 호버/탭 시 말풍선.
- `p-scrollbar-x` / `p-scrollbar-y` — 스크롤바를 모양으로만 그린다(값 없이 붙임). 한 요소는 한 축만. 컨텐츠는 잘린다.

## 유틸리티 클래스 · Tailwind

- 항상 동작(정적·canvas 공통): `.flex`(display:flex), `.text-small`(작은 글자), `button.active`(선택 표시: 흰 배경 + 검은 테두리 반전).
- 그 외 임의의 **Tailwind 유틸리티**(`flex-col`, `gap-4`, `items-center`, `justify-between`, `bg-blue-500` 등)는 **canvas 뷰어에서만** 런타임 생성된다. 정적 HTML 출력에는 포함되지 않으니, 정적 렌더가 목적이면 레이아웃을 `.flex`와 인라인에 의존하지 말고 확인할 것.

## 전체 예시

```pug-frame
mobile#main-1
    header
        div Rescene
    body
        div Ilsan!
        button(p-focus='main-2') Next
        div(p-tooltip='다음 화면으로 이동합니다') ?
    footer
        div 2026.07.07

mobile#main-2
    header
        div Rescene
    body
        div Yaho!
        button(p-focus='main-1') Prev
    footer
        div 2026.07.07
```

기본 요소·아이콘·스크롤바·유틸리티를 함께 쓴 예:

```pug-frame
mobile#profile
    nav.flex.items-center.justify-between
        div 뒤로
        div 프로필
        circle(p-icon='settings')
    main.flex.flex-col.gap-4
        section.flex.items-center.gap-3
            circle(p-icon='user')
            .flex.flex-col
                div 이강현
                div.text-small 클로드코드 조련사
        section.flex.gap-2(p-scrollbar-x)
            section.flex.flex-col.gap-2(p-scrollbar-y)
                image
                image
                image
            div.text-small 2026.06.05 호수공원 사진들
    footer.flex.justify-end
        div.text-small 2026-07-18
```

## 와이어프레임 문서 구성 (여러 화면짜리 앱)

앱 하나의 화면들을 Markdown 문서 한 편으로 정리할 때는 아래 순서를 따른다.

1. **개요 한 단락** — 대상 앱, 사용하는 프레임 종류와 그 이유(예: 세로형 단말 → `tablet`), 출처(라우팅 파일·화면 코드 경로).
2. **화면 흐름** — 코드블록 안 화살표 다이어그램으로 화면 이동을 정의한다.
3. **화면 목록 표** — 각 화면을 screen id(프레임의 `#id`)에 매핑한다. 열은 `# | 화면 | screen id` 세 개만 둔다. 한 화면이 여러 프레임(단계 전환·다이얼로그)으로 나뉘면 id를 나열한다.
4. **화면별 섹션** — `## N. 화면명 (\`screen-id\`)` 헤더 아래 pug-frame 블록. 파생 화면(다이얼로그·빈 상태)은 `### N-1.` 하위 섹션으로 붙인다.

레이아웃 설명 열이나 화면별 산문 설명은 **쓰지 않는다** — 레이아웃은 pug-frame 코드 자체가 보여준다. 산문은 코드로 표현할 수 없는 동작(진입 제스처, 자동 전환 조건 등)이 있을 때만 최소로 남긴다.

문서 뼈대 예시:

````markdown
# 알란테 키오스크 와이어프레임 (alante_kiosk)

Flutter 키오스크 앱의 주요 화면 레이아웃. 세로형 단말이라 `tablet` 프레임으로 그린다.

- 출처: `lib/app/router.dart`(라우팅), `lib/features/*/presentation/*.dart`(각 화면).

## 화면 흐름

```
로그인 ─▶ 대기(idle) ─▶ 메뉴 ─▶ (메뉴상세) ─▶ 휴대폰입력 ─▶ 결제수단 ─▶ 주문완료 ─▶ 대기
                        └─ 카페명 10회 더블탭 → PIN → 관리자(결제내역)
```

| #   | 화면     | screen id                              |
| --- | -------- | -------------------------------------- |
| 1   | 로그인   | `kiosk-login`                           |
| 2   | 대기     | `kiosk-idle`                            |
| 5   | 휴대폰입력 | `kiosk-phone-intro` `kiosk-phone-input` |

## 1. 로그인 (`kiosk-login`)

```pug-frame
tablet#kiosk-login
    body.flex.flex-col.items-center.justify-center.gap-4
        image
        input(placeholder='아이디')
        button.active 로그인
```
````

## 흔한 실수 (체크리스트)

- 클래스를 attribute 뒤에 두지 말 것. `section(p-scrollbar-x).flex`(✗) → `section.flex(p-scrollbar-x)`(✓).
- 프레임 키워드는 반드시 들여쓰기 0. 화면 하나 = 최상위 블록 하나.
- 화면 흐름을 만들 땐 `mobile#some-id`로 대상에 id를 주고 다른 화면에서 `button(p-focus='some-id')`로 연결.
- 정적 HTML(CLI `render`)이 목적이면 `p-focus`/`p-tooltip`/`p-scrollbar`와 Tailwind 유틸리티는 결과에 남지 않는다는 점을 전제로 작성. canvas/Obsidian 프리뷰가 목적이면 전부 동작.
- 아이콘 이름은 lucide kebab-case 그대로. 확신이 없으면 https://lucide.dev/icons/ 에서 확인.
- 한 요소에 `p-scrollbar-x`와 `p-scrollbar-y`를 동시에 쓰지 말 것(한 축만).
