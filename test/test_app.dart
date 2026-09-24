import 'package:basecamp/main.dart';
import 'package:basecamp/services/auth_service.dart';
import 'package:basecamp/services/settings_service.dart';
import 'package:basecamp/store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Builds the app on fresh, in-memory storage.
Future<(BasecampApp, TripStore, AuthService)> makeTestApp() async {
  SharedPreferences.setMockInitialValues({});
  final store = TripStore();
  final auth = LocalAuthService();
  final settings = SettingsService();
  await Future.wait([store.load(), auth.load(), settings.load()]);
  return (
    BasecampApp(store: store, auth: auth, settings: settings),
    store,
    auth,
  );
}
