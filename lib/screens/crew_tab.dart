import 'package:flutter/material.dart';

import '../models.dart';
import '../util.dart';
import '../widgets/common.dart';
import '../widgets/form_sheet.dart';
import 'camper_screen.dart';

const avatarColors = [
  Color(0xFF2F5D48),
  Color(0xFFD9822B),
  Color(0xFF4A6FA5),
  Color(0xFF8C4A6B),
  Color(0xFF6B7F3A),
  Color(0xFFB5523B),
];

Color avatarColor(Trip trip, Camper c) =>
    avatarColors[trip.campers.indexOf(c).clamp(0, 999) % avatarColors.length];

/// Add or edit a camper. Returns true when the camper was deleted.
Future<bool> editCamper(BuildContext context, Trip trip, [Camper? c]) async {
  final store = StoreScope.of(context);
  var deleted = false;
  final v = await showFormSheet(
    context,
    title: c == null ? 'Add camper' : 'Edit ${c.isMe ? 'me' : c.firstName}',
    onDelete: c == null
        ? null
        : () {
            deleted = true;
            store.update(() => trip.forgetCamper(c.id));
          },
    fields: [
      FieldSpec.text(
        'name',
        'Name',
        initial: c?.name ?? '',
        required: true,
        icon: Icons.person_outline,
      ),
      FieldSpec.text(
        'role',
        'Role',
        initial: c?.role ?? '',
        hint: 'Driver, chef, navigator…',
        icon: Icons.badge_outlined,
      ),
      FieldSpec.text(
        'phone',
        'Phone',
        initial: c?.phone ?? '',
        keyboardType: TextInputType.phone,
        icon: Icons.phone_outlined,
      ),
      FieldSpec.text(
        'email',
        'Email',
        initial: c?.email ?? '',
        keyboardType: TextInputType.emailAddress,
        icon: Icons.email_outlined,
      ),
      FieldSpec.text(
        'emergency',
        'Emergency contact',
        initial: c?.emergencyContact ?? '',
        hint: 'Name and phone',
        icon: Icons.emergency_outlined,
      ),
      FieldSpec.text(
        'notes',
        'Notes',
        initial: c?.notes ?? '',
        hint: 'Allergies, dietary needs…',
        maxLines: 2,
      ),
    ],
  );
  if (deleted) return true;
  if (v == null) return false;
  store.update(() {
    final target = c ?? Camper(name: '');
    target
      ..name = v.str('name')
      ..role = v.str('role')
      ..phone = v.str('phone')
      ..email = v.str('email')
      ..emergencyContact = v.str('emergency')
      ..notes = v.str('notes');
    if (c == null) trip.campers.add(target);
  });
  return false;
}

class CrewTab extends StatelessWidget {
  const CrewTab({super.key, required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final debts = trip.debts();

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        heroTag: 'crew-fab',
        tooltip: 'Add camper',
        onPressed: () => editCamper(context, trip),
        child: const Icon(Icons.person_add_alt),
      ),
      body: trip.campers.isEmpty
          ? EmptyHint(
              icon: Icons.group_outlined,
              title: 'Who\'s coming?',
              message: 'Add campers with their contact info and roles.',
              action: OutlinedButton.icon(
                onPressed: () => store.update(
                  () => trip.campers.insert(0, Camper(name: 'Me', isMe: true)),
                ),
                icon: const Icon(Icons.person_outline),
                label: const Text('Add me'),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
              itemCount: trip.campers.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final c = trip.campers[i];
                final owes = debts.where((d) => d.from == c.id).toList();
                final owed = debts
                    .where((d) => d.to == c.id)
                    .fold(0.0, (s, d) => s + d.amount);
                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            CamperScreen(tripId: trip.id, camperId: c.id),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 12, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: avatarColor(trip, c),
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
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            c.name,
                                            overflow: TextOverflow.ellipsis,
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                        ),
                                        if (c.isMe) ...[
                                          const SizedBox(width: 8),
                                          const _YouBadge(),
                                        ],
                                      ],
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
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    fmtMoney(trip.costFor(c.id)),
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    'trip cost',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: scheme.onSurfaceVariant,
                              ),
                            ],
                          ),
                          if (owes.isNotEmpty || owed > 0) ...[
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                for (final d in owes)
                                  _BalanceChip(
                                    text:
                                        'Owes ${who(trip, d.to)} ${fmtMoney(d.amount)}',
                                    negative: true,
                                  ),
                                if (owed > 0)
                                  _BalanceChip(
                                    text: 'Is owed ${fmtMoney(owed)}',
                                    negative: false,
                                  ),
                              ],
                            ),
                          ],
                          if (c.phone.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: [
                                ActionChip(
                                  avatar: const Icon(Icons.call, size: 16),
                                  label: Text(c.phone),
                                  onPressed: () => callNumber(context, c.phone),
                                ),
                                ActionChip(
                                  avatar: const Icon(
                                    Icons.sms_outlined,
                                    size: 16,
                                  ),
                                  label: const Text('Text'),
                                  onPressed: () => textNumber(context, c.phone),
                                ),
                              ],
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

class _YouBadge extends StatelessWidget {
  const _YouBadge();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        'YOU',
        style: TextStyle(
          fontSize: 10,
          letterSpacing: 1,
          fontWeight: FontWeight.w700,
          color: scheme.onSecondaryContainer,
        ),
      ),
    );
  }
}

class _BalanceChip extends StatelessWidget {
  const _BalanceChip({required this.text, required this.negative});

  final String text;
  final bool negative;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = negative ? scheme.errorContainer : scheme.primaryContainer;
    final fg = negative ? scheme.onErrorContainer : scheme.onPrimaryContainer;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 13, color: fg, fontWeight: FontWeight.w600),
      ),
    );
  }
}
