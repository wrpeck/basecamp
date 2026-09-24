import 'package:basecamp/main.dart';
import 'package:basecamp/store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('GPS coordinates entered with hemispheres are saved', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final store = TripStore();
    await store.load();
    await tester.pumpWidget(BasecampApp(store: store));
    await tester.tap(find.text('Big Sur Weekend'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('GPS location'), 300);
    await tester.tap(find.byTooltip('Edit GPS location'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '37.7459 N, 119.5332 W');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final trip = store.trips.single;
    expect(trip.latitude, 37.7459);
    expect(trip.longitude, -119.5332);
    expect(find.text('37.7459° N, 119.5332° W'), findsOneWidget);
  });
}
