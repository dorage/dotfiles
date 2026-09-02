# 기록 규칙 (aol 플러그인)

마스터의 반복 요청, LLM의 질문, 자주 하는 작업을 나중에 배치로 분석해 스킬로 바꾸기 위한 라벨을 남긴다. 파일은 훅이 쓰고, LLM은 파일을 쓰지 않는다.

- 마스터 프롬프트에 답하는 응답은 마지막 줄에 마커 한 줄을 붙인다: `[aol] intent=<의도> object=<대상> size=<예상 크기>`
  - `intent`: explore, plan, implement, fix, refactor, test, review, git, docs, config, ops, ask, continue 중 하나. 둘 이상이면 마스터 발언의 마지막 동사를 따른다("조사하고 고쳐줘"는 fix). 변경 요청 없이 답만 원하면 ask. 승인·계속·짧은 답은 continue.
  - `object`: 작업 대상 1~3단어, 영어 kebab-case. 브랜치가 있으면 브랜치 이름의 설명 부분을 그대로 쓴다.
  - `size`: 예상 크기 5m / 1h / 3d. 나중에 실측과 비교하는 데 쓴다.
- 마스터가 LLM의 직전 행동을 고치거나 되돌리게 했으면 같은 줄에 `corr="<무엇을 잘못했나 한 문장>" rule=<어긴 규칙의 절 제목, 없으면 none>`을 덧붙인다. corr 값 안에는 큰따옴표를 쓰지 않고, rule 값의 공백은 -로 바꾼다.
- 슬래시 커맨드, 시스템·훅·커맨드 출력에 답하는 턴은 마커를 쓰지 않는다.
- 마커가 빠지거나 형식이 틀리면 Stop 훅이 응답을 되돌린다.
- 예: `[aol] intent=fix object=fcm-ios-sound size=1h`
- 예: `[aol] intent=git object=commit-push size=5m corr="테스트를 돌리지 않고 커밋했다" rule=커밋`
