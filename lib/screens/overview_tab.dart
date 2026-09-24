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

    Future<void> editDates() async {
      final range = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
        initialDateRange: DateTimeRange(
          start: trip.startDate,
          end: trip.endDate,
        ),
        helpText: 'Trip dates',
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

    Future<void> editCampsite() async {
      final v = await showFormSheet(
        context,
        title: 'Campsite',
        fields: [
          FieldSpec(
            'campground',
            'Campground',
            initial: trip.campground,
            icon: Icons.forest_outlined,
          ),
          FieldSpec(
            'site',
            'Site / loop',
            initial: trip.siteNumber,
            icon: Icons.tag,
          ),
          FieldSpec(
            'address',
            'Address',
            initial: trip.address,
            icon: Icons.place_outlined,
          ),
          FieldSpec(
            'checkIn',
            'Check-in',
            initial: trip.checkIn,
            hint: '2:00 PM',
            icon: Icons.login,
          ),
          FieldSpec(
            'checkOut',
            'Check-out',
            initial: trip.checkOut,
            hint: '12:00 PM',
            icon: Icons.logout,
          ),
          FieldSpec(
            'res',
            'Reservation #',
            initial: trip.reservationNumber,
            icon: Icons.confirmation_number_outlined,
          ),
          FieldSpec(
            'ranger',
            'Ranger station phone',
            initial: trip.rangerPhone,
            keyboardType: TextInputType.phone,
            icon: Icons.phone_outlined,
          ),
        ],
      );
      if (v == null) return;
      store.update(() {
        trip.campground = v['campground']!;
        trip.siteNumber = v['site']!;
        trip.address = v['address']!;
        trip.checkIn = v['checkIn']!;
        trip.checkOut = v['checkOut']!;
        trip.reservationNumber = v['res']!;
        trip.rangerPhone = v['ranger']!;
      });
    }

    Future<void> editLocation() async {
      final v = await showFormSheet(
        context,
        title: 'GPS coordinates',
        fields: [
          FieldSpec(
            'lat',
            'Latitude',
            initial: trip.latitude?.toString() ?? '',
            hint: '36.2508',
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
          ),
          FieldSpec(
            'lng',
            'Longitude',
            initial: trip.longitude?.toString() ?? '',
            hint: '-121.7847',
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
          ),
        ],
      );
      if (v == null) return;
      final lat = double.tryParse(v['lat']!);
      final lng = double.tryParse(v['lng']!);
      store.update(() {
        trip.latitude = (lat != null && lat.abs() <= 90) ? lat : null;
        trip.longitude = (lng != null && lng.abs() <= 180) ? lng : null;
      });
    }

    Future<void> editText(
      String title,
      String initial,
      void Function(String) apply,
    ) async {
      final v = await showFormSheet(
        context,
        title: title,
        fields: [FieldSpec('text', title, initial: initial, maxLines: 5)],
      );
      if (v != null) store.update(() => apply(v['text']!));
    }

    Future<void> editCost([CostItem? item]) async {
      final v = await showFormSheet(
        context,
        title: item == null ? 'Add cost' : 'Edit cost',
        onDelete: item == null
            ? null
            : () => store.update(() => trip.costs.remove(item)),
        fields: [
          FieldSpec(
            'label',
            'What for',
            initial: item?.label ?? '',
            hint: 'Campsite fee',
            required: true,
          ),
          FieldSpec(
            'amount',
            'Amount (\$)',
            initial: item == null ? '' : item.amount.toStringAsFixed(2),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            required: true,
          ),
          FieldSpec(
            'paidBy',
            'Paid by',
            initial: item?.paidBy ?? '',
            options: whoOptions(trip.campers.map((c) => firstName(c.name))),
          ),
        ],
      );
      if (v == null) return;
      final amount =
          double.tryParse(v['amount']!.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0;
      final paidBy = v['paidBy'] == 'Anyone' ? '' : v['paidBy']!;
      store.update(() {
        if (item == null) {
          trip.costs.add(
            CostItem(label: v['label']!, amount: amount, paidBy: paidBy),
          );
        } else {
          item
            ..label = v['label']!
            ..amount = amount
            ..paidBy = paidBy;
        }
      });
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
              label: 'Per person',
              value: fmtMoney(trip.costPerPerson).split('.').first,
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
                    child: InfoRow(label: 'Check-in', value: trip.checkIn),
                  ),
                  Expanded(
                    child: InfoRow(label: 'Check-out', value: trip.checkOut),
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
              InfoRow(
                label: 'Ranger station',
                value: trip.rangerPhone,
                actions: [
                  IconButton(
                    tooltip: 'Call ranger station',
                    icon: const Icon(Icons.call_outlined, size: 20),
                    onPressed: () => callNumber(context, trip.rangerPhone),
                  ),
                ],
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
              : const InfoRow(
                  label: 'Coordinates',
                  value: '',
                  placeholder: 'Add latitude & longitude',
                ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: 'Parking',
          icon: Icons.local_parking,
          onEdit: () =>
              editText('Parking', trip.parking, (v) => trip.parking = v),
          child: InfoRow(
            label: 'Details',
            value: trip.parking,
            placeholder: 'Vehicle limits, overflow lots, passes…',
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: 'Costs',
          icon: Icons.payments_outlined,
          trailing: IconButton(
            tooltip: 'Add cost',
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => editCost(),
          ),
          child: Column(
            children: [
              for (final c in trip.costs)
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => editCost(c),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(c.label, style: theme.textTheme.bodyLarge),
                              if (c.paidBy.isNotEmpty)
                                Text(
                                  'Paid by ${c.paidBy}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
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
                const InfoRow(
                  label: 'Nothing yet',
                  value: '',
                  placeholder: 'Tap + to track fees, food and fuel',
                ),
              const Divider(height: 20),
              Row(
                children: [
                  Text('Total', style: theme.textTheme.titleMedium),
                  const Spacer(),
                  Text(
                    fmtMoney(trip.totalCost),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              if (trip.campers.length > 1) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Split ${trip.campers.length} ways',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${fmtMoney(trip.costPerPerson)} each',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.tertiary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: 'Notes',
          icon: Icons.sticky_note_2_outlined,
          onEdit: () => editText('Notes', trip.notes, (v) => trip.notes = v),
          child: InfoRow(
            label: 'Rules, reminders, anything else',
            value: trip.notes,
            placeholder: 'Fire rules, quiet hours, cell coverage…',
          ),
        ),
      ],
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
