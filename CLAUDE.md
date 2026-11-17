# donBug

Flutter app (돈벌래 - 스마트 매장 관리 앱). 소상공인 사장님·알바생용 매장 관리: QR 출퇴근, 근무표, 대타, 급여, 서류(근로계약서·보건증), 공지. 모바일 앱 + 사장님 웹/POS 화면.

현재 상태: **서버 연동 운영 중** (`https://donbug.ruraeru.xyz`). 백엔드는 Spring Boot (github.com/halo518/MoneyBug), 배포는 github.com/ruraeru/donBug_deploy (Docker, 이 레포는 submodule). 배포·운영 방법은 그 레포의 README.md·CLAUDE.md.
- **서버 모드가 기본.** `AppStore.api` 가 있으면 `store.remote`. `--dart-define=DEMO=true` 로 빌드하면 예전처럼 기기 안 시드 데이터로 도는 데모 모드. `--dart-define=API_BASE=...` 로 서버 주소를 바꾼다(앱 기본 `https://donbug.ruraeru.xyz`, 웹은 같은 origin).
- 계약: `lib/data/models.dart` 의 JSON 이 FE↔BE 계약이다. 백엔드가 이 모양에 맞춘다. 서버는 `GET /api/v1/me/state` 로 `AppState` JSON 을 그대로 준다.
- 로그인: 카카오(웹 = 서버 리다이렉트, 앱 = `flutter_web_auth_2` 로 서버 OAuth → `donbug://auth`). 테스트 계정 = 로그인 화면 로고 길게 누르기 → 서버 `TEST_LOGIN_TOKEN` 값 입력.
- 웹: 사장님 PC 대시보드. 폭 700 미만(폰 브라우저)이거나 알바생이면 모바일 앱 화면을 웹에서 그대로 띄운다.
- AI: 노무 도우미(앱 B6·웹 W7, Claude), AI 근무표 생성(웹, Ollama). 모바일 B6 은 진입 경로가 없다.

아직 안 만든 것:
- 휴대폰 푸시 알림 없음. 변경은 롱 폴링(`/me/changes`)·60초 확인·당겨서 새로고침으로 반영.
- 웹 인건비 "PDF 내보내기"·"정산 확정"은 "추후 개발 예정" 토스트만 띄운다.
- 근무 창의 "휴게 시작"은 "자동" 고정. 공휴일은 2026년만(`holidays.dart`).
- 모바일 근무표(알바생·사장님)는 `shiftsOn` 을 써서 연차·휴무·시간 미정 근무를 숨기기만 한다. 모바일 사장님 근무표·템플릿은 예전 API(즉시 저장) 그대로다.
- 출근 기록 있는 근무 삭제 시도는 웹 근무 창에서 안내 없이 무시된다.
- 노무 체크리스트의 5인 미만 판정은 지금 재직 인원으로 근사한다(월 평균 인원 아님).
- 모바일 화면은 테스트로만 확인했고 스크린샷으로 보지 않았다.

## Design (Figma)

Figma: https://www.figma.com/design/yGOBAGbQ9P5u74nGHL0eZx/%EB%8F%88%EB%B2%8C%EB%9E%98---%EC%8A%A4%EB%A7%88%ED%8A%B8-%EB%A7%A4%EC%9E%A5-%EA%B4%80%EB%A6%AC-%EC%95%B1?node-id=43-2

- fileKey: `yGOBAGbQ9P5u74nGHL0eZx`
- 화면 위젯 doc 주석에 Figma 노드 ID 표기 (예: `/// B4 대타 승인 (Figma 47:573).`).

페이지:

