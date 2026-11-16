import 'package:flutter/material.dart';

import '../../data/app_scope.dart';
import '../../data/app_store.dart';
import '../mobile_boot.dart';
import 'web_boot.dart';

/// 웹 보기 모드: PC 대시보드([WebShell]) 또는 모바일 앱 화면. 저장값이 없으면 화면 폭으로 정한다.
const _key = 'donbug.webView';
const _narrow = 700.0;

/// 켜지면 앱 전체를 가운데 폭 480 으로 좁힌다 (PC 에서 모바일 화면 볼 때).
final webMobileFrame = ValueNotifier<bool>(false);

bool wantsMobileView(BuildContext context, AppStore store) {
  final s = store.session;
  // PC 대시보드는 사장님 전용이다. 알바생 매장만 있으면 항상 모바일.
  if (s.ownerStoreId.isEmpty && s.employeeStoreId.isNotEmpty) return true;
  return switch (store.api!.prefs.getString(_key)) {
    'mobile' => true,
    'pc' => false,
    _ => MediaQuery.sizeOf(context).width < _narrow,
  };
}

/// 모바일 앱 화면으로: 매장 없음 → 역할 선택, 가입 대기 → 대기 화면, 그 밖 → 역할별 셸.
void openMobileView(BuildContext context, {bool remember = true}) {
  final store = AppScope.read(context);
  if (remember) store.api!.prefs.setString(_key, 'mobile');
  webMobileFrame.value = true;
  enterApp(context);
}

/// PC 대시보드로.
void openPcView(BuildContext context) {
  final store = AppScope.read(context);
  store.api!.prefs.setString(_key, 'pc');
  webMobileFrame.value = false;
  Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => WebBoot(store: store)), (_) => false);
}
