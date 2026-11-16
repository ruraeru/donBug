import 'dart:convert';

import 'package:donbug/data/api_client.dart';
import 'package:donbug/data/app_store.dart';
import 'package:donbug/data/models.dart';
import 'package:donbug/data/seed.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _now = DateTime(2026, 5, 14, 14, 30);

void main() {
  test('createContractRemote: 서명 PNG 업로드(multipart) 후 signatureUrl 로 계약 PUT', () async {
    SharedPreferences.setMockInitialValues({'donbug.access': 't', 'donbug.refresh': 'r'});
    final prefs = await SharedPreferences.getInstance();
    final calls = <String>[];
    Object? putBody;
    String? uploadType;
    final state = jsonEncode(buildSeed(_now).toJson());
    final mock = MockClient((req) async {
      calls.add('${req.method} ${req.url.path}');
      if (req.url.path == '/api/v1/me/state') return http.Response.bytes(utf8.encode(state), 200, headers: {'content-type': 'application/json'});
      if (req.url.path == '/api/v1/me/signatures') {
        uploadType = req.headers['content-type'];
        expect(req.headers['Authorization'], 'Bearer t');
        return http.Response('{"signatureUrl":"signatures/1/a.png"}', 200);
      }
      putBody = jsonDecode(req.body);
      return http.Response('{}', 200);
    });
    final api = ApiClient(prefs: prefs, baseUrl: 'http://x', client: mock);
    final s = AppStore(buildSeed(_now), now: () => _now, api: api);
    s.login(Role.employer);
    calls.clear();
    final staff = s.activeStaff.first;
    final c = Contract(start: '2026-06-01', end: '2027-05-31', wage: 11000, weeklyHours: 20, workDays: '월', duty: '');
    await s.createContractRemote(staff.id, c, [1, 2, 3]);
    expect(uploadType, startsWith('multipart/form-data'));
    expect(calls.take(2), ['POST /api/v1/me/signatures', 'PUT /api/v1/stores/${staff.storeId}/staff/${staff.id}/contract']);
    expect((putBody as Map)['ownerSignatureUrl'], 'signatures/1/a.png');
    expect(api.authHeaders, {'Authorization': 'Bearer t'});
  });
}
