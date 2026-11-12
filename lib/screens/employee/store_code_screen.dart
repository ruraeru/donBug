import 'package:flutter/material.dart';

import '../../data/app_scope.dart';
import '../../data/app_store.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'join_approved_screen.dart';
import 'join_pending_screen.dart';

/// 매장 코드 입력. [addMode]: MY 에서 다른 매장 추가 가입.
class StoreCodeScreen extends StatefulWidget {
  const StoreCodeScreen({super.key, this.addMode = false});

  final bool addMode;

  @override
  State<StoreCodeScreen> createState() => _StoreCodeScreenState();
}

class _StoreCodeScreenState extends State<StoreCodeScreen> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _submit() {
    final store = AppScope.read(context);
    final (result, st) = store.requestJoin(_code.text);
    switch (result) {
      case JoinResult.notFound:
        showToast(context, '매장 코드를 찾을 수 없어요');
      case JoinResult.alreadyMember:
        if (widget.addMode) return showToast(context, '이미 가입한 매장이에요');
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => JoinApprovedScreen(storeId: st!.id)));
      case JoinResult.requested:
      case JoinResult.alreadyPending:
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => JoinPendingScreen(storeId: st!.id)));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppHeader(widget.addMode ? '매장 추가 가입' : '매장 가입'),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          children: [
            Text('사장님께 받은\n매장 코드를 입력해주세요', style: AppText.style(22, FontWeight.w500)),
            const SizedBox(height: 16),
            TextField(
              controller: _code,
              textAlign: TextAlign.center,
              textCapitalization: TextCapitalization.characters,
              maxLength: 9,
              onSubmitted: (_) => _submit(),
              style: AppText.style(22, FontWeight.w500).copyWith(letterSpacing: 4),
              decoration: InputDecoration(
                hintText: 'CAFE-8K2D',
                hintStyle: AppText.style(22, FontWeight.w500, AppColors.border)
                    .copyWith(letterSpacing: 4),
                counterText: '',
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary)),
              ),
            ),
            const SizedBox(height: 16),
            AppButton(
              'QR 코드로 입력하기 (데모)',
              variant: AppButtonVariant.outline,
              // shortcut: 카메라 대신 데모 매장 코드를 채운다.
              onPressed: () => setState(() =>
                  _code.text = widget.addMode ? 'MOA-27QX' : 'CAFE-8K2D'),
            ),
            const SizedBox(height: 16),
            const NoteBox(
              '매장 코드는 사장님 앱의 [매장 설정]에서 확인할 수 있어요. 여러 매장에서 일하면 코드를 추가로 입력하세요.\n데모 매장 코드: CAFE-8K2D · MOA-27QX',
              color: AppColors.info,
              background: AppColors.infoSoft,
            ),
          ],
        ),
        bottomNavigationBar: BottomBar(child: AppButton('가입 신청하기', onPressed: _submit)),
      );
}
