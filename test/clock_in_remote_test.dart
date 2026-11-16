import 'dart:convert';

import 'package:donbug/data/api_client.dart';
import 'package:donbug/data/app_store.dart';
import 'package:donbug/data/seed.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _now = DateTime(2026, 5, 14, 14, 30);

void main() {
  Future<(AppStore, List<http.Request>)> setup(int clockInStatus) async {
    SharedPreferences.setMockInitialValues({'donbug.access': 't', 'donbug.refresh': 'r'});
    final prefs = await SharedPreferences.getInstance();
    final reqs = <http.Request>[];
    final stateJson = jsonEncode(buildSeed(_now).toJson());
    final mock = MockClient((req) async {
      reqs.add(req);
      if (req.url.path == '/api/v1/me/state') {
        return http.Response.bytes(utf8.encode(stateJson), 200,
            headers: {'content-type': 'application/json'});
      }
      if (clockInStatus != 204) {
        return http.Response('{"code":"INVALID_QR","message":"QR 이 달라요"}', clockInStatus,
            headers: {'content-type': 'application/json'});
      }
      return http.Response('', 204);
    });
    final api = ApiClient(prefs: prefs, baseUrl: 'http://x', client: mock);
    return (AppStore(buildSeed(_now), now: () => _now, api: api), reqs);
  }

  test('clockInRemote → 본문에 qrToken, 이어서 state 다시 읽음', () async {
    final (s, reqs) = await setup(204);
    final shift = s.shiftsOn(s.today).firstWhere((x) => s.attendanceFor(x.id) != null);
    await s.clockInRemote(shift.id, 'tok-1');
    expect(reqs.first.url.path, '/api/v1/stores/${shift.storeId}/shifts/${shift.id}/clock-in');
    expect(jsonDecode(reqs.first.body), {'qrToken': 'tok-1'});
    expect(reqs.last.url.path, '/api/v1/me/state');
  });

  test('clockInRemote 실패 → ApiException, reload 안 함', () async {
    final (s, reqs) = await setup(400);
    final shift = s.shiftsOn(s.today).first;
    await expectLater(s.clockInRemote(shift.id, 'bad'), throwsA(isA<ApiException>()));
    expect(reqs.length, 1);
  });
}
