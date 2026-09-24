import 'package:flutter/material.dart';

import '../models.dart';
import '../util.dart';
import '../widgets/common.dart';
import '../widgets/form_sheet.dart';
import 'home_screen.dart';

class OverviewTab extends StatelessWidget {
  const OverviewTab({super.key, required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final theme = Theme.of(context);
    final days = trip.daysUntil(DateTime.now());
    final me = trip.me;

    Future<void> editDates() async {
      final range = await pickTripDates(
        context,
        initial: DateTimeRange(start: trip.startDate, end: trip.endDate),
      );
      if (range == null) return;
      store.update(() {
        trip.startDate = range.start;
        trip.endDate = range.end;
        // Keep day-indexed plans inside the new range.
        final last = trip.dayCount - 1;
        for (final m in trip.meals) {
          if (m.day > last) m.day = last;
        }
        for (final a in trip.activities) {
          if (a.day > last) a.day = last;
        }
      });
    }

    Future<void> editTravel() async {
      final v = await showFormSheet(
        context,
        title: 'Travel times',
        fields: [
          FieldSpec.time(
            'leaveHome',
            'Day 1 · Leave home by',
            initial: trip.leaveHomeBy,
            icon: Icons.home_outlined,
          ),
          FieldSpec.time(
            'arriveCamp',
            'Day 1 · Arrive at camp by',
            initial: trip.arriveCampBy,
            icon: Icons.flag_outlined,
          ),
          FieldSpec.time(
            'leaveCamp',
            'Day ${trip.dayCount} · Leave camp by',
            initial: trip.leaveCampBy,
            icon: Icons.logout,
          ),
          FieldSpec.time(
            'arriveHome',
            'Day ${trip.dayCount} · Arrive home by',
            initial: trip.arriveHomeBy,
            icon: Icons.home_outlined,
          ),
        ],
      );
      if (v == null) return;
      store.update(() {
        trip.leaveHomeBy = v.time('leaveHome');
        trip.arriveCampBy = v.time('arriveCamp');
        trip.leaveCampBy = v.time('leaveCamp');
        trip.arriveHomeBy = v.time('arriveHome');
      });
    }

    Future<void> editCampsite() async {
      final v = await showFormSheet(
        context,
        title: 'Campsite',
        fields: [
          FieldSpec.text(
            'campground',
            'Campground',
            initial: trip.campground,
            icon: Icons.forest_outlined,
          ),
          FieldSpec.text(
            'site',
            'Site / loop',
            initial: trip.siteNumber,
            icon: Icons.tag,
          ),
          FieldSpec.text(
            'address',
            'Address',
            initial: trip.address,
            icon: Icons.place_outlined,
          ),
          FieldSpec.time(
            'checkIn',
            'Check-in',
            initial: trip.checkIn,
            icon: Icons.login,
          ),
          FieldSpec.time(
            'checkOut',
            'Check-out',
            initial: trip.checkOut,
            icon: Icons.logout,
          ),
          FieldSpec.text(
            'res',
            'Reservation #',
            initial: trip.reservationNumber,
            icon: Icons.confirmation_number_outlined,
          ),
          FieldSpec.choice(
            'water',
            'Water',
            options: plainOptions(waterOptions),
            initial: trip.water,
            icon: Icons.water_drop_outlined,
          ),
          FieldSpec.choice(
            'bathrooms',
            'Bathrooms',
            options: plainOptions(bathroomOptions),
            initial: trip.bathrooms,
            icon: Icons.wc_outlined,
          ),
          FieldSpec.toggle(
            'cell',
            'Cell service',
            initial: trip.cellService,
            icon: Icons.signal_cellular_alt,
          ),
        ],
      );
      if (v == null) return;
      store.update(() {
        trip.campground = v.str('campground');
        trip.siteNumber = v.str('site');
        trip.address = v.str('address');
        trip.checkIn = v.time('checkIn');
        trip.checkOut = v.time('checkOut');
        trip.reservationNumber = v.str('res');
        trip.water = v.str('water');
        trip.bathrooms = v.str('bathrooms');
        trip.cellService = v.flag('cell');
      });
    }

    Future<void> editLocation() async {
      final v = await showFormSheet(
        context,
        title: 'GPS coordinates',
        fields: [
          FieldSpec.text(
            'coords',
            'Latitude, longitude',
            initial: trip.hasCoordinates
                ? '${trip.latitude}, ${trip.longitude}'
                : '',
            hint: '36.2508, -121.7847',
            keyboardType: TextInputType.text,
            icon: Icons.my_location,
            validator: (s) => parseCoords(s) == null
                ? 'Try "36.2508, -121.7847" or "36.2508 N, 121.7847 W"'
                : null,
          ),
        ],
      );
      if (v == null) return;
      final coords = parseCoords(v.str('coords'));
      store.update(() {
        trip.latitude = coords?.$1;
        trip.longitude = coords?.$2;
      });
    }

    Future<void> editParking() async {
      final v = await showFormSheet(
        context,
        title: 'Parking',
        fields: [
          FieldSpec.text(
            'vehicles',
            'Vehicles allowed at site',
            initial: trip.vehiclesAllowed?.toString() ?? '',
            keyboardType: TextInputType.number,
            icon: Icons.directions_car_outlined,
            validator: (s) =>
                int.tryParse(s) == null ? 'Enter a whole number' : null,
          ),
          FieldSpec.text(
            'cost',
            'Cost per vehicle (\$)',
            initial: trip.costPerVehicle?.toStringAsFixed(2) ?? '',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            icon: Icons.attach_money,
            validator: (s) => parseMoney(s) == null ? 'Enter an amount' : null,
          ),
          FieldSpec.text(
            'notes',
            'Notes',
            initial: trip.parkingNotes,
            hint: 'Overflow lots, passes, trailer rules…',
            maxLines: 4,
          ),
        ],
      );
      if (v == null) return;
      store.update(() {
        trip.vehiclesAllowed = int.tryParse(v.str('vehicles'));
        trip.costPerVehicle = parseMoney(v.str('cost'));
        trip.parkingNotes = v.str('notes');
      });
    }

    Future<void> editNotes() async {
      final v = await showFormSheet(
        context,
        title: 'Notes',
        fields: [
          FieldSpec.text('text', 'Notes', initial: trip.notes, maxLines: 6),
        ],
      );
      if (v != null) store.update(() => trip.notes = v.str('text'));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: TripBanner(trip: trip),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _StatTile(
              label: days > 0
                  ? 'Countdown'
                  : countdownLabel(days, trip.dayCount),
              value: days > 0 ? '$days' : '${trip.dayCount}d',
              caption: days > 0 ? 'days to go' : 'trip length',
            ),
            const SizedBox(width: 10),
            _StatTile(
              label: 'Packed',
              value: '${(trip.packedFraction * 100).round()}%',
              caption: '${trip.packedCount}/${trip.gear.length} items',
            ),
            const SizedBox(width: 10),
            _StatTile(
              label: me != null ? 'My cost' : 'Total cost',
              value: fmtMoney(me != null ? trip.costFor(me.id) : trip.totalCost)
                  .split('.')
                  .first,
              caption: '${trip.campers.length} campers',
            ),
          ],
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: 'Dates',
          icon: Icons.event_outlined,
          onEdit: editDates,
          child: Column(
            children: [
              InfoRow(
                label: 'When',
                value: fmtRange(trip.startDate, trip.endDate),
              ),
              InfoRow(
                label: 'Length',
                value:
                    '${trip.dayCount} days · ${trip.nights} night${trip.nights == 1 ? '' : 's'}',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: 'Travel',
          icon: Icons.directions_car_outlined,
          onEdit: editTravel,
          child: Column(
            children: [
              _TimePair(
                heading: 'Day 1 · ${fmtDayLabel(trip.startDate)}',
                leftLabel: 'Leave home by',
                left: trip.leaveHomeBy,
                rightLabel: 'Arrive at camp by',
                right: trip.arriveCampBy,
              ),
              const SizedBox(height: 8),
              _TimePair(
                heading: 'Day ${trip.dayCount} · ${fmtDayLabel(trip.endDate)}',
                leftLabel: 'Leave camp by',
                left: trip.leaveCampBy,
                rightLabel: 'Arrive home by',
                right: trip.arriveHomeBy,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: 'Campsite',
          icon: Icons.forest_outlined,
          onEdit: editCampsite,
          child: Column(
            children: [
              InfoRow(label: 'Campground', value: trip.campground),
              InfoRow(label: 'Site', value: trip.siteNumber),
              InfoRow(
                label: 'Address',
                value: trip.address,
                actions: [
                  IconButton(
                    tooltip: 'Copy address',
                    icon: const Icon(Icons.copy, size: 20),
                    onPressed: () => copyText(context, trip.address, 'Address'),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: InfoRow(
                      label: 'Check-in',
                      value: trip.checkIn == null ? '' : fmtTime(trip.checkIn!),
                    ),
                  ),
                  Expanded(
                    child: InfoRow(
                      label: 'Check-out',
                      value: trip.checkOut == null
                          ? ''
                          : fmtTime(trip.checkOut!),
                    ),
                  ),
                ],
              ),
              InfoRow(
                label: 'Reservation #',
                value: trip.reservationNumber,
                actions: [
                  IconButton(
                    tooltip: 'Copy reservation number',
                    icon: const Icon(Icons.copy, size: 20),
                    onPressed: () => copyText(
                      context,
                      trip.reservationNumber,
                      'Reservation #',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Amenity(
                      icon: Icons.water_drop_outlined,
                      label: trip.water == 'Unknown'
                          ? 'Water: unknown'
                          : trip.water,
                      good:
                          trip.water.startsWith('Potable') ||
                          trip.water.startsWith('Spigot'),
                    ),
                    _Amenity(
                      icon: Icons.wc_outlined,
                      label: trip.bathrooms == 'Unknown'
                          ? 'Bathrooms: unknown'
                          : trip.bathrooms == 'None'
                          ? 'No bathrooms'
                          : trip.bathrooms,
                      good: trip.bathrooms.startsWith('Flush'),
                    ),
                    _Amenity(
                      icon: trip.cellService
                          ? Icons.signal_cellular_alt
                          : Icons.signal_cellular_off_outlined,
                      label: trip.cellService
                          ? 'Cell service'
                          : 'No cell service',
                      good: trip.cellService,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: 'GPS location',
          icon: Icons.my_location,
          onEdit: editLocation,
          child: trip.hasCoordinates
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      fmtCoord(trip.latitude!, trip.longitude!),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${trip.latitude}, ${trip.longitude}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.tonalIcon(
                            onPressed: () => openMaps(
                              context,
                              trip.latitude!,
                              trip.longitude!,
                            ),
                            icon: const Icon(Icons.directions_outlined),
                            label: const Text('Directions'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => copyText(
                              context,
                              '${trip.latitude}, ${trip.longitude}',
                              'Coordinates',
                            ),
                            icon: const Icon(Icons.copy, size: 18),
                            label: const Text('Copy'),
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              : InkWell(
                  onTap: editLocation,
                  child: const InfoRow(
                    label: 'Coordinates',
                    value: '',
                    placeholder: 'Tap to add or paste coordinates',
                  ),
                ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: 'Parking',
          icon: Icons.local_parking,
          onEdit: editParking,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: InfoRow(
                      label: 'Vehicles allowed',
                      value: trip.vehiclesAllowed?.toString() ?? '',
                    ),
                  ),
                  Expanded(
                    child: InfoRow(
                      label: 'Cost per vehicle',
                      value: trip.costPerVehicle == null
                          ? ''
                          : trip.costPerVehicle == 0
                          ? 'Free'
                          : fmtMoney(trip.costPerVehicle!),
                    ),
                  ),
                ],
              ),
              InfoRow(
                label: 'Notes',
                value: trip.parkingNotes,
                placeholder: 'Overflow lots, passes, trailer rules…',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _CostsCard(trip: trip),
        const SizedBox(height: 12),
        SectionCard(
          title: 'Notes',
          icon: Icons.sticky_note_2_outlined,
          onEdit: editNotes,
          child: InfoRow(
            label: 'Rules, reminders, anything else',
            value: trip.notes,
            placeholder: 'Fire rules, quiet hours, what to download…',
          ),
        ),
      ],
    );
  }
}

/// Add or edit a cost. Shared with the crew summary screen.
Future<void> editCost(BuildContext context, Trip trip, [CostItem? item]) async {
  final store = StoreScope.of(context);
  final v = await showFormSheet(
    context,
    title: item == null ? 'Add cost' : 'Edit cost',
    onDelete: item == null
        ? null
        : () => store.update(() => trip.costs.remove(item)),
    fields: [
      FieldSpec.text(
        'label',
        'What for',
        initial: item?.label ?? '',
        hint: 'Campsite fee',
        required: true,
        icon: Icons.receipt_long_outlined,
      ),
      FieldSpec.text(
        'amount',
        'Amount (\$)',
        initial: item == null ? '' : item.amount.toStringAsFixed(2),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        required: true,
        icon: Icons.attach_money,
        validator: (s) => parseMoney(s) == null ? 'Enter an amount' : null,
      ),
      FieldSpec.multi(
        'paidBy',
        'Paid by',
        options: camperOptions(trip),
        initial: item?.payerIds ?? [if (trip.me != null) trip.me!.id],
        hint: 'Several payers split the amount evenly',
      ),
      FieldSpec.multi(
        'owed',
        'Owed by',
        options: camperOptions(trip),
        allLabel: 'Everyone',
        initial: item == null
            ? const [allValue]
            : item.owedByEveryone
            ? const [allValue]
            : item.owedIds,
        hint: 'Leave empty for a personal expense nobody owes',
      ),
    ],
  );
  if (v == null) return;
  final owed = v.list('owed');
  store.update(() {
    final target = item ?? CostItem(label: '', amount: 0);
    target
      ..label = v.str('label')
      ..amount = parseMoney(v.str('amount')) ?? 0
      ..payerIds = v.list('paidBy')
      ..owedByEveryone = owed.contains(allValue)
      ..owedIds = owed.where((id) => id != allValue).toList();
    if (item == null) trip.costs.add(target);
  });
}

class _CostsCard extends StatelessWidget {
  const _CostsCard({required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final debts = trip.debts();

    String split(CostItem c) {
      if (c.isPersonal) return 'Personal';
      if (c.owedByEveryone) return 'Split with everyone';
      return 'Split: ${namesOr(trip, c.owedIds, 'nobody')}';
    }

    return SectionCard(
      title: 'Costs',
      icon: Icons.payments_outlined,
      onHeaderTap: () => editCost(context, trip),
      trailing: IconButton(
        tooltip: 'Add cost',
        icon: const Icon(Icons.add_circle_outline),
        onPressed: () => editCost(context, trip),
      ),
      child: Column(
        children: [
          for (final c in trip.costs)
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => editCost(context, trip, c),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.label, style: theme.textTheme.bodyLarge),
                          Text(
                            [
                              if (c.payerIds.isNotEmpty)
                                'Paid by ${namesOr(trip, c.payerIds, '?')}',
                              split(c),
                            ].join(' · '),
                            style: muted,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      fmtMoney(c.amount),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (trip.costs.isEmpty)
            InkWell(
              onTap: () => editCost(context, trip),
              child: const InfoRow(
                label: 'Nothing yet',
                value: '',
                placeholder: 'Tap to track fees, food and fuel',
              ),
            ),
          const Divider(height: 20),
          Row(
            children: [
              Text('Trip total', style: theme.textTheme.titleMedium),
              const Spacer(),
              Text(
                fmtMoney(trip.totalCost),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          if (debts.isNotEmpty) ...[
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'SETTLE UP',
                style: theme.textTheme.labelSmall?.copyWith(
                  letterSpacing: 1,
                  color: theme.colorScheme.tertiary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 4),
            for (final d in debts)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        trip.camper(d.from)!.isMe
                            ? 'You owe ${who(trip, d.to)}'
                            : '${who(trip, d.from)} owes ${who(trip, d.to)}',
                      ),
                    ),
                    Text(
                      fmtMoney(d.amount),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _TimePair extends StatelessWidget {
  const _TimePair({
    required this.heading,
    required this.leftLabel,
    required this.left,
    required this.rightLabel,
    required this.right,
  });

  final String heading;
  final String leftLabel;
  final int? left;
  final String rightLabel;
  final int? right;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          heading,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        Row(
          children: [
            Expanded(
              child: InfoRow(
                label: leftLabel,
                value: left == null ? '' : fmtTime(left!),
              ),
            ),
            Expanded(
              child: InfoRow(
                label: rightLabel,
                value: right == null ? '' : fmtTime(right!),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Amenity extends StatelessWidget {
  const _Amenity({required this.icon, required this.label, required this.good});

  final IconData icon;
  final String label;
  final bool good;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: good ? scheme.primaryContainer : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: good ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: good
                    ? scheme.onPrimaryContainer
                    : scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.caption,
  });

  final String label;
  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              Text(
                caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
