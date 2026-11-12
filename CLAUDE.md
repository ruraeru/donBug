# donBug

Flutter app (돈벌래 - 스마트 매장 관리 앱). 소상공인 사장님·알바생용 매장 관리: QR 출퇴근, 근무표, 대타, 급여, 서류(근로계약서·보건증), 공지. 모바일 앱 + 사장님 웹/POS 화면.

현재 상태: **프로토타입**. 백엔드·실제 로그인 없이 기기 안 데이터(`lib/data/`)로 동작한다.
- 모바일 알바생·사장님 화면은 전부 데이터에 연결돼 있다.
- 웹(`lib/screens/web/`)도 사장님 W1–W6, 대타 승인, POS W8–W9 가 데이터에 연결돼 있다. 근무표는 Figma v3 오토스케줄 W2(`151:9248`) 기준이다.
- AI 노무 도우미(모바일 B6, 웹 W7)는 "추후 개발 예정" 안내만 있다. 모바일 B6 은 진입 경로가 없다.

아직 안 만든 것 (웹 근무표 v3 작업 기준):
- 웹 인건비 "PDF 내보내기"·"정산 확정"은 "추후 개발 예정" 토스트만 띄운다. 근무표 "저장"은 늘 자동 저장이라 비활성이다.
- 일간 보기에서 블록 가장자리를 끌어 시간 조정하는 기능은 없다(수정 창에서 바꾼다).
- 근무 창의 "휴게 시작"은 "자동" 고정이다.
- 모바일 근무표(알바생·사장님)는 `shiftsOn` 을 써서 연차·휴무·시간 미정 근무를 숨기기만 한다. 칩으로 보여 주지 않는다.
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
./flutter/bin/flutter run
./flutter/bin/flutter build web   # 이 서버에는 에뮬레이터·화면이 없어 컴파일 확인용
```

## Structure

- `lib/main.dart`
  - prefs 에서 상태를 읽어 `AppStore` 를 만들고 `MyApp(store:)` 을 `AppScope` 로 감싼다.
  - 웹이면 역할을 사장님으로 고정하고 로그인 없이 `WebShell`. 그 밖에는 로그인 상태면 역할 셸(`EmployeeShell` / `EmployerShell`), 아니면 `LoginScreen`.
- `lib/data/` — 프로토타입 데이터 계층
  - `models.dart`: `Person`(보건증은 사람 단위), `Store`(`scheduleConfirmedAt`), `Staff`(매장별 소속. 가입 신청 = `status: pending`, 계약서 포함, `kind`: 매니저·정직원·알바·연소자), `Shift`(`kind`: 근무·연차·휴무, `timeTbd`: 시간 미정), `Attendance`, `SubstituteRequest`, `Notice`, `AppNotification`, `Session`, `AppState`. 수동 JSON 직렬화.
  - 매니저·정직원(`StaffKind.flex`)은 유동 근무: 파트 대신 `part: '직원'` 으로 시간을 직접 정한다.
  - `app_store.dart`: `AppStore extends ChangeNotifier`. 조회·파생값(내 근무, 출근 상태, 대타, 급여, 인건비, 안 읽은 수)과 모든 액션(출퇴근, 대타, 근무표, 직원, 공지, 서류, 매장, 세션, 데모). 액션마다 관련자에게 `AppNotification` 을 만든다.
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
- `lib/widgets/demo_menu.dart` — `openShell(context, role)`, `logoutToLogin`, `DemoMenu`(역할 전환 · 데모 데이터 초기화).
- `lib/widgets/tab_shell.dart` — 하단 탭 셸. `TabShell.of(context)?.select(i)`로 탭 전환.
- `lib/screens/employee/` — 알바생 화면. 전용 위젯은 `employee_parts.dart`(`CheckLine`, `ShiftHeroCard`, `TabTitle`, `SignaturePad`, `shiftStatus`).
- `lib/screens/employer/` — 사장님 화면. 전용 위젯은 `employer_parts.dart`(`SegmentedPicker`, `CountStepper`, `SmallButton`, `SuccessStepsScaffold`, `showWageDialog`, `pickStaff`, `pickTime`, `partColors`, `attStyle`, `employerTarget`).
- `lib/screens/web/` — 사장님 웹(W1–W7, 대타 승인)과 POS QR(W8–W9).
  - `web_shell.dart`: 폭 1100 이상 사이드바, 800–1100 아이콘 레일, 800 미만 상단 바 + 서랍. 메뉴 이동은 `WebShell.open(context, WebMenu.xxx)`.
  - 웹 공용은 `web_common.dart`: `WebPage`(제목 + 액션, 안 들어가면 액션이 아래 줄), `WebButton`, `WebRow`, `WebSplit`, `WebTable`(`onRowTap`, 좁으면 가로 스크롤), `WebSegmented`, `WebSelect`, `showWebDialog`, `showWebSheet`, `webField`/`webPair`, `DashedBorderPainter`.
  - 상세·작성은 웹 전용 창이다: 근무 추가·수정(`web_shift_dialog.dart`), 직원 상세 시트·직원 초대(`web_staff_screen.dart`), 계약서 작성(`web_documents_screen.dart`), 공지 작성(`web_notice_screen.dart`), 알림·오늘 근무·근태 수정(`web_dashboard_screen.dart`).
  - 근무표(`web_schedule_screen.dart` + `web_schedule_views.dart`): 한 달·파트별·인원별·일간. 빈 칸 클릭 = 추가, 블록 클릭 = 수정, 블록 드래그 = 이동(겹침·지난 날짜 막음). 되돌리기·자동 채우기·확정하기.
- `assets/icons/` — Figma에서 받은 SVG (`flutter_svg`). `assets/images/app_icon.svg` — 로고 App Icon(Figma `186:174`). `assets/fonts/` — Noto Sans KR 400/500/700 (OFL).

## 프로토타입 데이터 규칙

- 화면은 상수를 두지 말고 `AppScope.of(context)` 값으로 그린다. 바꾸는 일은 `AppStore` 액션으로만 한다(화면에서 모델 직접 수정 금지). 탭에 남는 로컬 사본 상태(`_working` 같은)를 두지 않는다.
- 상세 화면은 id 를 받는다(`ShiftDetailScreen(shiftId:)` 등). 대상이 없으면 `MissingScreen`.
- 근무 날짜는 `'yyyy-MM-dd'` + `startMin`/`endMin`(하루 기준 분, `end <= start` 면 야간). 시각만 ISO 문자열.
- 근무 조회는 두 갈래다. `shiftsOn`·`shiftsOfStaff` 는 실제 근무(`Shift.isWork`: 근무 + 시간 확정)만 → 출퇴근·근태·급여·대타는 이것만 쓴다. 근무표 표시는 `scheduleOn`·`scheduleOfStaff`(연차·휴무·미정 포함).
- 연차는 소정 시간만큼 유급(`payslip`), 휴무·미정은 0원.
- 근무표 액션(`addShift`·`updateShift`·`deleteShift`·`autoFill`·`applyTemplate`)은 직전 상태를 되돌리기 스택(메모리)에 쌓는다.
- id 는 `AppState.nextId` 카운터(`'s12'`). 시드의 사람·매장은 고정 id (`p-taewoo`, `p-owner`, `st-cafe`, `st-moa`).
- 저장: SharedPreferences 키 `donbug.state` 에 JSON 한 덩어리. **모델 스키마를 바꾸면 `AppState.version` 을 올린다** (다르면 저장본을 버리고 시드로 시작).
- 시드는 실제 오늘 기준이다.
  - 알바생(김태우)은 오늘 근무가 항상 있다(미들 14–20, 오늘 포함 격일 3일).
  - 카페 커푸치노: `CAFE-8K2D`, 5인 이상(재직 7명), 데모 사장님 소유. 매니저 지훈(유동 근무), 알바 지민·수빈·하윤·태우·서연, 연소자 유나, 가입 대기 도현.
  - 근무: 지난달 1일이 든 주부터 다음 주(또는 이번 달 끝 주)까지. 파트(오픈 10–16 · 미들 14–20 · 마감 18–22)마다 필요 1명을 매일 채운다. 일부러 남긴 것: 다음 주 일요일 마감 빈칸(자동 채우기 시연), 지훈 다음 주 토요일 시간 미정, 지훈 이번 주 연차 1건.
  - 보건증: 수빈 D-12, 태우 D-25, 도현 미등록. 계약서 직원 미서명: 태우·서연.
  - 편의점 모아: `MOA-27QX`, 태우 야간. 사장님 화면 없음.
  - 진행 중 대타 2건: 수빈 → 지민 수락(승인 대기), 하윤(지원 대기).
- 급여 규칙(근사)
  - 기본급 = 실근무 분 × 시급.
  - 주휴수당: 그 주 대타 제외 15시간 이상, 일요일이 속한 달에 지급.
  - 가산(5인 이상 + 직원 설정): 야간·8시간 초과분에 0.5배 추가.
  - 공제: 3.3%(원 단위 내림), 4대보험 근사 9.4%(화면에 "예상" 표기), 없음.
  - 시급은 최저임금 미만으로 저장할 수 없다.
- 인건비 추이의 2달 전 이전은 `Store.monthlyTotals` 상수다. 시드가 근무 패턴으로 낸 월 인건비에 작은 변동을 줘 만든다.
- 데모 장치
  - 역할 전환·초기화: `DemoMenu`(알바생 MY, 사장님 매장 설정). 웹은 사이드바 "데모 데이터 초기화"
  - POS QR(웹 W8): QR 을 누르면 오늘 아직 출근하지 않은 다음 근무자가 출근
  - "동료 수락 (데모)" 버튼: 대타 요청 현황
  - "사장님이 승인한 것으로 (데모)" 버튼: 가입 대기
  - 탭하면 성공하는 모의 동작: QR 스캔, 보건증 사진
  - `SignaturePad`: 손가락 서명
- 사장님은 1인 1매장이다. 매장 만들기는 기존 매장 정보를 바꾼다.

## Tests

- `test/widget_test.dart`
  - `pumpAt(tester, home, size, store:)`: 고정 시각 2026-05-14(목) 14:30 시드 store 를 주입한다.
  - `openPage`: 스스로 닫히는 화면용. 빈 화면 위에 push 한다.
  - `employerStore()`, `subinId()` 헬퍼.
- `test/app_store_test.dart`: 액션 상태 전이, JSON 왕복, 날짜별 시드 생성.
- `test/payroll_test.dart`: 급여 경계값.
- `test/web_screens_test.dart`: 웹 메뉴 × 폭(1440·1280·1024·800) 넘침 검사 + 근무표·직원·대타·공지·POS 상호작용.
  - 화면 확인용 스크린샷: `SHOTS_DIR=<폴더> ./flutter/bin/flutter test test/web_screens_test.dart --update-goldens` (실제 폰트로 PNG 저장, 커밋하지 않음). 이 서버엔 화면이 없으니 UI 를 고치면 이걸로 본다.
- 근무 중 카드는 1초 타이머가 있어 `pumpAndSettle` 대신 `pump(Duration)` 을 쓴다.

## Conventions

- 색은 `AppColors`만 사용. 새 색이 필요하면 `AppColors`에 추가 (파일별 상수 금지).
- 공용으로 쓸 위젯은 `widgets/common.dart`에 두고 중복 정의 금지. 두 역할이 함께 쓰면 common 으로 올린다.
- 변경 후 `analyze` 0 issue, `test` 통과 확인.

## Git

- 브랜치: 기능 브랜치 → `develop` PR → `main` PR. `main`/`develop`에 직접 커밋 금지.
- PR 은 merge commit 으로 머지한다. CI 없음 — 머지 전 로컬에서 analyze·test 확인.
- remote는 SSH (`git@github.com:ruraeru/donBug.git`). `gh` CLI 로그인됨.
