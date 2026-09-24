import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'store.dart';
import 'util.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = TripStore();
  await store.load();
  runApp(BasecampApp(store: store));
}

class BasecampApp extends StatelessWidget {
  const BasecampApp({super.key, required this.store});

  final TripStore store;

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
      child: MaterialApp(
        title: 'Basecamp',
        debugShowCheckedModeBanner: false,
        theme: _theme(Brightness.light),
        darkTheme: _theme(Brightness.dark),
        home: const HomeScreen(),
      ),
    );
  }
}
