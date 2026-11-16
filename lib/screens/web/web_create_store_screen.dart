import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'web_common.dart';

/// 서버 모드 첫 로그인: 사장님이 아직 매장이 없을 때.
class WebCreateStoreScreen extends StatefulWidget {
  const WebCreateStoreScreen({super.key, required this.onCreate, required this.onLogout});

  final Future<void> Function({
    required String name,
    required String address,
    required bool isSmall,
    required Deduction deduction,
  }) onCreate;
  final VoidCallback onLogout;

  @override
  State<WebCreateStoreScreen> createState() => _WebCreateStoreScreenState();
}

class _WebCreateStoreScreenState extends State<WebCreateStoreScreen> {
  final _name = TextEditingController();
  final _address = TextEditingController();
  bool _small = false;
  Deduction _deduction = Deduction.biz33;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      showToast(context, '매장 이름을 입력해 주세요');
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.onCreate(
          name: name, address: _address.text.trim(), isSmall: _small, deduction: _deduction);
    } catch (e) {
      if (mounted) showToast(context, '$e');
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text('매장 만들기', style: AppText.style(24, FontWeight.w700)),
                const SizedBox(height: 6),
                Text('처음 오셨네요. 매장 정보를 입력해 주세요.',
                    style: AppText.style(14, FontWeight.w400, AppColors.textSecondary)),
                const SizedBox(height: 24),
                webField('매장 이름', AppTextField(controller: _name, hint: '예: 카페 커푸치노')),
                const SizedBox(height: 16),
                webField('주소', AppTextField(controller: _address, hint: '매장 주소')),
                const SizedBox(height: 16),
                ToggleCard(
                  title: '5인 미만 사업장',
                  subtitle: '연장·야간 가산수당이 적용되지 않아요',
                  value: _small,
                  onChanged: (v) => setState(() => _small = v),
                ),
                const SizedBox(height: 16),
                webField(
                    '기본 공제',
                    WebSelect<Deduction>(
                      value: _deduction,
                      items: [for (final d in Deduction.values) (d, d.label)],
                      onChanged: (v) => setState(() => _deduction = v),
                    )),
                const SizedBox(height: 24),
                WebButton(_busy ? '만드는 중…' : '매장 만들기',
                    height: 50, expand: true, onPressed: _busy ? null : _submit),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: widget.onLogout,
                  child: Text('로그아웃',
                      style: AppText.style(13, FontWeight.w500, AppColors.textTertiary)),
                ),
              ]),
            ),
          ),
        ),
      );
}
