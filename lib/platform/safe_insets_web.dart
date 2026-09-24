import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/widgets.dart';

@JS('basecampSafeInsets')
external JSArray<JSNumber> _safeInsets();

/// Safe-area insets measured by `basecampSafeInsets` in web/index.html.
/// Flutter web leaves [MediaQuery.padding] at zero, so without this the app
/// bar and menus draw under the status bar in full-screen web views.
EdgeInsets hostSafeInsets() {
  try {
    if (!globalContext.has('basecampSafeInsets')) return EdgeInsets.zero;
    final v = _safeInsets().toDart.map((n) => n.toDartDouble).toList();
    if (v.length < 4) return EdgeInsets.zero;
    return EdgeInsets.fromLTRB(v[3], v[0], v[1], v[2]);
  } catch (_) {
    return EdgeInsets.zero;
  }
}
