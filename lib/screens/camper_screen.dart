import 'package:flutter/material.dart';

import '../models.dart';
import '../util.dart';
import '../widgets/common.dart';
import 'crew_tab.dart';
import 'gear_tab.dart';
import 'meals_tab.dart';
import 'overview_tab.dart';

/// Everything one camper is doing on the trip: meals they cook, gear they
/// bring or that's for them, what they paid for and who they owe.
class CamperScreen extends StatelessWidget {
  const CamperScreen({super.key, required this.tripId, required this.camperId});

  final String tripId;
  final String camperId;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final trip = store.byId(tripId);
    final c = trip?.camper(camperId);
    if (trip == null || c == null) return const Scaffold();

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final debts = trip.debts();
    final owes = debts.where((d) => d.from == c.id).toList();
    final owedBy = debts.where((d) => d.to == c.id).toList();
    final paid = trip.costs.where((x) => x.payerIds.contains(c.id)).toList();
    final meals = trip.meals.where((m) => m.cookIds.contains(c.id)).toList()
      ..sort(
        (a, b) => a.day != b.day
            ? a.day.compareTo(b.day)
            : mealTypes.indexOf(a.type).compareTo(mealTypes.indexOf(b.type)),
      );
    final bringing = trip.gear
        .where((g) => !g.personal && g.bringerId == c.id)
        .toList();
    final forThem = trip.gear
        .where((g) => !g.personal && g.forIds.contains(c.id))
        .toList();
    final ownList = trip.gear
        .where((g) => g.personal && g.bringerId == c.id)
        .toList();
    final ownPacked = ownList.where((g) => g.packed).length;
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );

    Widget row(
      String title,
      String? subtitle,
      String? trailing,
      VoidCallback onTap, {
      IconData? icon,
    }) => InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: scheme.primary),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.bodyLarge),
                  if (subtitle != null && subtitle.isNotEmpty)
                    Text(subtitle, style: muted),
                ],
              ),
            ),
            if (trailing != null)
              Text(
                trailing,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
    );

    Widget none(String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: scheme.outline,
          fontStyle: FontStyle.italic,
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(c.isMe ? 'My trip' : '${c.firstName}\'s trip'),
        actions: [
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              final deleted = await editCamper(context, trip, c);
              if (deleted && context.mounted) Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: avatarColor(trip, c),
                        foregroundColor: Colors.white,
                        child: Text(
                          c.initials,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c.name,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (c.role.isNotEmpty) Text(c.role, style: muted),
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
                            onPressed: () => callNumber(context, c.phone),
                          ),
                          ActionChip(
                            avatar: const Icon(Icons.sms_outlined, size: 16),
                            label: const Text('Text'),
                            onPressed: () => textNumber(context, c.phone),
                          ),
                        ],
                        if (c.email.isNotEmpty)
                          ActionChip(
                            avatar: const Icon(Icons.email_outlined, size: 16),
                            label: Text(c.email),
                            onPressed: () => sendEmail(context, c.email),
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
                          child: Text('Emergency: ${c.emergencyContact}'),
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
                        Expanded(child: Text(c.notes)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: 'Money',
            icon: Icons.account_balance_wallet_outlined,
            collapsible: true,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: InfoRow(
                        label: 'Trip cost',
                        value: fmtMoney(trip.costFor(c.id)),
                      ),
                    ),
                    Expanded(
                      child: InfoRow(
                        label: 'Paid so far',
                        value: fmtMoney(trip.paidBy(c.id)),
                      ),
                    ),
                  ],
                ),
                if (owes.isEmpty && owedBy.isEmpty) none('All square'),
                for (final d in owes)
                  _Balance(
                    text: c.isMe
                        ? 'You owe ${who(trip, d.to)}'
                        : 'Owes ${who(trip, d.to)}',
                    amount: d.amount,
                    negative: true,
                  ),
                for (final d in owedBy)
                  _Balance(
                    text:
                        '${who(trip, d.from, capitalize: true)} owes ${who(trip, c.id)}',
                    amount: d.amount,
                    negative: false,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: 'Paid for',
            icon: Icons.receipt_long_outlined,
            collapsible: true,
            badge: '${paid.length}',
            child: Column(
              children: [
                if (paid.isEmpty) none('Hasn\'t paid for anything yet'),
                for (final x in paid)
                  row(
                    x.label,
                    [
                      if (x.payerIds.length > 1)
                        'Paid with ${namesOr(trip, x.payerIds.where((id) => id != c.id).toList(), '')}',
                      x.isPersonal ? 'Personal' : null,
                    ].whereType<String>().join(' · '),
                    fmtMoney(x.amount / x.payerIds.length),
                    () => editCost(context, trip, x),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: 'Cooking',
            icon: Icons.outdoor_grill_outlined,
            collapsible: true,
            badge: '${meals.length}',
            child: Column(
              children: [
                if (meals.isEmpty) none('Not cooking any meals'),
                for (final m in meals)
                  row(
                    m.displayTitle,
                    'Day ${m.day + 1} ${m.type.toLowerCase()}'
                    '${m.cookIds.length > 1 ? ' · with ${namesOr(trip, m.cookIds.where((id) => id != c.id).toList(), '')}' : ''}',
                    null,
                    () => editMeal(context, trip, meal: m),
                    icon: mealIcon(m.type),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: 'Bringing for the group',
            icon: Icons.local_shipping_outlined,
            collapsible: true,
            badge: '${bringing.length}',
            child: Column(
              children: [
                if (bringing.isEmpty) none('Not bringing any group gear'),
                for (final g in bringing)
                  row(
                    g.quantity > 1 ? '${g.name} ×${g.quantity}' : g.name,
                    [
                      g.category,
                      if (g.forIds.isNotEmpty)
                        'for ${namesOr(trip, g.forIds, '')}',
                      if (g.packed) 'packed',
                    ].join(' · '),
                    null,
                    () => editGear(context, trip, g),
                    icon: g.packed ? Icons.check_circle : gearIcon(g.category),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: c.isMe ? 'My packing list' : 'Personal packing list',
            icon: Icons.backpack_outlined,
            collapsible: true,
            badge: '$ownPacked/${ownList.length}',
            child: Column(
              children: [
                if (ownList.isEmpty) none('No personal items yet'),
                for (final g in ownList)
                  row(
                    g.quantity > 1 ? '${g.name} ×${g.quantity}' : g.name,
                    [g.category, if (g.packed) 'packed'].join(' · '),
                    null,
                    () => editGear(context, trip, g),
                    icon: g.packed ? Icons.check_circle : gearIcon(g.category),
                  ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => editGear(context, trip, null, true, c.id),
                    icon: const Icon(Icons.add),
                    label: const Text('Add personal item'),
                  ),
                ),
              ],
            ),
          ),
          if (forThem.isNotEmpty) ...[
            const SizedBox(height: 12),
            SectionCard(
              title: 'Group gear set aside for ${c.isMe ? 'me' : c.firstName}',
              icon: Icons.bookmark_outline,
              collapsible: true,
              badge: '${forThem.length}',
              child: Column(
                children: [
                  for (final g in forThem)
                    row(
                      g.quantity > 1 ? '${g.name} ×${g.quantity}' : g.name,
                      trip.camper(g.bringerId) == null
                          ? 'Nobody bringing it yet'
                          : 'Bringing: ${who(trip, g.bringerId, capitalize: true)}',
                      null,
                      () => editGear(context, trip, g),
                      icon: gearIcon(g.category),
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

class _Balance extends StatelessWidget {
  const _Balance({
    required this.text,
    required this.amount,
    required this.negative,
  });

  final String text;
  final double amount;
  final bool negative;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            negative ? Icons.arrow_outward : Icons.call_received,
            size: 18,
            color: negative ? scheme.error : scheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
          Text(
            fmtMoney(amount),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: negative ? scheme.error : scheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