| 페이지 | ID | 내용 |
|---|---|---|
| 앱 디자인 v2 | `43:2` | 코드 구현 기준 화면. 섹션 단위(알바생 1–7, 사장님 1–9, 웹) |
| 앱 디자인 v3 (근무표 개편) | `151:2` | v2 사본 + 웹 근무표 개편. 반복 요소를 디자인 시스템 인스턴스로 교체함 (아래) |
| 유저 플로우 (플로우차트) | `147:2` | 차트 2개: Figma 기준(`147:23`), 코드 기준(`176:178`, ⚠ = 코드 미연결) |
| 근무표-오토스케줄 | `137:1612` | 웹 근무표 작업. 공용 컴포넌트 `근무표/Sidebar`(`142:34`) |
| 디자인 시스템 | `194:2` | 변수·텍스트 스타일·아이콘·컴포넌트·로고 컴포넌트 (아래) |
| 로고 (Logo) | `181:2` | 로고 에셋. 원본 프레임 `181:3`, 섹션 사본 `186:2` |
| 로고 후보들 | `185:11889` | 로고 시안 |
| 앱 디자인 | `0:1` | 구버전 |
| 제품 사진 (목업) | `114:2` | 경진대회 판넬용 목업. 원본 프레임은 수정하지 말고 아래에 사본으로 작업 |

디자인 시스템 (페이지 "디자인 시스템"):
- 변수 컬렉션 `돈벌래/Colors`: 16색, `AppColors` 와 1:1. 설명에 `AppColors.xxx` 를 적어 두었다(Figma 에 Flutter 코드 이름 칸이 없음). 라이트 모드만 있다.
- 변수 컬렉션 `돈벌래/Spacing`: `space/2`–`space/32`, `radius/10`–`radius/20`, `radius/full`.
- 텍스트 스타일 25개: 이름은 `굵기/크기`(예: `Bold/16` = `AppText.style(16, FontWeight.w700)`), Noto Sans KR, 줄높이 140%.
- 아이콘 `Icon/<name>`: `assets/icons/*.svg` 13개, 24px.
- 컴포넌트: Button(5×2), Pill, Note Box, Letter Avatar, Field Box, Card, Header, Key Value Row, Person Row, Labeled Field, Step Row, Success Hero, Tab Item, Tab Bar(알바생/사장님), Bottom Bar, Confirm Dialog.
- 로고 컴포넌트: `Logo/App Icon`, `Logo/Symbol`(L·M·S), `Logo/Lockup Compact`(Light·Dark·Green).

v3 교체 상태:
- 교체함: Header 27, Tab Bar 18, Letter Avatar 30, Pill(Chip·Badge) 108, Button 93, 임시 ₩ 로고 → `Logo/App Icon`.
- 그대로 둔 것(맞는 변형 없음): 카카오·검정·파랑 버튼, 아이콘 있는 버튼·헤더, 회색·보라 칩, Status Bar, Bottom Bar 틀, 카드.
- 원래 크기를 위해 여백·크기를 인스턴스에서 덮어쓴 것이 있다. 이런 인스턴스는 컴포넌트 기본값을 바꿔도 따라오지 않는다.

## Commands

Flutter SDK는 PATH에 없음. 프로젝트 루트의 로컬 SDK 사용 (`/flutter/`는 gitignore, 커밋 금지):

```sh
./flutter/bin/flutter analyze
./flutter/bin/flutter test
./flutter/bin/flutter run                              # 서버 모드 (운영 서버)
./flutter/bin/flutter run --dart-define=DEMO=true      # 데모 모드 (시드 데이터)
./flutter/bin/flutter build web --release   # 이 서버에는 에뮬레이터·화면이 없어 컴파일 확인용
```

## Structure

- `lib/main.dart`
  - 서버 모드: `AppStore(buildSeed(now), api: ApiClient(prefs))`. 첫 화면은 웹 `WebBoot`, 앱 `MobileBoot`. 토큰 갱신 실패(`onUnauthorized`)면 로그인으로.
  - 서버 모드 새로고침: `_watchChanges`(롱 폴링 `GET /api/v1/me/changes?since=` → 바뀌면 `refreshNow`), 60초 주기, 앱 복귀 시. `remoteError` 를 토스트로 띄운다.
  - 데모 모드: prefs 저장본으로 `AppStore.load`. 웹이면 `WebShell`, 앱이면 로그인 상태에 따라 역할 셸 / `LoginScreen`.
  - `builder`: 빈 곳 탭하면 포커스 해제(키보드 내림), 웹 모바일 화면이면 폭 480 가운데 틀(`webMobileFrame`).
