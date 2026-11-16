import 'package:flutter/material.dart';

import '../../data/api_client.dart';
import '../../data/app_store.dart';
import '../../data/models.dart';
import '../../theme.dart';
import 'web_create_store_screen.dart';
import 'web_login_screen.dart';
import 'web_shell.dart';
import 'web_url.dart';

enum _Phase { loading, login, createStore, ready }

/// 서버 모드 웹 진입. 토큰 확인 → 상태 읽기 → (매장 없으면 만들기) → [WebShell].
class WebBoot extends StatefulWidget {
  const WebBoot({super.key, required this.store});

  final AppStore store;

  /// 로그아웃하고 로그인 화면으로.
  static Future<void> logout(BuildContext context) =>
      context.findAncestorStateOfType<_WebBootState>()?._logout() ?? Future.value();

  @override
  State<WebBoot> createState() => _WebBootState();
}

class _WebBootState extends State<WebBoot> {
  _Phase _phase = _Phase.loading;
  String? _error;

  ApiClient get _api => widget.store.api!;

  @override
  void initState() {
    super.initState();
    _api.onUnauthorized = () {
      if (mounted) setState(() => _phase = _Phase.login);
    };
    _start();
  }

  /// 카카오 콜백이 `/#/auth?access=..&refresh=..` 또는 `?error=..` 로 돌려보낸다.
  Future<void> _start() async {
    final frag = Uri.base.fragment;
    final q = frag.contains('?') ? Uri.splitQueryString(frag.split('?').last) : <String, String>{};
    if (frag.startsWith('/auth')) {
      clearAddressFragment();
      final access = q['access'], refresh = q['refresh'];
      if (access != null && refresh != null) {
        await _api.setTokens(access, refresh);
      } else {
        _error = q['error'] ?? '로그인하지 못했어요';
      }
    }
    await _load();
  }

  Future<void> _load() async {
    if (!_api.hasToken) {
      if (mounted) setState(() => _phase = _Phase.login);
      return;
    }
    if (mounted) setState(() => _phase = _Phase.loading);
    try {
      await widget.store.reload();
      if (!mounted) return;
      setState(() => _phase = widget.store.session.ownerStoreId.isEmpty
          ? _Phase.createStore
          : _Phase.ready);
    } catch (e) {
      if (!mounted) return;
      // 401 이면 onUnauthorized 가 이미 토큰을 지웠다. 그 밖의 실패는 메시지를 남기고 로그인으로.
      setState(() {
        _error = _error ?? '$e';
        _phase = _Phase.login;
      });
    }
  }

  Future<void> _logout() async {
    await _api.logout();
    if (mounted) setState(() => _phase = _Phase.login);
  }

  Future<void> _create({
    required String name,
    required String address,
    required bool isSmall,
    required Deduction deduction,
  }) async {
    await widget.store.createStoreRemote(
        name: name, address: address, isSmall: isSmall, deduction: deduction);
    if (mounted) setState(() => _phase = _Phase.ready);
  }

  @override
  Widget build(BuildContext context) => switch (_phase) {
        _Phase.loading => const Scaffold(
            backgroundColor: AppColors.bg,
            body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          ),
        _Phase.login => WebLoginScreen(
            error: _error,
            onKakao: () {
              _error = null;
              navigateTo(_api.kakaoLoginUrl);
            },
          ),
        _Phase.createStore => WebCreateStoreScreen(onCreate: _create, onLogout: _logout),
        _Phase.ready => const WebShell(),
      };
}
