import 'package:flutter/material.dart';

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.onEdit,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final VoidCallback? onEdit;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                ?trailing,
                if (onEdit != null)
                  IconButton(
                    tooltip: 'Edit $title',
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    onPressed: onEdit,
                  )
                else
                  const SizedBox(height: 48),
              ],
            ),
            const SizedBox(height: 4),
            Padding(padding: const EdgeInsets.only(right: 8), child: child),
          ],
        ),
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.actions = const [],
    this.placeholder = 'Not set',
  });

  final String label;
  final String value;
  final List<Widget> actions;
  final String placeholder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final empty = value.trim().isEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  empty ? placeholder : value,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: empty ? theme.colorScheme.outline : null,
                    fontStyle: empty ? FontStyle.italic : null,
                  ),
                ),
              ],
            ),
          ),
          if (!empty) ...actions,
        ],
      ),
    );
  }
}

class EmptyHint extends StatelessWidget {
  const EmptyHint({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 64, 32, 32),
      child: Column(
        children: [
          Icon(icon, size: 56, color: theme.colorScheme.primary),
          const SizedBox(height: 12),
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class DayHeader extends StatelessWidget {
  const DayHeader({super.key, required this.day, required this.label});

  final int day;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Day ${day + 1}',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Names that can be offered in "who" dropdowns.
List<String> whoOptions(Iterable<String> names) => [
  'Anyone',
  ...names.where((n) => n.isNotEmpty),
];

String firstName(String full) => full.trim().split(RegExp(r'\s+')).first;