- `lib/data/` — 데이터 계층
  - `models.dart`: `Person`(보건증은 사람 단위), `Store`(`scheduleConfirmedAt`, 영업시간 `openMin/closeMin/weekendOpenMin/weekendCloseMin`(1440 넘으면 익일), `sizeMode`, `parts`: `PartTemplate{id, name, tone, startMin, endMin, breakMin, need}`), `Staff`(매장별 소속. 가입 신청 = `status: pending`, 계약서 포함, `kind`: 매니저·정직원·알바·연소자, 알바생 `fixedParts`(월~일 고정 파트 이름), 직원 `workHours`(월~일 출퇴근)), `Shift`(`kind`: 근무·연차·휴무, `timeTbd`: 시간 미정), `Attendance`, `SubstituteRequest`, `Notice`, `AppNotification`, `Session`, `MonthSchedule`(월 근무표: 작성 중/확정·출처·AI 코멘트), `ScheduleTemplate`(이름 있는 주간 패턴), `AppState`. 수동 JSON 직렬화.
  - 매니저·정직원(`StaffKind.flex`)은 유동 근무: 파트 대신 `part: '직원'` 으로 시간을 직접 정한다.
  - `api_client.dart`: `useApi`(= `!DEMO`), `apiBase`, `ApiClient`(SharedPreferences 토큰 `donbug.access`/`donbug.refresh`, 401 이면 refresh 한 번, `multipart`, `authHeaders`), `ApiException(status, code, message)`.
  - `app_store.dart`: `AppStore extends ChangeNotifier`. 조회·파생값(내 근무, 출근 상태, 대타, 급여, 인건비, 안 읽은 수)과 모든 액션(출퇴근, 대타, 근무표(근무표 만들기: planSchedule 미리보기 → applySchedulePlan), 직원, 공지, 서류, 매장, 세션, 데모). 액션마다 관련자에게 `AppNotification` 을 만든다.
  - 서버 모드에서 액션은 로컬 상태를 바꾸고 `_remote(...)` 로 API 를 보낸 뒤 `/me/state` 를 다시 읽는다(실패는 `remoteError`). 결과를 기다려야 하는 일은 `...Remote` Future 메서드(`createStoreRemote`, `requestJoinRemote`, `clockInRemote`, `uploadHealthCertRemote`, `signContractRemote` 등). `reload` 는 늦게 온 응답·초안 편집 중 응답을 버린다. `refreshNow({quiet})` 는 버전 불일치를 한 번 알린다.
  - 웹 근무표 초안 모드: `setScheduleDraft(true)` 동안 근무 편집은 로컬 + 되돌리기 스택만, `saveSchedule(month)` 이 `PUT /stores/{id}/schedules/{month}/shifts`(그 달 근무 전체). 월 근무표 `createMonthSchedule`·`autofillMonth`·`generateSchedule`(AI job 폴링)·`confirmMonth`·`deleteMonthSchedule`, 템플릿 `saveScheduleTemplate`·`applyScheduleTemplate`·`deleteScheduleTemplate`, 매장 `updateStoreSettings`·`saveParts`.
  - `autoschedule.dart`: autoSchedule_FE 이식 순수 함수(`fixedShifts`, `autofill`, `toPattern`/`fillMonth`, 휴게 규칙, `hoursOn`). `holidays.dart`: 2026 공휴일. `ai_api.dart`: AI 노무 도우미 호출.
  - `seed.dart`: `buildSeed(now)`. 지난달 1일이 있는 주부터 다음 주까지 근무·출근 기록을 만든다.
  - `payroll.dart`: 급여 순수 함수(`computePayslip`, `weeklyHolidayPay`, `deductionOf`), `minimumWage2026 = 10320`.
  - `format.dart`: `won`, `wonText`, `md`, `hm`, `dDay`, `relative`, `shiftDay/Time/Caption` 등.
  - `app_scope.dart`: `AppScope.of(context)`(build 에서, 구독), `AppScope.read(context)`(콜백에서, 구독 안 함).
