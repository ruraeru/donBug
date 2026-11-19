import 'dart:convert';
import 'dart:typed_data';

import 'package:donbug/data/api_client.dart';
import 'package:donbug/data/app_store.dart';
import 'package:donbug/data/format.dart';
import 'package:donbug/data/models.dart';
import 'package:donbug/data/seed.dart';
import 'package:donbug/screens/employee/employee_my_screen.dart';
import 'package:donbug/screens/employer/store_info_edit_screen.dart';
import 'package:donbug/screens/employer/store_settings_screen.dart';
import 'package:donbug/screens/profile_edit_screen.dart';
import 'package:donbug/screens/web/web_settings_screen.dart';
import 'package:donbug/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'widget_test.dart' show employerStore, openPage, pumpAt, testNow, testStore;

/// 보낸 요청을 `calls` 에 쌓는 가짜 서버 (app_store_remote_test 와 같은 모양).
Future<(AppStore, List<String>, List<Object?>)> _remote() async {
  SharedPreferences.setMockInitialValues({'donbug.access': 't', 'donbug.refresh': 'r'});
  final prefs = await SharedPreferences.getInstance();
  final calls = <String>[];
  final bodies = <Object?>[];
  final stateJson = jsonEncode(buildSeed(testNow).toJson());
  final mock = MockClient((req) async {
    calls.add('${req.method} ${req.url.path}');
    final ct = req.headers['content-type'] ?? '';
    bodies.add(req.body.isEmpty || !ct.startsWith('application/json') ? null : jsonDecode(req.body));
    if (req.url.path == '/api/v1/me/state') {
      return http.Response.bytes(utf8.encode(stateJson), 200,
          headers: {'content-type': 'application/json'});
    }
    return http.Response('', 204);
  });
  final store = AppStore(buildSeed(testNow),
      now: () => testNow, api: ApiClient(prefs: prefs, baseUrl: 'http://x', client: mock));
  store.login(Role.employer);
  calls.clear();
  bodies.clear();
  return (store, calls, bodies);
}

class _Page extends StatelessWidget {
  const _Page(this.title, {this.actions = const []});

  final String title;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) =>
      Scaffold(appBar: AppHeader(title, actions: actions), body: const SizedBox());
}

