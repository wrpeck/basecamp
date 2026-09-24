import 'package:flutter_test/flutter_test.dart';

import 'test_app.dart';

void main() {
  testWidgets('shows the sample trip and opens it', (tester) async {
    final (app, store, _) = await makeTestApp();
    await tester.pumpWidget(app);
    expect(find.text('Big Sur Weekend'), findsOneWidget);

    await tester.tap(find.text('Big Sur Weekend'));
    await tester.pumpAndSettle();
    expect(find.text('Dates'), findsOneWidget);

    for (final tab in ['Meals', 'Gear', 'Plans', 'Crew']) {
      await tester.tap(find.text(tab).last);
      await tester.pumpAndSettle();
    }
    expect(find.text('Jordan Lee'), findsOneWidget);
  });
}