- `lib/theme.dart` — `AppColors`(Figma 변수 1:1 토큰), `AppText.style(size, [weight, color])`(line-height 1.4), `appTheme`(폰트 Noto Sans KR).
- `lib/widgets/common.dart` — 공용 위젯
  - 레이아웃·표시: `AppIcon`, `AppCard`, `Pill`, `AppButton`(Primary/Soft/Surface/Outline/Danger), `AppHeader`("‹ 제목" 헤더), `LetterAvatar`, `MemberAvatar`(직원 tone 색), `PersonRow`, `KeyValueRow`, `BottomBar`, `NoteBox`, `SuccessHero`, `StepRow`, `LabeledField`
  - 입력: `FieldBox`(`onTap` 주면 날짜·시간 선택 버튼), `AppTextField`, `AppToggle`, `ToggleCard`
  - 데이터 표시: `PayBreakdown`, `MonthNav`, `certPill`, `CountBadge`, `EmptyNote`
  - 상태·피드백: `MissingScreen`(상세 대상이 사라졌을 때), `showConfirmDialog`, `showToast`
- `lib/widgets/demo_menu.dart` — `openShell(context, role)`, `logoutToLogin`, `DemoMenu`(역할 전환 · 데모 데이터 초기화, 서버 모드에선 숨김).
- `lib/widgets/tab_shell.dart` — 하단 탭 셸. `TabShell.of(context)?.select(i)`로 탭 전환. 서버 모드면 탭마다 당겨서 새로고침.
- `lib/widgets/signature_input.dart` — 서버 모드 서명 패드(`signature` 패키지 → PNG 업로드).
- `lib/screens/mobile_boot.dart` — 앱 서버 모드 진입: `MobileBoot`, `kakaoAppLogin`, `testAccountLogin`, `enterApp`(매장 없음 → 역할 선택, 가입 대기 → 대기 화면, 그 밖 → 역할별 셸).
- `lib/screens/employee/` — 알바생 화면. 전용 위젯은 `employee_parts.dart`(`CheckLine`, `ShiftHeroCard`, `TabTitle`, `SignaturePad`, `shiftStatus`).
- `lib/screens/employer/` — 사장님 화면. 전용 위젯은 `employer_parts.dart`(`SegmentedPicker`, `CountStepper`, `SmallButton`, `SuccessStepsScaffold`, `showWageDialog`, `pickStaff`, `pickTime`, `partColors`, `attStyle`, `employerTarget`).
- `lib/screens/web/` — 사장님 웹(W1–W7, 대타 승인, 템플릿, 매장 설정)과 POS QR(W8–W9).
  - 서버 모드 진입: `web_boot.dart`(`#/auth?access=..` 토큰 처리 → 상태 읽기 → 매장 만들기 / `WebShell` / 모바일 화면), `web_login_screen.dart`(로고 길게 = 테스트 계정), `web_create_store_screen.dart`, `web_view_mode.dart`(PC/모바일 화면 선택·저장 `donbug.webView`), `web_url*.dart`·`web_download*.dart`(웹 전용 조건부 import).
  - `web_shell.dart`: 폭 1100 이상 사이드바, 800–1100 아이콘 레일, 800 미만 상단 바 + 서랍. 메뉴 이동은 `WebShell.open(context, WebMenu.xxx)` (dashboard·schedule·staff·substitute·payroll·documents·notice·ai·templates·settings).
  - 웹 공용은 `web_common.dart`: `WebPage`(제목 + 액션, 안 들어가면 액션이 아래 줄), `WebButton`, `WebRow`, `WebSplit`, `WebTable`(`onRowTap`, 좁으면 가로 스크롤), `WebSegmented`, `WebSelect`, `showWebDialog`, `showWebSheet`, `webField`/`webPair`, `DashedBorderPainter`.
  - 상세·작성은 웹 전용 창이다: 근무 추가·수정(`web_shift_dialog.dart`), 직원 상세 시트·직원 초대(`web_staff_screen.dart`), 계약서 작성(`web_documents_screen.dart`), 공지 작성(`web_notice_screen.dart`), 알림·오늘 근무·근태 수정(`web_dashboard_screen.dart`).
  - 대시보드(`web_dashboard_screen.dart`): KPI 4개, 오늘 타임라인(`web_today_strip.dart`), 이번 달 근무 통계, 직원(유동) 주간 근무 현황, 대타·노무 리스크.
  - 근무표는 autoSchedule_FE(github.com/ruraeru/autoSchedule_FE) 방식이다.
    - 목록(`web_schedules_screen.dart`): 월별 근무표(작성 중/확정·출처), 직접 만들기·AI 생성(`web_schedule_generate.dart`). `WebSchedulesScreen.openRequest`/`openDay` 로 다른 화면에서 그 달·그날 편집기를 연다.
    - 편집기(`web_schedule_screen.dart` + `web_schedule_views.dart`): 한 달·파트별·인원별·일간. 초안 모드(되돌리기/다시하기 ⌘Z·저장·저장 안 됨 배지), 자동 채우기, 확정하기(미정 있으면 막음), 옆 패널(합계 `scheduleSummary`·AI 브리핑·이미지 저장·템플릿 저장·삭제). 일간 보기 블록 끌기·양끝 크기 조정.
    - 템플릿(`web_templates_screen.dart`), 매장 설정(`web_settings_screen.dart`: 영업시간·사업장 규모·파트 표·기존 설정, `toneColor`).
    - `web_schedule_create_dialog.dart`(필요 인원 자동 배정)는 웹 메뉴에서 빠졌고 테스트만 남아 있다.
  - 직원 상세 시트(`web_staff_screen.dart`): 시급·공제·유형·연소자, 알바생 파트×요일 고정 근무 격자, 직원 요일별 출퇴근.
