import 'package:flutter/material.dart';

import '../models.dart';
import '../util.dart';
import '../widgets/common.dart';
import '../widgets/form_sheet.dart';

class CrewTab extends StatelessWidget {
  const CrewTab({super.key, required this.trip});

  final Trip trip;

  static const _avatarColors = [
    Color(0xFF2F5D48),
    Color(0xFFD9822B),
    Color(0xFF4A6FA5),
    Color(0xFF8C4A6B),
    Color(0xFF6B7F3A),
    Color(0xFFB5523B),
  ];

  Future<void> _edit(BuildContext context, [Camper? c]) async {
    final store = StoreScope.of(context);
    final v = await showFormSheet(
      context,
      title: c == null ? 'Add camper' : 'Edit camper',
      onDelete: c == null
          ? null
          : () => store.update(() => trip.campers.remove(c)),
      fields: [
        FieldSpec(
          'name',
          'Name',
          initial: c?.name ?? '',
          required: true,
          icon: Icons.person_outline,
        ),
        FieldSpec(
          'role',
          'Role',
          initial: c?.role ?? '',
          hint: 'Driver, chef, navigator…',
          icon: Icons.badge_outlined,
        ),
        FieldSpec(
          'phone',
          'Phone',
          initial: c?.phone ?? '',
          keyboardType: TextInputType.phone,
          icon: Icons.phone_outlined,
        ),
        FieldSpec(
          'email',
          'Email',
          initial: c?.email ?? '',
          keyboardType: TextInputType.emailAddress,
          icon: Icons.email_outlined,
        ),
        FieldSpec(
          'emergency',
          'Emergency contact',
          initial: c?.emergencyContact ?? '',
          hint: 'Name and phone',
          icon: Icons.emergency_outlined,
        ),
        FieldSpec(
          'notes',
          'Notes',
          initial: c?.notes ?? '',
          hint: 'Allergies, dietary needs…',
          maxLines: 2,
        ),
      ],
    );
    if (v == null) return;
    store.update(() {
      if (c == null) {
        trip.campers.add(
          Camper(
            name: v['name']!,
            role: v['role']!,
            phone: v['phone']!,
            email: v['email']!,
            emergencyContact: v['emergency']!,
            notes: v['notes']!,
          ),
        );
      } else {
        c
          ..name = v['name']!
          ..role = v['role']!
          ..phone = v['phone']!
          ..email = v['email']!
          ..emergencyContact = v['emergency']!
          ..notes = v['notes']!;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    StoreScope.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        heroTag: 'crew-fab',
        tooltip: 'Add camper',
        onPressed: () => _edit(context),
        child: const Icon(Icons.person_add_alt),
      ),
      body: trip.campers.isEmpty
          ? const EmptyHint(
              icon: Icons.group_outlined,
              title: 'Who\'s coming?',
              message: 'Add campers with their contact info and roles.',
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
              itemCount: trip.campers.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final c = trip.campers[i];
                final color = _avatarColors[i % _avatarColors.length];
                final bringing = trip.gear
                    .where((g) => g.bringer == firstName(c.name))
                    .length;
                final cooking = trip.meals
                    .where((m) => m.cook == firstName(c.name))
                    .length;
                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => _edit(context, c),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 12, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: color,
                                foregroundColor: Colors.white,
                                child: Text(
                                  c.initials,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      c.name,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    if (c.role.isNotEmpty)
                                      Text(
                                        c.role,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: scheme.onSurfaceVariant,
                                            ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (c.phone.isNotEmpty || c.email.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                if (c.phone.isNotEmpty) ...[
                                  ActionChip(
                                    avatar: const Icon(Icons.call, size: 16),
                                    label: Text(c.phone),
                                    onPressed: () =>
                                        callNumber(context, c.phone),
                                  ),
                                  ActionChip(
                                    avatar: const Icon(
                                      Icons.sms_outlined,
                                      size: 16,
                                    ),
                                    label: const Text('Text'),
                                    onPressed: () =>
                                        textNumber(context, c.phone),
                                  ),
                                ],
                                if (c.email.isNotEmpty)
                                  ActionChip(
                                    avatar: const Icon(
                                      Icons.email_outlined,
                                      size: 16,
                                    ),
                                    label: Text(c.email),
                                    onPressed: () =>
                                        sendEmail(context, c.email),
                                  ),
                              ],
                            ),
                          ],
                          if (c.emergencyContact.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Icon(
                                  Icons.emergency_outlined,
                                  size: 16,
                                  color: scheme.error,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Emergency: ${c.emergencyContact}',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (c.notes.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 16,
                                  color: scheme.tertiary,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    c.notes,
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (bringing > 0 || cooking > 0) ...[
                            const Divider(height: 24),
                            Text(
                              [
                                if (bringing > 0)
                                  'Bringing $bringing item${bringing == 1 ? '' : 's'}',
                                if (cooking > 0)
                                  'Cooking $cooking meal${cooking == 1 ? '' : 's'}',
                              ].join(' · '),
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: scheme.primary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