void main() {
  group('뒤로 버튼', () {
    testWidgets('탭 영역 48×48 이상 · 가장자리 탭으로 닫힘', (tester) async {
      await openPage(tester, const _Page('상세'));
      final hit = find.ancestor(of: find.text('‹'), matching: find.byType(InkWell));
      final r = tester.getRect(hit);
      expect(r.width, greaterThanOrEqualTo(48));
      expect(r.height, greaterThanOrEqualTo(48));
      expect(find.byWidgetPredicate((w) => w is Semantics && w.properties.label == '뒤로'), findsOneWidget);
      await tester.tapAt(Offset(r.right - 2, r.bottom - 2));
      await tester.pumpAndSettle();
      expect(find.text('상세'), findsNothing);
      expect(find.text('open'), findsOneWidget);
    });

    testWidgets('긴 제목 + 액션 · 360 폭 넘침 없음', (tester) async {
      await openPage(
          tester,
          _Page('아주 긴 제목이 들어가는 헤더입니다 아주 긴 제목이 들어가는 헤더입니다',
              actions: [HeaderTextAction('수정', onTap: () {}), HeaderTextAction('삭제', onTap: () {})]));
      tester.view.physicalSize = const Size(360, 640);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('‹'), findsOneWidget);
    });
  });

  test('Person.fromJson: 새 키 없으면 기본값, 있으면 읽음', () {
    final old = Person.fromJson({'id': 'p1', 'name': '태우', 'fullName': '김태우', 'certAlertDays': [30]});
    expect((old.contact, old.hasPhoto, old.photoVer), (null, false, null));
    final p = Person.fromJson({
      'id': 'p1',
      'name': '태우',
      'fullName': '김태우',
      'certAlertDays': [30],
      'contact': '010-1234-5678',
      'hasPhoto': true,
      'photoVer': 'v3',
    });
    expect((p.contact, p.hasPhoto, p.photoVer), ('010-1234-5678', true, 'v3'));
    final back = Person.fromJson(p.toJson());
    expect((back.contact, back.hasPhoto, back.photoVer), ('010-1234-5678', true, 'v3'));
  });

  test('프로필 검증 규칙', () {
    expect(AppStore.profileError(fullName: ' 김태우 ', contact: '010-1234-5678'), isNull);
    expect(AppStore.profileError(contact: ''), isNull);
    expect(AppStore.profileError(fullName: '  '), isNotNull);
    expect(AppStore.profileError(fullName: 'a' * 51), isNotNull);
    expect(AppStore.profileError(fullName: '😀' * 50), isNull); // 이모지 1자
    expect(AppStore.profileError(contact: ' '), isNotNull);
    expect(AppStore.profileError(contact: '010 1234'), isNotNull);
    expect(AppStore.profileError(contact: '1' * 21), isNotNull);
  });

  group('서버 호출', () {
    test('updateProfile → PATCH /me/profile (바뀐 키만)', () async {
      final (s, calls, bodies) = await _remote();
      await s.updateProfile(fullName: ' 새이름 ', contact: '010-1234-5678');
      expect(calls.first, 'PATCH /api/v1/me/profile');
      expect(bodies.first, {'fullName': '새이름', 'contact': '010-1234-5678'});
      expect(calls.last, 'GET /api/v1/me/state');
      calls.clear();
      bodies.clear();
      await s.updateProfile(contact: '');
      expect(bodies.first, {'contact': ''});
    });

    test('잘못된 입력은 보내지 않고 던진다', () async {
      final (s, calls, _) = await _remote();
      await expectLater(s.updateProfile(contact: 'abc'), throwsA(isA<ApiException>()));
      expect(calls, isEmpty);
    });

    test('사진 올리기 · 지우기 → PUT/DELETE /me/photo', () async {
      final (s, calls, _) = await _remote();
      await s.uploadProfilePhoto(Uint8List.fromList([1, 2, 3]), 'a.jpg');
      expect(calls.first, 'PUT /api/v1/me/photo');
      calls.clear();
      await s.deleteProfilePhoto();
      expect(calls.first, 'DELETE /api/v1/me/photo');
      expect(s.personPhotoUrl(Person(id: '7', name: 'a', fullName: 'a', hasPhoto: true, photoVer: 'v2')),
          'http://x/api/v1/people/7/photo?v=v2');
    });

    test('updateStoreSettings(address) → PATCH settings 에 address', () async {
      final (s, calls, bodies) = await _remote();
      await s.updateStoreSettings(address: '서울시 새 주소 1');
      expect(calls.first, 'PATCH /api/v1/stores/${s.store.id}/settings');
      expect(bodies.first, {'address': '서울시 새 주소 1'});
      await expectLater(s.updateStoreSettings(address: '  '), throwsA(isA<ApiException>()));
    });
  });

  test('데모: 사진은 메모리에, 지우면 사라짐', () async {
    final s = testStore();
    await s.uploadProfilePhoto(Uint8List.fromList([1, 2, 3]), 'a.jpg');
    expect(s.me.hasPhoto, isTrue);
    expect(s.demoPhotos[s.me.id], isNotNull);
    await s.deleteProfilePhoto();
    expect((s.me.hasPhoto, s.demoPhotos[s.me.id]), (false, null));
  });

  testWidgets('사진 있으면 아바타가 사진, 없으면 글자', (tester) async {
    final s = testStore();
    final p = s.me;
    await pumpAt(tester, Scaffold(body: LetterAvatar(p.letter, person: p)), const Size(390, 844), store: s);
    expect(find.text(p.letter), findsOneWidget);
    await s.uploadProfilePhoto(Uint8List.fromList([1, 2, 3]), 'a.jpg');
    await tester.pump();
    expect(find.byType(Image), findsOneWidget);
    // 깨진 사진이면 글자로 돌아간다.
    await tester.pumpAndSettle();
    expect(find.text(p.letter), findsOneWidget);
  });

  testWidgets('서버 모드: 사진 요청이 실패하면(403·404 등) 글자 아바타', (tester) async {
    final (s, _, _) = await _remote();
    final p = Person(id: '9', name: '전', fullName: '전직원', hasPhoto: true, photoVer: 'v1');
    await pumpAt(tester, Scaffold(body: LetterAvatar(p.letter, person: p)), const Size(390, 844), store: s);
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsOneWidget);
    expect(find.text('전'), findsOneWidget);
  });

  for (final size in const [Size(360, 640), Size(390, 844)]) {
    testWidgets('새 화면 넘침 없음 @${size.width.toInt()}', (tester) async {
      await pumpAt(tester, const ProfileEditScreen(), size, store: testStore());
      expect(tester.takeException(), isNull);
      expect(find.text('연락처'), findsOneWidget);
      await pumpAt(tester, const StoreInfoEditScreen(), size, store: employerStore());
      expect(tester.takeException(), isNull);
      expect(find.text('주말·공휴일 영업시간'), findsOneWidget);
      await pumpAt(tester, const StoreSettingsScreen(), size, store: employerStore());
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('프로필 저장 (데모): 이름·연락처 바뀌고 닫힘, 잘못된 연락처는 막음', (tester) async {
    final s = await openPage(tester, const ProfileEditScreen());
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(1), '010-12a');
    await tester.pump();
    expect(find.text('연락처는 숫자와 - 로 20자 이하로 입력해 주세요'), findsOneWidget);
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    expect(s.me.contact, isNull);
    await tester.enterText(fields.at(0), '김새이름');
    await tester.enterText(fields.at(1), '010-1234-5678');
    await tester.pump();
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    expect((s.me.fullName, s.me.name, s.me.contact), ('김새이름', '김새이름', '010-1234-5678'));
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('매장 정보 저장 (데모): 이름·주소 바뀜', (tester) async {
    final s = await openPage(tester, const StoreInfoEditScreen(), store: employerStore());
    expect(find.text(hm(s.store.openMin)), findsWidgets);
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '새 매장');
    await tester.enterText(fields.at(1), '부산시 해운대구 1');
    await tester.pump();
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    expect((s.store.name, s.store.address), ('새 매장', '부산시 해운대구 1'));
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('진입: 알바생 MY 프로필 카드 · 사장님 매장 설정', (tester) async {
    final s = testStore();
    s.me.contact = '010-9999-0000';
    await pumpAt(tester, const Scaffold(body: EmployeeMyScreen()), const Size(390, 844), store: s);
    expect(find.text('010-9999-0000'), findsOneWidget);
    await tester.tap(find.text(s.me.fullName));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileEditScreen), findsOneWidget);

    await pumpAt(tester, const StoreSettingsScreen(), const Size(390, 844), store: employerStore());
    await tester.tap(find.text('매장 정보 수정'));
    await tester.pumpAndSettle();
    expect(find.byType(StoreInfoEditScreen), findsOneWidget);
    await tester.tap(find.text('‹'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('내 프로필'));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileEditScreen), findsOneWidget);
  });

  testWidgets('웹 매장 설정: 주소 입력 → 저장', (tester) async {
    final store = employerStore();
    await pumpAt(tester, const Scaffold(body: WebSettingsScreen()), const Size(1280, 900), store: store);
    expect(find.text('주소'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(1), '대구시 새 주소');
    await tester.pump();
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    expect(store.store.address, '대구시 새 주소');
  });
}
