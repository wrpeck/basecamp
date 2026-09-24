import 'package:flutter/material.dart';

import '../models.dart';
import '../util.dart';
import '../widgets/common.dart';
import '../widgets/form_sheet.dart';

/// Add or edit a gear item. Shared with the crew summary screen.
Future<void> editGear(BuildContext context, Trip trip, [GearItem? item]) async {
  final store = StoreScope.of(context);
  final v = await showFormSheet(
    context,
    title: item == null ? 'Add item' : 'Edit item',
    onDelete: item == null
        ? null
        : () => store.update(() => trip.gear.remove(item)),
    fields: [
      FieldSpec.text(
        'name',
        'Item',
        initial: item?.name ?? '',
        hint: 'Camp chairs',
        required: true,
        icon: Icons.backpack_outlined,
      ),
      FieldSpec.choice(
        'category',
        'Category',
        options: plainOptions(gearCategories),
        initial: item?.category ?? 'Other',
      ),
      FieldSpec.text(
        'qty',
        'Quantity',
        initial: '${item?.quantity ?? 1}',
        keyboardType: TextInputType.number,
        validator: (s) => (int.tryParse(s) ?? 0) < 1 ? 'At least 1' : null,
      ),
      FieldSpec.choice(
        'bringer',
        'Who\'s bringing it',
        options: [(value: '', label: 'Not assigned'), ...camperOptions(trip)],
        initial: item?.bringerId ?? '',
        icon: Icons.local_shipping_outlined,
      ),
      FieldSpec.multi(
        'for',
        'Who\'s it for',
        options: camperOptions(trip),
        allLabel: 'Anyone',
        initial: item == null || item.forIds.isEmpty
            ? const [allValue]
            : item.forIds,
        hint: 'e.g. 3 chairs for anyone, plus 1 just for you',
      ),
    ],
  );
  if (v == null) return;
  final forIds = v.list('for').where((id) => id != allValue).toList();
  store.update(() {
    final target = item ?? GearItem(name: '');
    target
      ..name = v.str('name')
      ..category = v.str('category')
      ..quantity = (int.tryParse(v.str('qty')) ?? 1).clamp(1, 999)
      ..bringerId = v.str('bringer')
      ..forIds = forIds;
    if (item == null) trip.gear.add(target);
  });
}

class GearTab extends StatefulWidget {
  const GearTab({super.key, required this.trip});

  final Trip trip;

  @override
  State<GearTab> createState() => _GearTabState();
}

class _GearTabState extends State<GearTab> {
  bool _hidePacked = false;

  Trip get trip => widget.trip;

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

  void _delete(GearItem g) {
    final store = StoreScope.of(context);
    final index = trip.gear.indexOf(g);
    store.update(() => trip.gear.remove(g));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Removed ${g.name}'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => store.update(
              () => trip.gear.insert(index.clamp(0, trip.gear.length), g),
            ),
          ),
        ),
      );
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

    final header = Card(
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
                    trip.gear.isNotEmpty && trip.packedCount == trip.gear.length
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
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        heroTag: 'gear-fab',
        tooltip: 'Add item',
        onPressed: () => editGear(context, trip),
        child: const Icon(Icons.add),
      ),
      body: trip.gear.isEmpty
          ? Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  child: header,
                ),
                Expanded(
                  child: EmptyHint(
                    icon: Icons.backpack_outlined,
                    title: 'Nothing on the list',
                    message: 'Add items one at a time, or start with the essentials.',
                    action: FilledButton.tonalIcon(
                      onPressed: _addEssentials,
                      icon: const Icon(Icons.auto_awesome_outlined),
                      label: const Text('Add camping essentials'),
                    ),
                  ),
                ),
              ],
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
              children: [
                header,
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
                  child: Text(
                    'Swipe right to pack · swipe left to delete · long-press to edit',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
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
                          _SwipeableGear(
                            key: ValueKey(g.id),
                            trip: trip,
                            item: g,
                            onToggle: () =>
                                store.update(() => g.packed = !g.packed),
                            onDelete: () => _delete(g),
                            onEdit: () => editGear(context, trip, g),
                          ),
                      ],
                    ),
                  ),
                ],
                if (trip.packedCount > 0) ...[
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

class _SwipeableGear extends StatelessWidget {
  const _SwipeableGear({
    super.key,
    required this.trip,
    required this.item,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
  });

  final Trip trip;
  final GearItem item;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  Widget _background(Color color, IconData icon, String label, bool left) {
    return Container(
      color: color,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      alignment: left ? Alignment.centerLeft : Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final g = item;
    final bringer = trip.camper(g.bringerId);
    final forNames = trip.names(g.forIds);
    final subtitle = [
      if (bringer != null) 'Bringing: ${bringer.firstName}',
      if (forNames.isNotEmpty) 'For: ${forNames.join(', ')}',
    ].join(' · ');

    return Dismissible(
      key: ValueKey('dismiss-${g.id}'),
      background: _background(
        scheme.primary,
        g.packed ? Icons.undo : Icons.check,
        g.packed ? 'Unpack' : 'Packed',
        true,
      ),
      secondaryBackground: _background(
        scheme.error,
        Icons.delete_outline,
        'Delete',
        false,
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onToggle();
          return false;
        }
        return true;
      },
      onDismissed: (_) => onDelete(),
      child: ListTile(
        onTap: onToggle,
        onLongPress: onEdit,
        leading: Checkbox(value: g.packed, onChanged: (_) => onToggle()),
        title: Text(
          g.quantity > 1 ? '${g.name}  ×${g.quantity}' : g.name,
          style: g.packed
              ? TextStyle(
                  decoration: TextDecoration.lineThrough,
                  color: scheme.outline,
                )
              : null,
        ),
        subtitle: subtitle.isEmpty ? null : Text(subtitle),
        trailing: IconButton(
          tooltip: 'Edit',
          icon: const Icon(Icons.more_horiz),
          onPressed: onEdit,
        ),
      ),
    );
  }
}
