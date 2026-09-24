import 'package:flutter/material.dart';

import '../models.dart';
import '../util.dart';
import '../widgets/common.dart';
import '../widgets/form_sheet.dart';

/// All of the user's reusable packing lists.
class GearListsScreen extends StatelessWidget {
  const GearListsScreen({super.key});

  static Future<GearTemplate?> createList(
    BuildContext context, {
    List<TemplateItem> items = const [],
    String initialName = '',
  }) async {
    final store = StoreScope.of(context);
    final v = await showFormSheet(
      context,
      title: 'New gear list',
      submitLabel: 'Create',
      fields: [
        FieldSpec.text(
          'name',
          'List name',
          initial: initialName,
          hint: 'e.g. Winter camping, Backpacking',
          required: true,
          icon: Icons.checklist_outlined,
        ),
      ],
    );
    if (v == null) return null;
    final template = GearTemplate(name: v.str('name'), items: [...items]);
    store.update(() => store.templates.add(template));
    return template;
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Gear lists')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final t = await createList(context);
          if (t != null && context.mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => GearListScreen(listId: t.id)),
            );
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('New list'),
      ),
      body: store.templates.isEmpty
          ? const EmptyHint(
              icon: Icons.checklist_outlined,
              title: 'No gear lists',
              message:
                  'Create lists you pack from often, like "Camping essentials" '
                  'or "Winter layers", and add them to any trip in one tap.',
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
                  child: Text(
                    'Reusable packing lists you can add to any trip from '
                    'the Gear tab.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      for (final t in store.templates)
                        ListTile(
                          leading: const Icon(Icons.checklist_outlined),
                          title: Text(t.name),
                          subtitle: Text(_summary(t)),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => GearListScreen(listId: t.id),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

String _summary(GearTemplate t) {
  final personal = t.items.where((i) => i.personal).length;
  final group = t.items.length - personal;
  return [
    '${t.items.length} item${t.items.length == 1 ? '' : 's'}',
    if (group > 0 && personal > 0) '$group group · $personal personal',
  ].join(' · ');
}

/// Edits one reusable list.
class GearListScreen extends StatelessWidget {
  const GearListScreen({super.key, required this.listId});

  final String listId;

  Future<void> _editItem(
    BuildContext context,
    GearTemplate t, [
    TemplateItem? item,
  ]) async {
    final store = StoreScope.of(context);
    final v = await showFormSheet(
      context,
      title: item == null ? 'Add item' : 'Edit item',
      onDelete: item == null
          ? null
          : () => store.update(() => t.items.remove(item)),
      fields: [
        FieldSpec.text(
          'name',
          'Item',
          initial: item?.name ?? '',
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
        FieldSpec.toggle(
          'personal',
          'Personal item',
          initial: item?.personal ?? false,
          hint: 'Goes on your own list instead of the group\'s',
          icon: Icons.person_outline,
        ),
      ],
    );
    if (v == null) return;
    store.update(() {
      final target = item ?? TemplateItem(name: '');
      target
        ..name = v.str('name')
        ..category = v.str('category')
        ..quantity = (int.tryParse(v.str('qty')) ?? 1).clamp(1, 999)
        ..personal = v.flag('personal');
      if (item == null) t.items.add(target);
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    GearTemplate? t;
    for (final x in store.templates) {
      if (x.id == listId) t = x;
    }
    if (t == null) return const Scaffold();
    final list = t;

    final byCat = <String, List<TemplateItem>>{};
    for (final i in list.items) {
      byCat.putIfAbsent(i.category, () => []).add(i);
    }
    final cats = [
      ...gearCategories.where(byCat.containsKey),
      ...byCat.keys.where((k) => !gearCategories.contains(k)),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(list.name),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'rename') {
                final r = await showFormSheet(
                  context,
                  title: 'Rename list',
                  fields: [
                    FieldSpec.text(
                      'name',
                      'List name',
                      initial: list.name,
                      required: true,
                    ),
                  ],
                );
                if (r != null) store.update(() => list.name = r.str('name'));
              } else if (v == 'delete') {
                final ok = await confirm(
                  context,
                  'Delete "${list.name}"?',
                  'Trips that already used this list keep their gear.',
                );
                if (ok && context.mounted) {
                  Navigator.of(context).pop();
                  store.update(() => store.templates.remove(list));
                }
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'rename', child: Text('Rename list')),
              PopupMenuItem(value: 'delete', child: Text('Delete list')),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add item',
        onPressed: () => _editItem(context, list),
        child: const Icon(Icons.add),
      ),
      body: list.items.isEmpty
          ? const EmptyHint(
              icon: Icons.backpack_outlined,
              title: 'Empty list',
              message: 'Add the things you always bring.',
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
              children: [
                for (final cat in cats) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
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
                      ],
                    ),
                  ),
                  Card(
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        for (final i in byCat[cat]!)
                          ListTile(
                            title: Text(
                              i.quantity > 1
                                  ? '${i.name}  ×${i.quantity}'
                                  : i.name,
                            ),
                            trailing: i.personal
                                ? const ScopeTag(personal: true)
                                : null,
                            onTap: () => _editItem(context, list, i),
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
