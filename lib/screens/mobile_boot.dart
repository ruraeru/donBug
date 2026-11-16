import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

import '../data/app_scope.dart';
import '../data/models.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/demo_menu.dart';
import 'employee/join_pending_screen.dart';
import 'employee/login_screen.dart';
import 'employee/role_select_screen.dart';
import 'employee/store_code_screen.dart';

/// 서버 모드 앱 진입. 토큰이 있으면 상태를 읽고 [enterApp], 없으면 [LoginScreen].
class MobileBoot extends StatefulWidget {
  const MobileBoot({super.key});

  @override
  State<MobileBoot> createState() => _MobileBootState();
}

class _MobileBootState extends State<MobileBoot> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    final store = AppScope.read(context);
    if (store.api!.hasToken) {
      try {
        await store.reload();
        if (mounted) return enterApp(context);
      } catch (e) {
        if (mounted) showToast(context, '$e');
      }
    }
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) => const Scaffold(
    backgroundColor: AppColors.bg,
    body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
  );
}

/// 앱 카카오 로그인: 시스템 웹 로그인 시트로 서버 OAuth 를 돌고 `donbug://auth` 로 토큰을 받는다.
Future<void> kakaoAppLogin(BuildContext context) async {
  final store = AppScope.read(context);
  final api = store.api!;
  try {
    final result = await FlutterWebAuth2.authenticate(
      url: api.kakaoAppLoginUrl,
      callbackUrlScheme: 'donbug',
    );
    final q = Uri.parse(result).queryParameters;
    final access = q['access'], refresh = q['refresh'];
    if (access == null || refresh == null) {
      throw Exception(q['error'] ?? '로그인하지 못했어요');
    }
    await api.setTokens(access, refresh);
    await store.reload();
    if (context.mounted) enterApp(context);
  } on PlatformException catch (e) {
    if (e.code == 'CANCELED') return; // 사용자가 로그인 시트를 닫음
    if (context.mounted) showToast(context, '로그인하지 못했어요 (${e.code})');
  } catch (e) {
    if (context.mounted) showToast(context, '로그인하지 못했어요: $e');
  }
}

/// 서버 상태로 첫 화면을 정한다: 매장 없음 → 역할 선택, 가입 대기 → 대기 화면, 그 밖 → 역할별 셸.
void enterApp(BuildContext context) {
  final store = AppScope.read(context);
  final s = store.session;
  final nav = Navigator.of(context);
  if (s.ownerStoreId.isEmpty && s.employeeStoreId.isEmpty) {
    nav.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const RoleSelectScreen()),
      (_) => false,
    );
    return;
  }
  if (s.role == Role.employee &&
      store.membership(s.employeeId, s.employeeStoreId)?.status ==
          StaffStatus.pending) {
    nav.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const StoreCodeScreen()),
      (_) => false,
    );
    nav.push(
      MaterialPageRoute(
        builder: (_) => JoinPendingScreen(storeId: s.employeeStoreId),
      ),
    );
    return;
  }
  openShell(context, s.role);
}
