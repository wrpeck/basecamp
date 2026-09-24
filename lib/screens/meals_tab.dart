import 'package:flutter/material.dart';

import '../models.dart';
import '../util.dart';
import '../widgets/common.dart';
import '../widgets/form_sheet.dart';

class MealsTab extends StatefulWidget {
  const MealsTab({super.key, required this.trip});

  final Trip trip;

  @override
  State<MealsTab> createState() => _MealsTabState();
}

class _MealsTabState extends State<MealsTab> {
  bool _shopping = false;
  final Set<String> _gotIt = {};

  Trip get trip => widget.trip;

  List<String> get _dayOptions => [
    for (var d = 0; d < trip.dayCount; d++)
      'Day ${d + 1} · ${fmtDayLabel(trip.dateForDay(d))}',
  ];

  Future<void> _edit([Meal? meal, int? day, String? type]) async {
    final store = StoreScope.of(context);
    final days = _dayOptions;
    final v = await showFormSheet(
      context,
      title: meal == null ? 'Add meal' : 'Edit meal',
      onDelete: meal == null
          ? null
          : () => store.update(() => trip.meals.remove(meal)),
      fields: [
        FieldSpec(
          'title',
          'Meal',
          initial: meal?.title ?? '',
          hint: 'Campfire chili',
          required: true,
          icon: Icons.restaurant_menu,
        ),
        FieldSpec(
          'day',
          'Day',
          initial: days[(meal?.day ?? day ?? 0).clamp(0, days.length - 1)],
          options: days,
        ),
        FieldSpec(
          'type',
          'Type',
          initial: meal?.type ?? type ?? 'Dinner',
          options: mealTypes,
        ),
        FieldSpec(
          'cook',
          'Cook',
          initial: meal?.cook ?? '',
          options: whoOptions(trip.campers.map((c) => firstName(c.name))),
        ),
        FieldSpec(
          'ingredients',
          'Ingredients',
          initial: meal?.ingredients.join(', ') ?? '',
          hint: 'Comma separated: beans, onions, cheese',
          maxLines: 3,
        ),
        FieldSpec('notes', 'Notes', initial: meal?.notes ?? '', maxLines: 2),
      ],
    );
    if (v == null) return;
    final ingredients = v['ingredients']!
        .split(RegExp(r'[,\n]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final dayIndex = days.indexOf(v['day']!);
    final cook = v['cook'] == 'Anyone' ? '' : v['cook']!;
    store.update(() {
      if (meal == null) {
        trip.meals.add(
          Meal(
            day: dayIndex,
            type: v['type']!,
            title: v['title']!,
            ingredients: ingredients,
            cook: cook,
            notes: v['notes']!,
          ),
        );
      } else {
        meal
          ..title = v['title']!
          ..day = dayIndex
          ..type = v['type']!
          ..cook = cook
          ..ingredients = ingredients
          ..notes = v['notes']!;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    StoreScope.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: _shopping
          ? null
          : FloatingActionButton(
              heroTag: 'meal-fab',
              tooltip: 'Add meal',
              onPressed: () => _edit(),
              child: const Icon(Icons.add),
            ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: SegmentedButton<bool>(
              style: const ButtonStyle(
                visualDensity: VisualDensity.comfortable,
              ),
              segments: const [
                ButtonSegment(
                  value: false,
                  icon: Icon(Icons.calendar_view_day_outlined),
                  label: Text('Meal plan'),
                ),
                ButtonSegment(
                  value: true,
                  icon: Icon(Icons.shopping_cart_outlined),
                  label: Text('Shopping list'),
                ),
              ],
              selected: {_shopping},
              onSelectionChanged: (s) => setState(() => _shopping = s.first),
            ),
          ),
          Expanded(child: _shopping ? _shoppingList() : _plan()),
        ],
      ),
    );
  }

  Widget _plan() {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
      children: [
        for (var d = 0; d < trip.dayCount; d++) ...[
          DayHeader(day: d, label: fmtDayLabel(trip.dateForDay(d))),
          ...() {
            final meals = trip.meals.where((m) => m.day == d).toList()
              ..sort(
                (a, b) => mealTypes
                    .indexOf(a.type)
                    .compareTo(mealTypes.indexOf(b.type)),
              );
            final missing = mealTypes
                .take(3)
                .where((t) => !meals.any((m) => m.type == t))
                .toList();
            return [
              for (final m in meals) ...[
                _MealCard(meal: m, onTap: () => _edit(m)),
                const SizedBox(height: 8),
              ],
              if (missing.isNotEmpty)
                Wrap(
                  spacing: 8,
                  children: [
                    for (final t in missing)
                      ActionChip(
                        avatar: Icon(
                          Icons.add,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                        label: Text(t),
                        onPressed: () => _edit(null, d, t),
                      ),
                  ],
                ),
            ];
          }(),
        ],
      ],
    );
  }

  Widget _shoppingList() {
    final theme = Theme.of(context);
    final counts = <String, int>{};
    final display = <String, String>{};
    for (final m in trip.meals) {
      for (final i in m.ingredients) {
        final k = i.toLowerCase();
        counts[k] = (counts[k] ?? 0) + 1;
        display.putIfAbsent(k, () => i);
      }
    }
    final keys = counts.keys.toList()
      ..sort((a, b) {
        final ga = _gotIt.contains(a), gb = _gotIt.contains(b);
        if (ga != gb) return ga ? 1 : -1;
        return a.compareTo(b);
      });
    if (keys.isEmpty) {
      return const EmptyHint(
        icon: Icons.shopping_basket_outlined,
        title: 'No ingredients yet',
        message: 'Add ingredients to your meals and they\'ll show up here.',
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
          child: Text(
            '${_gotIt.length} of ${keys.length} picked up · built from your meal plan',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Card(
          child: Column(
            children: [
              for (final k in keys)
                CheckboxListTile(
                  value: _gotIt.contains(k),
                  onChanged: (v) => setState(
                    () => v == true ? _gotIt.add(k) : _gotIt.remove(k),
                  ),
                  title: Text(
                    display[k]!,
                    style: _gotIt.contains(k)
                        ? TextStyle(
                            decoration: TextDecoration.lineThrough,
                            color: theme.colorScheme.outline,
                          )
                        : null,
                  ),
                  secondary: counts[k]! > 1
                      ? Text('×${counts[k]}', style: theme.textTheme.labelLarge)
                      : null,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MealCard extends StatelessWidget {
  const _MealCard({required this.meal, required this.onTap});

  final Meal meal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: scheme.tertiaryContainer,
                foregroundColor: scheme.onTertiaryContainer,
                child: Icon(mealIcon(meal.type)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meal.type.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        letterSpacing: 1,
                        color: scheme.tertiary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      meal.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (meal.cook.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          children: [
                            Icon(
                              Icons.outdoor_grill_outlined,
                              size: 14,
                              color: scheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(meal.cook, style: theme.textTheme.bodySmall),
                          ],
                        ),
                      ),
                    if (meal.ingredients.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        meal.ingredients.join(' · '),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (meal.notes.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        meal.notes,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
