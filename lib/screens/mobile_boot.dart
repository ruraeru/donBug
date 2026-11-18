import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

import '../data/api_client.dart';
import '../data/app_scope.dart';
import '../data/models.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/demo_menu.dart';
import 'employee/join_pending_screen.dart';
import 'employee/login_screen.dart';
import 'employee/role_select_screen.dart';
import 'employee/store_code_screen.dart';
import 'web/web_boot.dart';

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
      if (context.mounted) showToast(context, loginErrorText(q['error']));
      return;
    }
    await api.setTokens(access, refresh);
    await store.reload();
    if (context.mounted) enterApp(context);
  } on PlatformException catch (e) {
    if (e.code == 'CANCELED') return; // 사용자가 로그인 시트를 닫음
    if (context.mounted) showToast(context, '로그인하지 못했어요 (${e.code})');
  } on ApiException catch (e) {
    if (context.mounted) showToast(context, e.message);
  } catch (_) {
    if (context.mounted) showToast(context, '로그인하지 못했어요. 다시 시도해 주세요');
  }
}

/// 서버 OAuth 콜백의 `error` 코드를 사용자 문구로 바꾼다(앱·웹 공용).
String loginErrorText(String? code) => switch (code) {
      'kakao_denied' => '카카오 로그인을 취소했어요',
      'invalid_state' => '로그인 시간이 지났어요. 다시 시도해 주세요',
      'missing_code' => '카카오 로그인 응답이 없어요. 다시 시도해 주세요',
      _ => '로그인하지 못했어요. 다시 시도해 주세요',
    };

/// 테스트 계정 로그인: 서버 TEST_LOGIN_TOKEN 과 같은 비밀 토큰을 카카오 토큰 자리에 보낸다.
/// 로그인 화면 로고를 길게 누르면 열린다.
Future<void> testAccountLogin(BuildContext context) async {
  final store = AppScope.read(context);
  final ctrl = TextEditingController();
  final token = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('테스트 계정 로그인'),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        obscureText: true,
        decoration: const InputDecoration(hintText: '테스트 토큰'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
        TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('로그인')),
      ],
    ),
  );
  if (token == null || token.isEmpty) return;
  try {
    final j = await store.api!.post('/api/auth/kakao/token', {'accessToken': token})
        as Map<String, dynamic>;
    await store.api!.setTokens(j['accessToken'] as String, j['refreshToken'] as String);
    if (!context.mounted) return;
    // 웹은 WebBoot 가 상태를 읽고 PC/모바일 화면을 고른다.
    if (kIsWeb) {
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => WebBoot(store: store)), (_) => false);
      return;
    }
    await store.reload();
    if (context.mounted) enterApp(context);
  } catch (e) {
    if (context.mounted) showToast(context, '테스트 로그인 실패: $e');
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
    // 퇴사·거절로 매장이 사라졌으면 그 알림(지금 매장 목록에 없는 매장의 가입 알림)을 한 번 알린다.
    final gone = store.state.notifications
        .where((n) =>
            !n.read && n.type == 'join' && n.toPersonId == s.employeeId && store.storeById(n.storeId) == null)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (gone.isNotEmpty) {
      showToast(context, gone.first.title);
      for (final n in gone) {
        store.markNotificationRead(n.id);
      }
    }
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
