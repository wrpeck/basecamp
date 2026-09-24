import 'package:flutter/material.dart';

import '../models.dart';
import '../util.dart';
import '../widgets/common.dart';
import '../widgets/form_sheet.dart';

class GearTab extends StatefulWidget {
  const GearTab({super.key, required this.trip});

  final Trip trip;

  @override
  State<GearTab> createState() => _GearTabState();
}

class _GearTabState extends State<GearTab> {
  bool _hidePacked = false;

  Trip get trip => widget.trip;

  Future<void> _edit([GearItem? item]) async {
    final store = StoreScope.of(context);
    final v = await showFormSheet(
      context,
      title: item == null ? 'Add item' : 'Edit item',
      onDelete: item == null
          ? null
          : () => store.update(() => trip.gear.remove(item)),
      fields: [
        FieldSpec(
          'name',
          'Item',
          initial: item?.name ?? '',
          hint: 'Headlamp',
          required: true,
          icon: Icons.backpack_outlined,
        ),
        FieldSpec(
          'category',
          'Category',
          initial: item?.category ?? 'Other',
          options: gearCategories,
        ),
        FieldSpec(
          'qty',
          'Quantity',
          initial: '${item?.quantity ?? 1}',
          keyboardType: TextInputType.number,
        ),
        FieldSpec(
          'bringer',
          'Who\'s bringing it',
          initial: item?.bringer ?? '',
          options: whoOptions(trip.campers.map((c) => firstName(c.name))),
        ),
      ],
    );
    if (v == null) return;
    final qty = (int.tryParse(v['qty']!) ?? 1).clamp(1, 999);
    final bringer = v['bringer'] == 'Anyone' ? '' : v['bringer']!;
    store.update(() {
      if (item == null) {
        trip.gear.add(
          GearItem(
            name: v['name']!,
            category: v['category']!,
            quantity: qty,
            bringer: bringer,
          ),
        );
      } else {
        item
          ..name = v['name']!
          ..category = v['category']!
          ..quantity = qty
          ..bringer = bringer;
      }
    });
  }

  void _addEssentials() {
    const essentials = {
      'Tent': 'Shelter',
      'Sleeping bag': 'Sleep',
      'Sleeping pad': 'Sleep',
      'Stove & fuel': 'Kitchen',
      'Lighter / matches': 'Kitchen',
      'Water bottles': 'Kitchen',
      'Rain jacket': 'Clothing',
      'First aid kit': 'Safety',
      'Headlamp': 'Safety',
      'Map & compass': 'Safety',
      'Knife / multi-tool': 'Tools',
      'Sunscreen': 'Personal',
    };
    final have = trip.gear.map((g) => g.name.toLowerCase()).toSet();
    StoreScope.of(context).update(() {
      essentials.forEach((name, cat) {
        if (!have.contains(name.toLowerCase())) {
          trip.gear.add(GearItem(name: name, category: cat));
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final byCat = <String, List<GearItem>>{};
    for (final g in trip.gear) {
      if (_hidePacked && g.packed) continue;
      byCat.putIfAbsent(g.category, () => []).add(g);
    }
    final cats = gearCategories.where(byCat.containsKey).toList()
      ..addAll(byCat.keys.where((k) => !gearCategories.contains(k)));

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        heroTag: 'gear-fab',
        tooltip: 'Add item',
        onPressed: () => _edit(),
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CircularProgressIndicator(
                          value: trip.packedFraction,
                          strokeWidth: 6,
                          backgroundColor: scheme.surfaceContainerHighest,
                        ),
                        Center(
                          child: Text(
                            '${(trip.packedFraction * 100).round()}%',
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trip.gear.isNotEmpty &&
                                  trip.packedCount == trip.gear.length
                              ? 'All packed!'
                              : 'Packing checklist',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${trip.packedCount} of ${trip.gear.length} items packed',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  FilterChip(
                    label: const Text('Hide packed'),
                    selected: _hidePacked,
                    onSelected: (v) => setState(() => _hidePacked = v),
                  ),
                ],
              ),
            ),
          ),
          if (trip.gear.isEmpty) ...[
            const EmptyHint(
              icon: Icons.backpack_outlined,
              title: 'Nothing on the list',
              message: 'Add items one at a time, or start with the essentials.',
            ),
            Center(
              child: FilledButton.tonalIcon(
                onPressed: _addEssentials,
                icon: const Icon(Icons.auto_awesome_outlined),
                label: const Text('Add camping essentials'),
              ),
            ),
          ],
          for (final cat in cats) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
              child: Row(
                children: [
                  Icon(gearIcon(cat), size: 20, color: scheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    cat,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${byCat[cat]!.where((g) => g.packed).length}/${byCat[cat]!.length}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (final g in byCat[cat]!)
                    ListTile(
                      onTap: () => store.update(() => g.packed = !g.packed),
                      onLongPress: () => _edit(g),
                      leading: Checkbox(
                        value: g.packed,
                        onChanged: (v) =>
                            store.update(() => g.packed = v ?? false),
                      ),
                      title: Text(
                        g.quantity > 1 ? '${g.name}  ×${g.quantity}' : g.name,
                        style: g.packed
                            ? TextStyle(
                                decoration: TextDecoration.lineThrough,
                                color: scheme.outline,
                              )
                            : null,
                      ),
                      subtitle: g.bringer.isEmpty
                          ? null
                          : Text('Bringing: ${g.bringer}'),
                      trailing: IconButton(
                        tooltip: 'Edit',
                        icon: const Icon(Icons.more_horiz),
                        onPressed: () => _edit(g),
                      ),
                    ),
                ],
              ),
            ),
          ],
          if (trip.gear.isNotEmpty && trip.packedCount > 0) ...[
            const SizedBox(height: 16),
            Center(
              child: TextButton.icon(
                onPressed: () => store.update(() {
                  for (final g in trip.gear) {
                    g.packed = false;
                  }
                }),
                icon: const Icon(Icons.restart_alt),
                label: const Text('Unpack everything'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
