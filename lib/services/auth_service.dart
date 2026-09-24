import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sign-in methods the UI offers. Only [email] works today, and only
/// locally; the rest are placeholders for a real identity provider.
enum AuthProvider { email, google, apple }

class AppUser {
  const AppUser({
    required this.id,
    required this.displayName,
    required this.email,
    required this.provider,
  });

  final String id;
  final String displayName;
  final String email;
  final AuthProvider provider;

  String get initials {
    final parts = displayName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty);
    final letters = parts.take(2).map((p) => p[0].toUpperCase()).join();
    return letters.isEmpty ? '?' : letters;
  }

  AppUser copyWith({String? displayName, String? email}) => AppUser(
    id: id,
    displayName: displayName ?? this.displayName,
    email: email ?? this.email,
    provider: provider,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'displayName': displayName,
    'email': email,
    'provider': provider.name,
  };

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
    id: j['id'],
    displayName: j['displayName'] ?? '',
    email: j['email'] ?? '',
    provider: AuthProvider.values.firstWhere(
      (p) => p.name == j['provider'],
      orElse: () => AuthProvider.email,
    ),
  );
}

/// The app's view of authentication. Swap [LocalAuthService] for an
/// implementation backed by a real provider (Firebase Auth, Supabase,
/// your own API…) without touching the UI.
abstract class AuthService extends ChangeNotifier {
  AppUser? get currentUser;
  bool get isSignedIn => currentUser != null;

  /// Whether [provider] can be used yet. The UI shows unsupported ones as
  /// "coming soon".
  bool supports(AuthProvider provider);

  Future<void> load();
  Future<void> signInWithEmail({
    required String displayName,
    required String email,
  });
  Future<void> signInWith(AuthProvider provider);
  Future<void> updateProfile({String? displayName, String? email});
  Future<void> signOut();
}

/// Placeholder that "signs in" by remembering a profile on this device.
/// Nothing leaves the device and no password is involved.
class LocalAuthService extends AuthService {
  static const _key = 'basecamp.localUser.v1';

  AppUser? _user;
  SharedPreferences? _prefs;

  @override
  AppUser? get currentUser => _user;

  @override
  bool supports(AuthProvider provider) => provider == AuthProvider.email;

  @override
  Future<void> load() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final raw = _prefs!.getString(_key);
      if (raw != null) {
        _user = AppUser.fromJson(Map<String, dynamic>.from(jsonDecode(raw)));
      }
    } catch (e) {
      debugPrint('Could not load user: $e');
    }
    notifyListeners();
  }

  @override
  Future<void> signInWithEmail({
    required String displayName,
    required String email,
  }) async {
    _user = AppUser(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      displayName: displayName,
      email: email,
      provider: AuthProvider.email,
    );
    await _save();
  }

  @override
  Future<void> signInWith(AuthProvider provider) =>
      throw UnsupportedError('${provider.name} sign-in is not available yet');

  @override
  Future<void> updateProfile({String? displayName, String? email}) async {
    if (_user == null) return;
    _user = _user!.copyWith(displayName: displayName, email: email);
    await _save();
  }

  @override
  Future<void> signOut() async {
    _user = null;
    await _save();
  }

  Future<void> _save() async {
    try {
      if (_user == null) {
        await _prefs?.remove(_key);
      } else {
        await _prefs?.setString(_key, jsonEncode(_user!.toJson()));
      }
    } catch (e) {
      debugPrint('Could not save user: $e');
    }
    notifyListeners();
  }
}
