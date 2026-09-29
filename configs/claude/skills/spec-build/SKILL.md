---
name: spec-build
description: PR·이슈·브랜치·계획을 조사해, 검토자(작업자가 아니라 진행 방향을 정하는 사람)가 읽고 결정할 수 있는 검토용 스펙을 만들어요. 결정 요청, 불변식, DB 쿼리, 실행 인터페이스, 플로우차트, 테스트 시나리오, 추가 검토사항, 결정 기록, 배포 단계를 담아요. 요청에 따라 artifact(기본) 또는 md 버전으로 분기해요. 트리거 - `/spec-build {요청}`, "검토용 스펙 써줘", "리뷰어가 읽을 스펙", "#123 스펙 만들어줘"
---

# spec-build — 검토용 스펙 분기

이 스킬은 출력 형식만 고르고, 실제 작업은 하위 스킬에 넘긴다.

## 분기 규칙

요청 문자열 `{요청}` 을 보고 하나를 고른다.

- 첫 단어가 `md`, `markdown`, `마크다운` 이거나, 요청에 "md로", "마크다운으로", ".md 파일" 이 있다 → `spec-build-md`
- 첫 단어가 `artifact`, `doc`, `docs`, `문서` 이거나, 요청에 "artifact로", "공유 문서로" 가 있다 → `spec-build-artifact`
- 위 어느 것도 아니다 (형식 언급 없음) → **기본값 `spec-build-artifact`**

형식을 가리키는 첫 단어는 떼고, 나머지를 그대로 넘긴다.

- `/spec-build md #1063` → `Skill(skill="spec-build-md", args="#1063")`
- `/spec-build #1063` → `Skill(skill="spec-build-artifact", args="#1063")`
- `/spec-build artifact #1063 보안 위주로` → `Skill(skill="spec-build-artifact", args="#1063 보안 위주로")`

## 하지 않는 것

- 분기 전에 조사하지 않는다. 조사는 하위 스킬이 한다 (artifact 버전은 조사보다 문서 뼈대 생성이 먼저여야 한다)
- 요청이 비어 있으면(대상 없음) 분기하지 말고, 무엇의 스펙인지(PR 번호·이슈·브랜치·계획) 한 번 묻는다

공통 작성 규칙은 `~/.claude/skills/spec-build/references/spec-contract.md` 에 있다.