- `assets/icons/` — Figma에서 받은 SVG (`flutter_svg`). `assets/images/app_icon.svg` — 로고 App Icon(Figma `186:174`). `assets/fonts/` — Noto Sans KR 400/500/700 (OFL).

## 데이터 규칙

- 화면은 상수를 두지 말고 `AppScope.of(context)` 값으로 그린다. 바꾸는 일은 `AppStore` 액션으로만 한다(화면에서 모델 직접 수정 금지). 탭에 남는 로컬 사본 상태(`_working` 같은)를 두지 않는다.
- 상세 화면은 id 를 받는다(`ShiftDetailScreen(shiftId:)` 등). 대상이 없으면 `MissingScreen`.
- 근무 날짜는 `'yyyy-MM-dd'` + `startMin`/`endMin`(하루 기준 분, `end <= start` 면 야간). 시각만 ISO 문자열.
- 근무 조회는 두 갈래다. `shiftsOn`·`shiftsOfStaff` 는 실제 근무(`Shift.isWork`: 근무 + 시간 확정)만 → 출퇴근·근태·급여·대타는 이것만 쓴다. 근무표 표시는 `scheduleOn`·`scheduleOfStaff`(연차·휴무·미정 포함).
- 연차는 소정 시간만큼 유급(`payslip`), 휴무·미정은 0원.
- 근무표 액션(`addShift`·`updateShift`·`deleteShift`·`autoFill`·`applyTemplate`)은 직전 상태를 되돌리기 스택(메모리)에 쌓는다.
- id 는 `AppState.nextId` 카운터(`'s12'`). 시드의 사람·매장은 고정 id (`p-taewoo`, `p-owner`, `st-cafe`, `st-moa`).
- 데모 저장: SharedPreferences 키 `donbug.state` 에 JSON 한 덩어리. **모델 스키마를 바꾸면 `AppState.version` 을 올린다** (지금 4. 데모는 저장본을 버리고 시드로 시작, 서버 모드는 백엔드 `FE_STATE_VERSION` 도 같이 올려야 한다. 다르면 앱이 "앱을 업데이트해 주세요"만 띄운다).
- 서버 id 는 숫자 문자열이다. API 로 보낼 때 `_n(id)` 로 숫자로 바꾼다. 로컬에서 새로 만든 근무(임시 id)는 저장 때 id 없이 보낸다.
- 시드는 실제 오늘 기준이다.
  - 알바생(김태우)은 오늘 근무가 항상 있다(미들 14–20, 오늘 포함 격일 3일).
  - 카페 커푸치노: `CAFE-8K2D`, 5인 이상(재직 7명), 데모 사장님 소유. 매니저 지훈(유동 근무), 알바 지민·수빈·하윤·태우·서연, 연소자 유나, 가입 대기 도현.
  - 근무: 지난달 1일이 든 주부터 다음 주(또는 이번 달 끝 주)까지. 파트(오픈 10–16 · 미들 14–20 · 마감 18–22)마다 필요 1명을 매일 채운다. 일부러 남긴 것: 다음 주 일요일 마감 빈칸(자동 채우기 시연), 지훈 다음 주 토요일 시간 미정, 지훈 이번 주 연차 1건.
  - 보건증: 수빈 D-12, 태우 D-25, 도현 미등록. 계약서 직원 미서명: 태우·서연.
  - 편의점 모아: `MOA-27QX`, 태우 야간. 사장님 화면 없음.
  - 베이커리 밀: `BAKE-5TQ1`, 태우 미가입(가입 신청 → 대기 → 데모 승인 시연용). 사장님 화면 없음. 이미 가입한 코드는 "이미 가입한 매장이에요" 토스트.
  - 진행 중 대타 2건: 수빈 → 지민 수락(승인 대기), 하윤(지원 대기).
