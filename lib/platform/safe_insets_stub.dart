import 'package:flutter/widgets.dart';

/// Extra safe-area insets reported by the host page. Only the web build has
/// any; native platforms already report them through [MediaQuery].
EdgeInsets hostSafeInsets() => EdgeInsets.zero;
