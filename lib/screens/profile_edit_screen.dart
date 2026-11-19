import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/app_scope.dart';
import '../data/app_store.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// 내 프로필 수정 (알바생 MY · 사장님 매장 설정). 웹 PC 화면은 같은 [ProfileForm] 을 창으로 띄운다(web_shell).
class ProfileEditScreen extends StatelessWidget {
  const ProfileEditScreen({super.key});

  @override
  Widget build(BuildContext context) => ProfileForm(
        onSaved: () => Navigator.pop(context),
        layout: (context, fields, save) => Scaffold(
          appBar: const AppHeader('내 프로필'),
          body: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 16), children: fields),
          bottomNavigationBar: BottomBar(child: save),
        ),
      );
}

/// 프로필 사진(바로 반영) · 이름 · 연락처(저장 버튼). [layout] 이 입력 칸들과 저장 버튼을 배치한다.
class ProfileForm extends StatefulWidget {
  const ProfileForm({super.key, required this.layout, required this.onSaved});

  final Widget Function(BuildContext context, List<Widget> fields, Widget save) layout;
  final VoidCallback onSaved;

  @override
  State<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<ProfileForm> {
  late final TextEditingController _name;
  late final TextEditingController _contact;
  bool _saving = false;
  bool _photoBusy = false;

  @override
  void initState() {
    super.initState();
    final p = AppScope.read(context).me;
    _name = TextEditingController(text: p.fullName);
    _contact = TextEditingController(text: p.contact ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _contact.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() call, String done, void Function(bool) busy) async {
    setState(() => busy(true));
    try {
      await call();
      if (mounted) showToast(context, done);
    } on ApiException catch (e) {
      if (mounted) showToast(context, e.message);
    } finally {
      if (mounted) setState(() => busy(false));
    }
  }

  Future<void> _changePhoto() async {
    final picked = await pickPhoto(context, fallbackName: 'profile.jpg');
    if (picked == null || !mounted) return;
    final store = AppScope.read(context);
    await _run(() => store.uploadProfilePhoto(picked.$1, picked.$2), '프로필 사진을 바꿨어요',
        (b) => _photoBusy = b);
  }

  Future<void> _removePhoto() async {
    final store = AppScope.read(context);
    await _run(store.deleteProfilePhoto, '프로필 사진을 지웠어요', (b) => _photoBusy = b);
  }

  Future<void> _save() async {
    final store = AppScope.read(context);
    final p = store.me;
    final name = _name.text.trim();
    final contact = _contact.text.trim();
    var ok = false;
    await _run(() async {
      await store.updateProfile(
        fullName: name != p.fullName ? name : null,
        contact: contact != (p.contact ?? '') ? contact : null,
      );
      ok = true;
    }, '프로필을 저장했어요', (b) => _saving = b);
    if (ok && mounted) widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final p = store.me;
    final name = _name.text.trim();
    final contact = _contact.text.trim();
    final changed = name != p.fullName || contact != (p.contact ?? '');
    final error = AppStore.profileError(fullName: name, contact: contact);
    final canSave = changed && error == null && !_saving;
    final fields = [
      Center(
        child: LetterAvatar(p.letter, size: 88, person: p),
      ),
      const SizedBox(height: 12),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        TextButton(
          onPressed: _photoBusy ? null : _changePhoto,
          child: Text(_photoBusy ? '처리 중…' : (p.hasPhoto ? '사진 변경' : '사진 등록'),
              style: AppText.style(14, FontWeight.w500, AppColors.primary)),
        ),
        if (p.hasPhoto)
          TextButton(
            onPressed: _photoBusy ? null : _removePhoto,
            child: Text('사진 삭제', style: AppText.style(14, FontWeight.w500, AppColors.danger)),
          ),
      ]),
      const SizedBox(height: 16),
      LabeledField('이름',
          child: AppTextField(
              controller: _name, hint: '이름', maxLength: 50, onChanged: (_) => setState(() {}))),
      const SizedBox(height: 8),
      LabeledField('연락처',
          child: AppTextField(
              controller: _contact,
              hint: '010-0000-0000',
              keyboardType: TextInputType.phone,
              maxLength: 20,
              onChanged: (_) => setState(() {}))),
      if (error != null) ...[
        const SizedBox(height: 4),
        Text(error, style: AppText.style(13, FontWeight.w400, AppColors.danger)),
      ],
    ];
    return widget.layout(
      context,
      fields,
      AppButton(_saving ? '저장 중…' : '저장',
          variant: canSave ? AppButtonVariant.primary : AppButtonVariant.soft,
          onPressed: canSave ? _save : null),
    );
  }
}
