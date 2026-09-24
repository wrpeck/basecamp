import 'package:flutter/material.dart';

import '../models.dart';
import '../util.dart';
import '../widgets/common.dart';
import '../widgets/form_sheet.dart';
import 'meals_tab.dart' show dayOptions;

/// One row on the day timeline: either an activity or a travel milestone.
class _Entry {
  _Entry.activity(Activity this.activity)
    : time = activity.time,
      title = activity.title,
      travel = false;
  _Entry.travel(this.time, this.title) : activity = null, travel = true;

  final Activity? activity;
  final int? time;
  final String title;
  final bool travel;
}

class PlansTab extends StatelessWidget {
  const PlansTab({super.key, required this.trip});

  final Trip trip;

  Future<void> _edit(BuildContext context, [Activity? a, int? day]) async {
    final store = StoreScope.of(context);
    final v = await showFormSheet(
      context,
      title: a == null ? 'Add activity' : 'Edit activity',
      onDelete: a == null
          ? null
          : () => store.update(() => trip.activities.remove(a)),
      fields: [
        FieldSpec.text(
          'title',
          'What',
          initial: a?.title ?? '',
          hint: 'Hike to the falls',
          required: true,
          icon: Icons.flag_outlined,
        ),
        FieldSpec.choice(
          'kind',
          'Type',
          options: plainOptions(activityKinds),
          initial: a?.kind ?? 'Hike',
        ),
        FieldSpec.choice(
          'day',
          'Day',
          options: dayOptions(trip),
          initial: '${(a?.day ?? day ?? 0).clamp(0, trip.dayCount - 1)}',
        ),
        FieldSpec.time('time', 'Time', initial: a?.time),
        FieldSpec.text(
          'location',
          'Where',
          initial: a?.location ?? '',
          hint: 'Trailhead, town, beach…',
          icon: Icons.place_outlined,
        ),
        FieldSpec.text(
          'distance',
          'Distance / duration',
          initial: a?.distance ?? '',
          hint: '3.2 mi · 2 hrs',
          icon: Icons.straighten,
        ),
        FieldSpec.text('notes', 'Notes', initial: a?.notes ?? '', maxLines: 3),
      ],
    );
    if (v == null) return;
    store.update(() {
      final target = a ?? Activity(day: 0, title: '');
      target
        ..title = v.str('title')
        ..kind = v.str('kind')
        ..day = int.parse(v.str('day'))
        ..time = v.time('time')
        ..location = v.str('location')
        ..distance = v.str('distance')
        ..notes = v.str('notes');
      if (a == null) trip.activities.add(target);
    });
  }

  List<_Entry> _entriesFor(int day) {
    final last = trip.dayCount - 1;
    final entries = [
      for (final a in trip.activities.where((a) => a.day == day))
        _Entry.activity(a),
      if (day == 0 && trip.leaveHomeBy != null)
        _Entry.travel(trip.leaveHomeBy, 'Leave home'),
      if (day == 0 && trip.arriveCampBy != null)
        _Entry.travel(trip.arriveCampBy, 'Arrive at camp'),
      if (day == last && trip.leaveCampBy != null)
        _Entry.travel(trip.leaveCampBy, 'Leave camp'),
      if (day == last && trip.arriveHomeBy != null)
        _Entry.travel(trip.arriveHomeBy, 'Arrive home'),
    ];
    // Untimed activities go last.
    entries.sort((x, y) => (x.time ?? 24 * 60).compareTo(y.time ?? 24 * 60));
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    StoreScope.of(context);
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
              final items = _entriesFor(d);
              return [
                for (var i = 0; i < items.length; i++)
                  _TimelineItem(
                    entry: items[i],
                    isLast: i == items.length - 1,
                    onTap: items[i].activity == null
                        ? null
                        : () => _edit(context, items[i].activity),
                  ),
                if (!items.any((e) => !e.travel))
                  Padding(
                    padding: EdgeInsets.only(left: items.isEmpty ? 0 : 50),
                    child: OutlinedButton.icon(
                      onPressed: () => _edit(context, null, d),
                      icon: const Icon(Icons.add),
                      label: const Text('Plan something'),
                    ),
                  ),
              ];
            }(),
          ],
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.entry,
    required this.isLast,
    required this.onTap,
  });

  final _Entry entry;
  final bool isLast;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final a = entry.activity;
    final done = a?.done ?? false;

    final icon = entry.travel
        ? Icons.directions_car_filled_outlined
        : done
        ? Icons.check
        : activityIcon(a!.kind);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 40,
            child: Column(
              children: [
                GestureDetector(
                  onTap: a == null
                      ? null
                      : () => store.update(() => a.done = !a.done),
                  child: CircleAvatar(
                    radius: entry.travel ? 14 : 18,
                    backgroundColor: entry.travel
                        ? scheme.tertiaryContainer
                        : done
                        ? scheme.primary
                        : scheme.primaryContainer,
                    foregroundColor: entry.travel
                        ? scheme.onTertiaryContainer
                        : done
                        ? scheme.onPrimary
                        : scheme.onPrimaryContainer,
                    child: Icon(icon, size: entry.travel ? 16 : 20),
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
              child: entry.travel
                  ? Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: '${entry.title} by '),
                            TextSpan(
                              text: fmtTime(entry.time!),
                              style: TextStyle(
                                color: scheme.tertiary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        style: theme.textTheme.bodyMedium,
                      ),
                    )
                  : Card(
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
                                  if (a!.time != null) ...[
                                    Text(
                                      fmtTime(a.time!),
                                      style: theme.textTheme.labelLarge
                                          ?.copyWith(
                                            color: scheme.tertiary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
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
                                  decoration: done
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