- 급여 규칙(근사)
  - 기본급 = 실근무 분 × 시급. 실근무는 max(출근, 소정 시작)부터 센다(일찍 찍어도 안 부풀음). 출근은 시작 30분 전부터, 종료 뒤엔 불가(`clockInBlock`). 근무 중엔 매장 전환 불가.
  - 시급은 근무 날짜 기준 이력(`Staff.wages`, `wageOn(day)`). 데모는 `updateStaff`·계약서 저장 때 이력이 쌓이고, 서버 모드는 서버 값을 쓴다.
  - 주휴수당(주 월–일 단위): 소정시간(계약서 `weeklyHours`, 없으면 그 주 본인 예정 근무+연차; 그 주 예정 근무가 없으면 0) ≥ 15h AND 개근(끝난 본인 근무는 모두 출근 기록, 지각 OK, 연차는 출근) AND 계속근로(`leftAt` 이 일요일 이상). 금액 min(소정, 40h)/40 × 8 × 일요일 시급, 일요일이 속한 달에 지급. 확정 급여는 일요일이 지난 주만, 예상 급여는 진행 중 주도 출근할 것으로 본다(`WeekBasis`).
  - 가산(5인 이상 + 직원 설정): 야간·8시간 초과분에 0.5배 추가. 주 40h 초과분이 그 주 일별 8h 초과 합보다 크면 차이만큼 0.5배 더(중복 없음).
  - 공제: 3.3%(원 단위 내림), 4대보험 근사 9.4%(화면에 "예상" 표기), 없음.
  - 시급은 최저임금 미만으로 저장할 수 없다.
