import 'package:flutter/material.dart';

import '../models.dart';
import '../util.dart';
import '../widgets/common.dart';
import '../widgets/form_sheet.dart';
import 'gear_lists_screen.dart';

enum GearView { group, mine, all }

/// Add or edit a gear item. Shared with the crew summary screen. When
/// adding, [personal] picks which list the new item goes on and [ownerId]
/// whose personal list it defaults to.
Future<void> editGear(
  BuildContext context,
  Trip trip, [
  GearItem? item,
  bool personal = false,
  String? ownerId,
]) async {
  final store = StoreScope.of(context);
  final isPersonal = item?.personal ?? personal;
  final defaultOwner =
      ownerId ?? trip.me?.id ?? trip.campers.firstOrNull?.id ?? '';
  final v = await showFormSheet(
    context,
    title: item == null
        ? (isPersonal ? 'Add to personal list' : 'Add group gear')
        : 'Edit item',
    onDelete: item == null
        ? null
        : () => store.update(() => trip.gear.remove(item)),
    fields: [
      FieldSpec.text(
        'name',
        'Item',
        initial: item?.name ?? '',
        hint: isPersonal ? 'Hiking boots' : 'Camp stove',
        required: true,
        icon: Icons.backpack_outlined,
      ),
      FieldSpec.choice(
        'category',
        'Category',
        options: plainOptions(gearCategories),
        initial: item?.category ?? (isPersonal ? 'Personal' : 'Other'),
      ),
      FieldSpec.text(
        'qty',
        'Quantity',
        initial: '${item?.quantity ?? 1}',
        keyboardType: TextInputType.number,
        validator: (s) => (int.tryParse(s) ?? 0) < 1 ? 'At least 1' : null,
      ),
      if (isPersonal)
        FieldSpec.choice(
          'owner',
          'Whose list',
          options: camperOptions(trip),
          initial: item?.bringerId ?? defaultOwner,
          icon: Icons.person_outline,
        )
      else ...[
        FieldSpec.choice(
          'bringer',
          'Who\'s providing it',
          options: [(value: '', label: 'Nobody yet'), ...camperOptions(trip)],
          initial: item?.bringerId ?? '',
          icon: Icons.local_shipping_outlined,
        ),
        FieldSpec.multi(
          'for',
          'Who\'s it for',
          options: camperOptions(trip),
          allLabel: 'Everyone',
          initial: item == null || item.forIds.isEmpty
              ? const [allValue]
              : item.forIds,
          hint: 'Group gear is for everyone unless you pick people',
        ),
      ],
    ],
  );
  if (v == null) return;
  store.update(() {
    final target = item ?? GearItem(name: '', personal: isPersonal);
    target
      ..name = v.str('name')
      ..category = v.str('category')
      ..quantity = (int.tryParse(v.str('qty')) ?? 1).clamp(1, 999);
    if (isPersonal) {
      target
        ..bringerId = v.str('owner')
        ..forIds = [v.str('owner')];
    } else {
      target
        ..bringerId = v.str('bringer')
        ..forIds = v.list('for').where((id) => id != allValue).toList();
    }
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
  GearView _view = GearView.group;
  bool _hidePacked = false;
  bool _unclaimedOnly = false;

  Trip get trip => widget.trip;

  bool _inView(GearItem g) => switch (_view) {
    GearView.group => !g.personal,
    GearView.mine => g.personal && g.bringerId == trip.me?.id,
    GearView.all => true,
  };

  Future<void> _add() async {
    if (_view != GearView.all) {
      return editGear(context, trip, null, _view == GearView.mine);
    }
    final personal = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.groups_outlined),
              title: const Text('Group gear'),
              subtitle: const Text('Shared stuff: stove, firewood, chairs'),
              onTap: () => Navigator.pop(ctx, false),
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('My gear'),
              subtitle: const Text('Just for me: boots, underwear, toothbrush'),
              onTap: () => Navigator.pop(ctx, true),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
    if (personal != null && mounted) {
      await editGear(context, trip, null, personal);
    }
  }

  Future<void> _addFromList() async {
    final store = StoreScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final template = await showModalBottomSheet<Object>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                'Add from a gear list',
                style: Theme.of(ctx).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            for (final t in store.templates)
              ListTile(
                leading: const Icon(Icons.checklist_outlined),
                title: Text(t.name),
                subtitle: Text(
                  '${t.items.length} items'
                  '${t.items.any((i) => i.personal) ? ' · personal items go on your list' : ''}',
                ),
                onTap: () => Navigator.pop(ctx, t),
              ),
            if (store.templates.isEmpty)
              const ListTile(title: Text('You have no gear lists yet.')),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.edit_note),
              title: const Text('Manage gear lists'),
              onTap: () => Navigator.pop(ctx, 'manage'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (template == 'manage') {
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const GearListsScreen()));
    } else if (template is GearTemplate) {
      var added = 0;
      store.update(
        () => added = trip.applyTemplate(template, ownerId: trip.me?.id),
      );
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              added == 0
                  ? 'Everything from ${template.name} is already here'
                  : 'Added $added item${added == 1 ? '' : 's'} from ${template.name}',
            ),
          ),
        );
    }
  }

  Future<void> _saveAsList() async {
    final items = [
      for (final g in trip.gear.where(_inView))
        TemplateItem(
          name: g.name,
          category: g.category,
          quantity: g.quantity,
          personal: g.personal,
        ),
    ];
    final t = await GearListsScreen.createList(
      context,
      items: items,
      initialName: '${trip.name} gear',
    );
    if (t != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved ${items.length} items to ${t.name}')),
      );
    }
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
    final me = trip.me;

    final inView = trip.gear.where(_inView).toList();
    final packed = inView.where((g) => g.packed).length;
    final unclaimed = inView
        .where((g) => !g.personal && g.bringerId.isEmpty)
        .length;
    final showUnclaimedFilter = _view != GearView.mine && unclaimed > 0;
    final visible = inView.where((g) {
      if (_hidePacked && g.packed) return false;
      if (_unclaimedOnly && showUnclaimedFilter) {
        return !g.personal && g.bringerId.isEmpty;
      }
      return true;
    }).toList();

    final byCat = <String, List<GearItem>>{};
    for (final g in visible) {
      byCat.putIfAbsent(g.category, () => []).add(g);
    }
    final cats = [
      ...gearCategories.where(byCat.containsKey),
      ...byCat.keys.where((k) => !gearCategories.contains(k)),
    ];

    final (title, subtitle) = switch (_view) {
      GearView.group => (
        'Group gear',
        unclaimed == 0
            ? 'Everything has someone providing it'
            : '$unclaimed need${unclaimed == 1 ? 's' : ''} someone to bring ${unclaimed == 1 ? 'it' : 'them'}',
      ),
      GearView.mine => ('My packing list', 'Personal stuff only you need'),
      GearView.all => ('Everything', 'Group and personal gear together'),
    };
    final fraction = inView.isEmpty ? 0.0 : packed / inView.length;

    final header = Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 52,
                  height: 52,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: fraction,
                        strokeWidth: 6,
                        backgroundColor: scheme.surfaceContainerHighest,
                      ),
                      Center(
                        child: Text(
                          '${(fraction * 100).round()}%',
                          style: theme.textTheme.labelMedium?.copyWith(
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
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '$packed of ${inView.length} packed',
                        style: theme.textTheme.bodySmall,
                      ),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: _view == GearView.group && unclaimed > 0
                              ? scheme.tertiary
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Gear list options',
                  onSelected: (v) {
                    if (v == 'save') _saveAsList();
                    if (v == 'manage') {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const GearListsScreen(),
                        ),
                      );
                    }
                  },
                  itemBuilder: (_) => [
                    if (inView.isNotEmpty)
                      const PopupMenuItem(
                        value: 'save',
                        child: Text('Save these as a gear list'),
                      ),
                    const PopupMenuItem(
                      value: 'manage',
                      child: Text('Manage gear lists'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FilterChip(
                  label: const Text('Hide packed'),
                  selected: _hidePacked,
                  onSelected: (v) => setState(() => _hidePacked = v),
                ),
                if (showUnclaimedFilter)
                  FilterChip(
                    label: Text('Nobody bringing ($unclaimed)'),
                    selected: _unclaimedOnly,
                    onSelected: (v) => setState(() => _unclaimedOnly = v),
                  ),
                ActionChip(
                  avatar: const Icon(Icons.playlist_add, size: 18),
                  label: const Text('Add from a list'),
                  onPressed: _addFromList,
                ),
              ],
            ),
          ],
        ),
      ),
    );

    Widget body;
    if (_view == GearView.mine && me == null) {
      body = EmptyHint(
        icon: Icons.person_off_outlined,
        title: 'Add yourself to the crew',
        message: 'Your personal packing list belongs to "Me" on the Crew tab.',
        action: FilledButton.tonal(
          onPressed: () => store.update(
            () => trip.campers.insert(0, Camper(name: 'Me', isMe: true)),
          ),
          child: const Text('Add me'),
        ),
      );
    } else if (inView.isEmpty) {
      body = Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: header,
          ),
          Expanded(
            child: EmptyHint(
              icon: _view == GearView.mine
                  ? Icons.person_outline
                  : Icons.backpack_outlined,
              title: _view == GearView.mine
                  ? 'Nothing on your list yet'
                  : 'Nothing on the list',
              message: 'Add items one at a time, or start from a gear list.',
              action: FilledButton.tonalIcon(
                onPressed: _addFromList,
                icon: const Icon(Icons.playlist_add),
                label: const Text('Add from a list'),
              ),
            ),
          ),
        ],
      );
    } else {
      body = ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
        children: [
          header,
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
            child: Text(
              'Swipe right to pack · swipe left to delete · tap ••• to edit',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          if (visible.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                _hidePacked ? 'Everything here is packed!' : 'Nothing matches',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
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
                      showScope: _view == GearView.all,
                      onToggle: () => store.update(() => g.packed = !g.packed),
                      onDelete: () => _delete(g),
                      onEdit: () => editGear(context, trip, g),
                    ),
                ],
              ),
            ),
          ],
          if (packed > 0) ...[
            const SizedBox(height: 16),
            Center(
              child: TextButton.icon(
                onPressed: () => store.update(() {
                  for (final g in inView) {
                    g.packed = false;
                  }
                }),
                icon: const Icon(Icons.restart_alt),
                label: const Text('Unpack everything here'),
              ),
            ),
          ],
        ],
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        heroTag: 'gear-fab',
        tooltip: 'Add item',
        onPressed: _add,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Center(
              child: SegmentedButton<GearView>(
                style: const ButtonStyle(
                  visualDensity: VisualDensity.comfortable,
                ),
                segments: const [
                  ButtonSegment(
                    value: GearView.group,
                    icon: Icon(Icons.groups_outlined),
                    label: Text('Group'),
                  ),
                  ButtonSegment(
                    value: GearView.mine,
                    icon: Icon(Icons.person_outline),
                    label: Text('Mine'),
                  ),
                  ButtonSegment(
                    value: GearView.all,
                    icon: Icon(Icons.list),
                    label: Text('All'),
                  ),
                ],
                selected: {_view},
                onSelectionChanged: (s) => setState(() => _view = s.first),
              ),
            ),
          ),
          Expanded(child: body),
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
    required this.showScope,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
  });

  final Trip trip;
  final GearItem item;
  final bool showScope;
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final g = item;
    final owner = trip.camper(g.bringerId);

    Widget? subtitle;
    if (!g.personal) {
      final forNames = trip.names(g.forIds);
      subtitle = Text.rich(
        TextSpan(
          children: [
            owner == null
                ? TextSpan(
                    text: 'Nobody bringing yet',
                    style: TextStyle(
                      color: scheme.tertiary,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                : TextSpan(
                    text: 'Bringing: ${who(trip, owner.id, capitalize: true)}',
                  ),
            TextSpan(
              text: forNames.isEmpty
                  ? ' · for everyone'
                  : ' · for ${forNames.join(', ')}',
            ),
          ],
        ),
      );
    } else if (showScope && owner != null && !owner.isMe) {
      subtitle = Text('${owner.firstName}\'s list');
    }

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
        title: Row(
          children: [
            Flexible(
              child: Text(
                g.quantity > 1 ? '${g.name}  ×${g.quantity}' : g.name,
                style: g.packed
                    ? TextStyle(
                        decoration: TextDecoration.lineThrough,
                        color: scheme.outline,
                      )
                    : null,
              ),
            ),
            if (showScope && g.personal) ...[
              const SizedBox(width: 8),
              ScopeTag(
                personal: g.personal,
                owner: g.personal && owner != null && !owner.isMe
                    ? owner.firstName
                    : null,
              ),
            ],
          ],
        ),
        subtitle: subtitle,
        trailing: IconButton(
          tooltip: 'Edit',
          icon: const Icon(Icons.more_horiz),
          onPressed: onEdit,
        ),
      ),
    );
  }
}
