import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'platform/safe_insets.dart';

import 'screens/home_screen.dart';
import 'services/auth_service.dart';
import 'services/settings_service.dart';
import 'store.dart';
import 'util.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = TripStore();
  final auth = LocalAuthService();
  final settings = SettingsService();
  await Future.wait([store.load(), auth.load(), settings.load()]);
  runApp(BasecampApp(store: store, auth: auth, settings: settings));
}

class BasecampApp extends StatelessWidget {
  const BasecampApp({
    super.key,
    required this.store,
    required this.auth,
    required this.settings,
  });

  final TripStore store;
  final AuthService auth;
  final SettingsService settings;

  static const forest = Color(0xFF2F5D48);

  ThemeData _theme(Brightness brightness) {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: forest,
          brightness: brightness,
          tertiary: const Color(0xFFD9822B),
        ).copyWith(
          tertiaryContainer: brightness == Brightness.light
              ? const Color(0xFFFFE0C2)
              : const Color(0xFF6B3A10),
          onTertiaryContainer: brightness == Brightness.light
              ? const Color(0xFF5A2E00)
              : const Color(0xFFFFE0C2),
        );
    final base = ThemeData(colorScheme: scheme, useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: brightness == Brightness.light
          ? const Color(0xFFF6F4EE)
          : scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: brightness == Brightness.light
            ? Colors.white
            : scheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: .5)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: scheme.surfaceContainerLowest,
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StoreScope(
      store: store,
      child: AuthScope(
        auth: auth,
        child: SettingsScope(
          settings: settings,
          child: ListenableBuilder(
            listenable: settings,
            builder: (context, _) => MaterialApp(
              title: 'Basecamp',
              debugShowCheckedModeBanner: false,
              theme: _theme(Brightness.light),
              darkTheme: _theme(Brightness.dark),
              themeMode: settings.themeMode,
              builder: (context, child) => _withHostInsets(context, child!),
              home: const HomeScreen(),
            ),
          ),
        ),
      ),
    );
  }

  /// Merges safe-area insets reported by the host web view into
  /// [MediaQuery] so app bars, sheets, dialogs and menus avoid system UI.
  static Widget _withHostInsets(BuildContext context, Widget child) {
    final mq = MediaQuery.of(context);
    var host = hostSafeInsets();
    if (host == EdgeInsets.zero) return child;
    // The keyboard already covers the bottom inset while it is open.
    if (mq.viewInsets.bottom > 0) host = host.copyWith(bottom: 0);
    EdgeInsets merge(EdgeInsets a) => EdgeInsets.fromLTRB(
      math.max(a.left, host.left),
      math.max(a.top, host.top),
      math.max(a.right, host.right),
      math.max(a.bottom, host.bottom),
    );
    return MediaQuery(
      data: mq.copyWith(
        padding: merge(mq.padding),
        viewPadding: merge(mq.viewPadding),
      ),
      child: child,
    );
  }
}