- 인건비 추이의 2달 전 이전은 `Store.monthlyTotals` 상수다. 시드가 근무 패턴으로 낸 월 인건비에 작은 변동을 줘 만든다.
- 데모 장치 (데모 모드에서만 보인다. 서버 모드는 실제 기능: POS 는 30초 회전 QR, 앱은 카메라 스캔, 보건증·서명은 업로드, 공유는 시스템 공유 시트)
  - 역할 전환·초기화: `DemoMenu`(알바생 MY, 사장님 매장 설정). 웹은 사이드바 "데모 데이터 초기화"
  - POS QR(웹 W8): QR 을 누르면 오늘 아직 출근하지 않은 다음 근무자가 출근
  - "동료 수락 (데모)" 버튼: 대타 요청 현황
  - "사장님이 승인한 것으로 (데모)" 버튼: 가입 대기
  - 탭하면 성공하는 모의 동작: QR 스캔, 보건증 사진
  - `SignaturePad`: 손가락 서명
- 데모에서 사장님은 1인 1매장이다. 매장 만들기는 기존 매장 정보를 바꾼다. 서버 모드는 `POST /api/v1/stores` 로 새로 만든다(매장 코드 8자 `XXXX-XXXX`).

## Tests

- `test/widget_test.dart`
  - `pumpAt(tester, home, size, store:)`: 고정 시각 2026-05-14(목) 14:30 시드 store 를 주입한다.
  - `openPage`: 스스로 닫히는 화면용. 빈 화면 위에 push 한다.
  - `employerStore()`, `subinId()` 헬퍼.
- `test/app_store_test.dart`: 액션 상태 전이, JSON 왕복, 날짜별 시드 생성.
- `test/payroll_test.dart`: 급여 경계값.
- `test/web_screens_test.dart`: 웹 메뉴 × 폭(1440·1280·1024·800) 넘침 검사 + 근무표·직원·대타·공지·POS 상호작용.
  - 화면 확인용 스크린샷: `SHOTS_DIR=<폴더> ./flutter/bin/flutter test test/web_screens_test.dart --update-goldens` (실제 폰트로 PNG 저장, 커밋하지 않음). 이 서버엔 화면이 없으니 UI 를 고치면 이걸로 본다.
- 서버 모드 테스트는 `MockClient` 로 가짜 서버를 둔다: `app_store_remote_test.dart`, `mobile_boot_test.dart`, `web_boot_view_test.dart`, `clock_in_remote_test.dart`, `documents_remote_test.dart`, `ai_assistant_test.dart`, `live_refresh_test.dart`, `schedule_draft_save_test.dart`.
- 근무표 개편: `autoschedule_test.dart`, `web_schedule_editor_test.dart`, `web_settings_test.dart`. 기타 `keyboard_dismiss_test.dart`.
- 근무 중 카드는 1초 타이머가 있어 `pumpAndSettle` 대신 `pump(Duration)` 을 쓴다.

## Conventions

- 색은 `AppColors`만 사용. 새 색이 필요하면 `AppColors`에 추가 (파일별 상수 금지).
- 공용으로 쓸 위젯은 `widgets/common.dart`에 두고 중복 정의 금지. 두 역할이 함께 쓰면 common 으로 올린다.
- 변경 후 `analyze` 0 issue, `test` 통과 확인.

## Git

- 브랜치: 기능 브랜치 → `develop` PR → `main` PR → `deploy` PR. `main`/`develop`/`deploy` 에 직접 커밋 금지. 남기는 브랜치는 이 셋뿐, 기능 브랜치는 머지 뒤 지운다.
- 배포: 배포 레포(donBug_deploy) `develop` 은 이 레포 `develop`(테스트 배포), `main` 은 `deploy`(운영)를 가리킨다. 머지 뒤 배포 레포 포인터를 올린다.
- PR 은 merge commit 으로 머지한다. CI 없음 — 머지 전 로컬에서 analyze·test 확인.
- remote는 SSH (`git@github.com:ruraeru/donBug.git`). `gh` CLI 로그인됨.
