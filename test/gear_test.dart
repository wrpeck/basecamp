import 'package:basecamp/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_app.dart';

void main() {
  Trip trip(Camper me) => Trip(
    name: 't',
    startDate: DateTime(2026, 10, 1),
    endDate: DateTime(2026, 10, 2),
    campers: [me],
  );

  test('applying a gear list splits group and personal items', () {
    final me = Camper(name: 'Me', isMe: true);
    final t = trip(me);
    final list = GearTemplate(
      name: 'x',
      items: [
        TemplateItem(name: 'Stove', category: 'Kitchen'),
        TemplateItem(name: 'Boots', category: 'Clothing', personal: true),
      ],
    );
    expect(t.applyTemplate(list, ownerId: me.id), 2);
    final stove = t.gear.firstWhere((g) => g.name == 'Stove');
    final boots = t.gear.firstWhere((g) => g.name == 'Boots');
    expect(stove.personal, isFalse);
    expect(stove.bringerId, isEmpty);
    expect(boots.personal, isTrue);
    expect(boots.bringerId, me.id);

    // Applying again adds nothing.
    expect(t.applyTemplate(list, ownerId: me.id), 0);
  });

  test('personal items without an owner are skipped', () {
    final t = trip(Camper(name: 'Sam'));
    final list = GearTemplate(
      name: 'x',
      items: [TemplateItem(name: 'Boots', personal: true)],
    );
    expect(t.applyTemplate(list, ownerId: null), 0);
  });

  test('old "brought by me, just for me" items become personal', () {
    final g = GearItem.fromJson({
      'id': 'g',
      'name': 'Chair',
      'bringerId': 'me',
      'forIds': ['me'],
    });
    expect(g.personal, isTrue);
    final shared = GearItem.fromJson({
      'id': 'h',
      'name': 'Stove',
      'bringerId': 'me',
      'forIds': <String>[],
    });
    expect(shared.personal, isFalse);
  });

  test('deleting a camper removes their personal list', () {
    final me = Camper(name: 'Me', isMe: true);
    final t = trip(me)
      ..gear.addAll([
        GearItem.personalFor(me.id, name: 'Boots'),
        GearItem(name: 'Stove', bringerId: me.id),
      ]);
    t.forgetCamper(me.id);
    expect(t.gear.map((g) => g.name), ['Stove']);
    expect(t.gear.single.bringerId, isEmpty);
  });

  testWidgets('gear tab switches between group, mine and all', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final (app, _, _) = await makeTestApp();
    await tester.pumpWidget(app);
    await tester.tap(find.text('Big Sur Weekend'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gear').last);
    await tester.pumpAndSettle();

    expect(find.text('Group gear'), findsOneWidget);
    expect(find.text('Hiking boots'), findsNothing);

    await tester.tap(find.text('Mine'));
    await tester.pumpAndSettle();
    expect(find.text('My packing list'), findsOneWidget);
    expect(find.text('Hiking boots'), findsOneWidget);
    expect(find.text('Pop-up canopy'), findsNothing);
  });

  testWidgets('local sign in and sign out', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final (app, _, auth) = await makeTestApp();
    await tester.pumpWidget(app);

    await tester.tap(find.byTooltip('Account & settings'));
    await tester.pumpAndSettle();
    expect(find.text('You\'re not signed in'), findsOneWidget);

    await tester.tap(find.text('Sign in with email'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Wes Camper');
    await tester.enterText(find.byType(TextFormField).at(1), 'wes@example.com');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();
    expect(auth.currentUser?.displayName, 'Wes Camper');
    expect(find.text('wes@example.com'), findsOneWidget);

    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Sign out'));
    await tester.pumpAndSettle();
    expect(auth.currentUser, isNull);
  });

  testWidgets('crew profile sections collapse', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final (app, _, _) = await makeTestApp();
    await tester.pumpWidget(app);
    await tester.tap(find.text('Big Sur Weekend'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Crew').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Jordan Lee'));
    await tester.pumpAndSettle();

    expect(find.text('Groceries'), findsOneWidget);
    await tester.tap(find.text('Paid for'));
    await tester.pumpAndSettle();
    expect(find.text('Groceries'), findsNothing);
  });
}
