import 'package:basecamp/main.dart';
import 'package:basecamp/store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('shows the sample trip and opens it', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = TripStore();
    await store.load();
    await tester.pumpWidget(BasecampApp(store: store));
    expect(find.text('Big Sur Weekend'), findsOneWidget);

    await tester.tap(find.text('Big Sur Weekend'));
    await tester.pumpAndSettle();
    expect(find.text('Dates'), findsOneWidget);

    for (final tab in ['Meals', 'Gear', 'Plans', 'Crew']) {
      await tester.tap(find.text(tab).last);
      await tester.pumpAndSettle();
    }
    expect(find.text('Alex Rivera'), findsOneWidget);
  });
}
