import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// 주소창 해시(`#/auth?...`)를 지운다. 토큰이 주소창에 남지 않게.
void clearAddressFragment() => web.window.history.replaceState(null, '', '/');

/// 같은 탭에서 [url] 로 이동.
void navigateTo(String url) => web.window.location.href = url;

/// 저장 안 한 변경이 있을 때 탭 닫기·새로고침 경고.
void setLeaveWarning(bool on) {
  web.window.onbeforeunload = on
      ? ((web.Event e) {
          e.preventDefault();
          (e as web.BeforeUnloadEvent).returnValue = '';
        }).toJS
      : null;
}
