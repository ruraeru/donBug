import 'package:flutter/widgets.dart';

import 'app_store.dart';

/// [AppStore]를 위젯 트리에 내려준다.
///
/// - `AppScope.of(context)`: build 에서 쓴다. store 가 바뀌면 다시 그린다.
/// - `AppScope.read(context)`: 버튼 콜백 등에서 쓴다. 구독하지 않는다.
class AppScope extends InheritedNotifier<AppStore> {
  const AppScope({super.key, required AppStore store, required super.child})
      : super(notifier: store);

  static AppStore of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  static AppStore read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
