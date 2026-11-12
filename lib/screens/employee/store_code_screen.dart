import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/app_scope.dart';
import '../../data/app_store.dart';
import '../../data/models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/demo_menu.dart';
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
  final _focus = FocusNode();

  @override
  void dispose() {
    _code.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _submit() {
    final store = AppScope.read(context);
    final (result, st) = store.requestJoin(_code.text);
    switch (result) {
      case JoinResult.notFound:
        showToast(context, '매장 코드를 찾을 수 없어요');
      case JoinResult.alreadyMember:
        // 로그인 직후(매장 가입)면 그 매장 홈으로 들어간다. MY 의 추가 가입은 안내만.
        if (!widget.addMode && store.switchStore(st!.id)) return openShell(context, Role.employee);
        showToast(context, '이미 가입한 매장이에요');
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
            _CodeBoxes(controller: _code, focus: _focus, onSubmit: _submit),
            const SizedBox(height: 16),
            AppButton(
              'QR 코드로 입력하기 (데모)',
              variant: AppButtonVariant.outline,
              // shortcut: 카메라 대신 데모 매장 코드를 채운다.
              onPressed: () => setState(() =>
                  _code.text = 'BAKE5TQ1'),
            ),
            const SizedBox(height: 16),
            const NoteBox(
              '매장 코드는 사장님 앱의 [매장 설정]에서 확인할 수 있어요. 여러 매장에서 일하면 코드를 추가로 입력하세요.\n데모 매장 코드: CAFE-8K2D(가입됨) · BAKE-5TQ1',
              color: AppColors.textSecondary,
              background: AppColors.surface,
            ),
          ],
        ),
        bottomNavigationBar: BottomBar(child: AppButton('가입 신청하기', onPressed: _submit)),
      );
}

/// 매장 코드 8칸 입력. 보이지 않는 TextField 가 입력을 받고 칸은 글자를 보여 준다(Figma 43:3).
class _CodeBoxes extends StatelessWidget {
  const _CodeBoxes({required this.controller, required this.focus, required this.onSubmit});

  final TextEditingController controller;
  final FocusNode focus;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          ListenableBuilder(
            listenable: Listenable.merge([controller, focus]),
            builder: (_, _) {
              final text = controller.text;
              return Row(
                children: [
                  for (var i = 0; i < 8; i++) ...[
                    if (i > 0) const SizedBox(width: 6),
                    Expanded(
                      child: Container(
                        height: 52,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: focus.hasFocus && i == text.length.clamp(0, 7)
                                  ? AppColors.primary
                                  : AppColors.border),
                        ),
                        child: Text(i < text.length ? text[i] : '',
                            style: AppText.style(20, FontWeight.w500)),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
          Positioned.fill(
            child: TextField(
              controller: controller,
              focusNode: focus,
              autofocus: true,
              maxLength: 8,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                TextInputFormatter.withFunction(
                    (_, v) => v.copyWith(text: v.text.toUpperCase())),
              ],
              onSubmitted: (_) => onSubmit(),
              showCursor: false,
              enableInteractiveSelection: false,
              style: const TextStyle(color: Colors.transparent),
              decoration: const InputDecoration(
                  border: InputBorder.none, counterText: '', fillColor: Colors.transparent),
            ),
          ),
        ],
      );
}
