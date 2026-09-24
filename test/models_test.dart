import 'package:basecamp/models.dart';
import 'package:basecamp/util.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Trip tripWith(List<Camper> campers, List<CostItem> costs) => Trip(
    name: 't',
    startDate: DateTime(2026, 10, 1),
    endDate: DateTime(2026, 10, 3),
    campers: campers,
    costs: costs,
  );

  group('costs', () {
    final a = Camper(name: 'Ann'), b = Camper(name: 'Ben');
    final c = Camper(name: 'Cy');

    test('shared cost split with everyone', () {
      final trip = tripWith(
        [a, b, c],
        [
          CostItem(
            label: 'site',
            amount: 90,
            payerIds: [a.id],
            owedByEveryone: true,
          ),
        ],
      );
      final debts = trip.debts();
      expect(debts, hasLength(2));
      expect(debts.every((d) => d.to == a.id && d.amount == 30), isTrue);
      expect(trip.costFor(a.id), 30);
      expect(trip.paidBy(a.id), 90);
    });

    test('personal expense counts toward cost but creates no debt', () {
      final trip = tripWith(
        [a, b],
        [
          CostItem(label: 'snacks', amount: 12, payerIds: [b.id]),
        ],
      );
      expect(trip.debts(), isEmpty);
      expect(trip.costFor(b.id), 12);
      expect(trip.costFor(a.id), 0);
    });

    test('multiple payers and specific owers net out', () {
      final trip = tripWith(
        [a, b, c],
        [
          // Ann and Ben each paid 30; Ben and Cy share it (30 each).
          CostItem(
            label: 'x',
            amount: 60,
            payerIds: [a.id, b.id],
            owedIds: [b.id, c.id],
          ),
          // Ben paid 10 for Ann alone.
          CostItem(label: 'y', amount: 10, payerIds: [b.id], owedIds: [a.id]),
        ],
      );
      double owed(Camper from, Camper to) => trip
          .debts()
          .where((d) => d.from == from.id && d.to == to.id)
          .fold(0.0, (s, d) => s + d.amount);
      // Ben owes Ann 15, Ann owes Ben 10 → Ben owes Ann 5.
      expect(owed(b, a), closeTo(5, 1e-9));
      expect(owed(a, b), 0);
      expect(owed(c, a), closeTo(15, 1e-9));
      expect(owed(c, b), closeTo(15, 1e-9));
    });

    test('removing a camper drops their references', () {
      final trip = tripWith(
        [a, b],
        [
          CostItem(label: 'x', amount: 10, payerIds: [a.id], owedIds: [b.id]),
        ],
      );
      trip.forgetCamper(b.id);
      expect(trip.costs.single.owedIds, isEmpty);
      expect(trip.debts(), isEmpty);
    });
  });

  test('v1 data migrates names to ids and adds Me', () {
    final trip = Trip.fromJson({
      'id': 't1',
      'name': 'Old',
      'startDate': '2026-10-01T00:00:00.000',
      'endDate': '2026-10-02T00:00:00.000',
      'checkIn': '2:00 PM',
      'parking': 'Lot B',
      'campers': [
        {'id': 'c1', 'name': 'Alex Rivera'},
      ],
      'costs': [
        {'id': 'k', 'label': 'Site', 'amount': 50, 'paidBy': 'Alex'},
      ],
      'meals': [
        {
          'id': 'm',
          'day': 0,
          'type': 'Dinner',
          'title': 'Chili',
          'cook': 'Alex',
        },
      ],
      'gear': [
        {'id': 'g', 'name': 'Tent', 'bringer': 'Alex'},
      ],
      'activities': [
        {
          'id': 'a',
          'day': 0,
          'title': 'Swim',
          'kind': 'Water',
          'time': '8:30 AM',
        },
      ],
    });
    expect(trip.me, isNotNull);
    expect(trip.checkIn, 14 * 60);
    expect(trip.parkingNotes, 'Lot B');
    expect(trip.costs.single.payerIds, ['c1']);
    expect(trip.costs.single.owedByEveryone, isTrue);
    expect(trip.meals.single.cookIds, ['c1']);
    expect(trip.gear.single.bringerId, 'c1');
    expect(trip.activities.single.kind, 'Water Sports');
    expect(trip.activities.single.time, 8 * 60 + 30);

    // Round-trips as v2 without re-adding Me after it's deleted.
    trip.forgetCamper(trip.me!.id);
    final again = Trip.fromJson(trip.toJson());
    expect(again.me, isNull);
  });

  group('parseCoords', () {
    test('decimal pair', () {
      expect(parseCoords('36.2508, -121.7847'), (36.2508, -121.7847));
      expect(parseCoords('36.2508 -121.7847'), (36.2508, -121.7847));
      expect(parseCoords('36.2508,-121.7847'), (36.2508, -121.7847));
    });
    test('hemispheres', () {
      expect(parseCoords('36.2508° N, 121.7847° W'), (36.2508, -121.7847));
      expect(parseCoords('36.25 S 121.78 E'), (-36.25, 121.78));
    });
    test('degrees minutes seconds', () {
      final r = parseCoords('36°15\'03"N 121°47\'05"W')!;
      expect(r.$1, closeTo(36.2508, 1e-3));
      expect(r.$2, closeTo(-121.7847, 1e-3));
    });
    test('rejects junk', () {
      expect(parseCoords('hello'), isNull);
      expect(parseCoords('36.25'), isNull);
      expect(parseCoords('200, 10'), isNull);
    });
  });
}
