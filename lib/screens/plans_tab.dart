import 'package:flutter/material.dart';

import '../models.dart';
import '../util.dart';
import '../widgets/common.dart';
import '../widgets/form_sheet.dart';

class PlansTab extends StatelessWidget {
  const PlansTab({super.key, required this.trip});

  final Trip trip;

  List<String> get _dayOptions => [
    for (var d = 0; d < trip.dayCount; d++)
      'Day ${d + 1} · ${fmtDayLabel(trip.dateForDay(d))}',
  ];

  /// Sort key that understands times like "8:30 AM"; untimed items go last.
  static int _minutes(String t) {
    final m = RegExp(
      r'(\d{1,2})(?::(\d{2}))?\s*([ap]m)?',
      caseSensitive: false,
    ).firstMatch(t);
    if (m == null) return 24 * 60;
    var h = int.parse(m[1]!) % 12;
    final min = int.tryParse(m[2] ?? '') ?? 0;
    final pm = (m[3] ?? '').toLowerCase() == 'pm';
    if (m[3] == null) h = int.parse(m[1]!);
    return (pm ? h + 12 : h) * 60 + min;
  }

  Future<void> _edit(BuildContext context, [Activity? a, int? day]) async {
    final store = StoreScope.of(context);
    final days = _dayOptions;
    final v = await showFormSheet(
      context,
      title: a == null ? 'Add activity' : 'Edit activity',
      onDelete: a == null
          ? null
          : () => store.update(() => trip.activities.remove(a)),
      fields: [
        FieldSpec(
          'title',
          'What',
          initial: a?.title ?? '',
          hint: 'Hike to the falls',
          required: true,
          icon: Icons.flag_outlined,
        ),
        FieldSpec(
          'kind',
          'Type',
          initial: a?.kind ?? 'Hike',
          options: activityKinds,
        ),
        FieldSpec(
          'day',
          'Day',
          initial: days[(a?.day ?? day ?? 0).clamp(0, days.length - 1)],
          options: days,
        ),
        FieldSpec(
          'time',
          'Time',
          initial: a?.time ?? '',
          hint: '9:00 AM',
          icon: Icons.schedule,
        ),
        FieldSpec(
          'location',
          'Where',
          initial: a?.location ?? '',
          hint: 'Trailhead, town, beach…',
          icon: Icons.place_outlined,
        ),
        FieldSpec(
          'distance',
          'Distance / duration',
          initial: a?.distance ?? '',
          hint: '3.2 mi · 2 hrs',
          icon: Icons.straighten,
        ),
        FieldSpec('notes', 'Notes', initial: a?.notes ?? '', maxLines: 3),
      ],
    );
    if (v == null) return;
    final d = days.indexOf(v['day']!);
    store.update(() {
      if (a == null) {
        trip.activities.add(
          Activity(
            day: d,
            title: v['title']!,
            kind: v['kind']!,
            time: v['time']!,
            location: v['location']!,
            distance: v['distance']!,
            notes: v['notes']!,
          ),
        );
      } else {
        a
          ..title = v['title']!
          ..kind = v['kind']!
          ..day = d
          ..time = v['time']!
          ..location = v['location']!
          ..distance = v['distance']!
          ..notes = v['notes']!;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    StoreScope.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        heroTag: 'plan-fab',
        tooltip: 'Add activity',
        onPressed: () => _edit(context),
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
        children: [
          for (var d = 0; d < trip.dayCount; d++) ...[
            DayHeader(day: d, label: fmtDayLabel(trip.dateForDay(d))),
            ...() {
              final items = trip.activities.where((a) => a.day == d).toList()
                ..sort((x, y) => _minutes(x.time).compareTo(_minutes(y.time)));
              if (items.isEmpty) {
                return [
                  OutlinedButton.icon(
                    onPressed: () => _edit(context, null, d),
                    icon: const Icon(Icons.add),
                    label: const Text('Plan something'),
                  ),
                ];
              }
              return [
                for (var i = 0; i < items.length; i++)
                  _TimelineItem(
                    activity: items[i],
                    isLast: i == items.length - 1,
                    onTap: () => _edit(context, items[i]),
                  ),
              ];
            }(),
          ],
          if (trip.activities.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Text(
                'Plan hikes, day trips, and camp activities for each day.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.activity,
    required this.isLast,
    required this.onTap,
  });

  final Activity activity;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final a = activity;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 40,
            child: Column(
              children: [
                GestureDetector(
                  onTap: () => store.update(() => a.done = !a.done),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: a.done
                        ? scheme.primary
                        : scheme.primaryContainer,
                    foregroundColor: a.done
                        ? scheme.onPrimary
                        : scheme.onPrimaryContainer,
                    child: Icon(
                      a.done ? Icons.check : activityIcon(a.kind),
                      size: 20,
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: scheme.outlineVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onTap,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (a.time.isNotEmpty)
                              Text(
                                a.time,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: scheme.tertiary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            if (a.time.isNotEmpty) const SizedBox(width: 8),
                            Text(
                              a.kind.toUpperCase(),
                              style: theme.textTheme.labelSmall?.copyWith(
                                letterSpacing: 1,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          a.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            decoration: a.done
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        if (a.location.isNotEmpty)
                          _Meta(Icons.place_outlined, a.location),
                        if (a.distance.isNotEmpty)
                          _Meta(Icons.straighten, a.distance),
                        if (a.notes.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            a.notes,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
